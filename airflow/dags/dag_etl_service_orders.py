# ============================================
# DAG: dag_etl_service_orders.py
# Description: Modern ETL pipeline for Service
#              Orders using Apache Airflow
# Author: Iago Seara Vicente
# ============================================

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from datetime import datetime, timedelta
import oracledb
import logging

# Default arguments
default_args = {
    'owner': 'svc_orders',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Oracle connection
DB_CONNECTION = "svc_orders/poc123@172.24.32.1:1521/xepdb1"

def get_connection():
    return oracledb.connect(DB_CONNECTION)

# Task 1: Extract and validate source data
def extract_and_validate():
    conn = get_connection()
    cursor = conn.cursor()
    
    logging.info("Starting extraction and validation...")
    
    # Validate orders without employee
    cursor.execute("""
        SELECT COUNT(*) FROM SERVICE_ORDERS 
        WHERE EMPLOYEE_ID IS NULL
    """)
    null_employees = cursor.fetchone()[0]
    if null_employees > 0:
        logging.warning(f"Found {null_employees} orders without employee assigned")
    
    # Validate satisfaction score range
    cursor.execute("""
        SELECT COUNT(*) FROM SERVICE_ORDERS 
        WHERE SATISFACTION_SCORE NOT BETWEEN 1 AND 5
        AND SATISFACTION_SCORE IS NOT NULL
    """)
    invalid_scores = cursor.fetchone()[0]
    if invalid_scores > 0:
        logging.warning(f"Found {invalid_scores} orders with invalid satisfaction score")
    
    cursor.execute("SELECT COUNT(*) FROM SERVICE_ORDERS")
    total = cursor.fetchone()[0]
    logging.info(f"Total orders to process: {total}")
    
    cursor.close()
    conn.close()

# Task 2: Load DWH_ORDERS_SUMMARY
def load_orders_summary():
    conn = get_connection()
    cursor = conn.cursor()
    
    logging.info("Loading DWH_ORDERS_SUMMARY...")
    
    cursor.execute("TRUNCATE TABLE DWH_ORDERS_SUMMARY")
    
    cursor.execute("""
        INSERT INTO DWH_ORDERS_SUMMARY (
            ORDER_ID, CUSTOMER_NAME, EMPLOYEE_NAME, CATEGORY_NAME,
            ORDER_DATE, RESOLUTION_DATE, STATUS, PRIORITY, AMOUNT,
            ESTIMATED_HOURS, ACTUAL_HOURS, RESOLUTION_DAYS, SLA_DAYS,
            SLA_MET, EFFICIENCY_RATIO, SATISFACTION_SCORE, LOAD_DATE
        )
        SELECT
            SO.ORDER_ID,
            C.NAME, E.NAME, CAT.NAME,
            SO.ORDER_DATE, SO.RESOLUTION_DATE, SO.STATUS, SO.PRIORITY,
            SO.AMOUNT, SO.ESTIMATED_HOURS, SO.ACTUAL_HOURS,
            CASE WHEN SO.RESOLUTION_DATE IS NOT NULL 
                 THEN SO.RESOLUTION_DATE - SO.ORDER_DATE ELSE NULL END,
            CAT.SLA_DAYS,
            CASE WHEN SO.RESOLUTION_DATE IS NULL THEN 'N/A'
                 WHEN (SO.RESOLUTION_DATE - SO.ORDER_DATE) <= CAT.SLA_DAYS THEN 'YES'
                 ELSE 'NO' END,
            CASE WHEN SO.ACTUAL_HOURS IS NULL OR SO.ESTIMATED_HOURS = 0 THEN NULL
                 ELSE ROUND(SO.ACTUAL_HOURS / SO.ESTIMATED_HOURS, 2) END,
            SO.SATISFACTION_SCORE,
            SYSDATE
        FROM SERVICE_ORDERS SO
        JOIN CUSTOMERS C    ON SO.CUSTOMER_ID  = C.CUSTOMER_ID
        JOIN EMPLOYEES E    ON SO.EMPLOYEE_ID  = E.EMPLOYEE_ID
        JOIN CATEGORIES CAT ON SO.CATEGORY_ID  = CAT.CATEGORY_ID
    """)
    
    rows = cursor.rowcount
    conn.commit()
    logging.info(f"DWH_ORDERS_SUMMARY loaded: {rows} rows")
    
    cursor.close()
    conn.close()

# Task 3: Load DWH_EMPLOYEE_PERFORMANCE
def load_employee_performance():
    conn = get_connection()
    cursor = conn.cursor()
    
    logging.info("Loading DWH_EMPLOYEE_PERFORMANCE...")
    
    cursor.execute("TRUNCATE TABLE DWH_EMPLOYEE_PERFORMANCE")
    
    cursor.execute("""
        INSERT INTO DWH_EMPLOYEE_PERFORMANCE (
            EMPLOYEE_ID, EMPLOYEE_NAME, DEPARTMENT, ROLE,
            TOTAL_ORDERS, CLOSED_ORDERS, AVG_SATISFACTION,
            AVG_EFFICIENCY_RATIO, SLA_MET_COUNT, SLA_BREACH_COUNT,
            TOTAL_AMOUNT, LOAD_DATE
        )
        SELECT
            E.EMPLOYEE_ID, E.NAME, E.DEPARTMENT, E.ROLE,
            COUNT(SO.ORDER_ID),
            COUNT(CASE WHEN SO.STATUS = 'closed' THEN 1 END),
            ROUND(AVG(SO.SATISFACTION_SCORE), 2),
            ROUND(AVG(CASE WHEN SO.ACTUAL_HOURS IS NULL OR SO.ESTIMATED_HOURS = 0 
                          THEN NULL ELSE SO.ACTUAL_HOURS / SO.ESTIMATED_HOURS END), 2),
            COUNT(CASE WHEN SO.RESOLUTION_DATE IS NOT NULL 
                       AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) <= CAT.SLA_DAYS THEN 1 END),
            COUNT(CASE WHEN SO.RESOLUTION_DATE IS NOT NULL 
                       AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) > CAT.SLA_DAYS THEN 1 END),
            SUM(SO.AMOUNT),
            SYSDATE
        FROM EMPLOYEES E
        JOIN SERVICE_ORDERS SO  ON E.EMPLOYEE_ID  = SO.EMPLOYEE_ID
        JOIN CATEGORIES CAT     ON SO.CATEGORY_ID = CAT.CATEGORY_ID
        GROUP BY E.EMPLOYEE_ID, E.NAME, E.DEPARTMENT, E.ROLE
    """)
    
    rows = cursor.rowcount
    conn.commit()
    logging.info(f"DWH_EMPLOYEE_PERFORMANCE loaded: {rows} rows")
    
    cursor.close()
    conn.close()

# Task 4: Load DWH_CUSTOMER_ANALYSIS
def load_customer_analysis():
    conn = get_connection()
    cursor = conn.cursor()
    
    logging.info("Loading DWH_CUSTOMER_ANALYSIS...")
    
    cursor.execute("TRUNCATE TABLE DWH_CUSTOMER_ANALYSIS")
    
    cursor.execute("""
        INSERT INTO DWH_CUSTOMER_ANALYSIS (
            CUSTOMER_ID, CUSTOMER_NAME, COUNTRY, SEGMENT, CONTRACT_TYPE,
            TOTAL_ORDERS, CLOSED_ORDERS, TOTAL_AMOUNT, AVG_SATISFACTION,
            SLA_MET_COUNT, SLA_BREACH_COUNT, LOAD_DATE
        )
        SELECT
            C.CUSTOMER_ID, C.NAME, C.COUNTRY, C.SEGMENT, C.CONTRACT_TYPE,
            COUNT(SO.ORDER_ID),
            COUNT(CASE WHEN SO.STATUS = 'closed' THEN 1 END),
            SUM(SO.AMOUNT),
            ROUND(AVG(SO.SATISFACTION_SCORE), 2),
            COUNT(CASE WHEN SO.RESOLUTION_DATE IS NOT NULL 
                       AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) <= CAT.SLA_DAYS THEN 1 END),
            COUNT(CASE WHEN SO.RESOLUTION_DATE IS NOT NULL 
                       AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) > CAT.SLA_DAYS THEN 1 END),
            SYSDATE
        FROM CUSTOMERS C
        JOIN SERVICE_ORDERS SO  ON C.CUSTOMER_ID  = SO.CUSTOMER_ID
        JOIN CATEGORIES CAT     ON SO.CATEGORY_ID = CAT.CATEGORY_ID
        GROUP BY C.CUSTOMER_ID, C.NAME, C.COUNTRY, C.SEGMENT, C.CONTRACT_TYPE
    """)
    
    rows = cursor.rowcount
    conn.commit()
    logging.info(f"DWH_CUSTOMER_ANALYSIS loaded: {rows} rows")
    
    cursor.close()
    conn.close()

# DAG definition
with DAG(
    'etl_service_orders',
    default_args=default_args,
    description='ETL pipeline for Service Orders DWH',
    schedule_interval='0 6 * * *',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'service_orders', 'dwh'],
) as dag:

    start = EmptyOperator(task_id='start')
    
    validate = PythonOperator(
        task_id='extract_and_validate',
        python_callable=extract_and_validate,
    )
    
    orders = PythonOperator(
        task_id='load_orders_summary',
        python_callable=load_orders_summary,
    )
    
    employees = PythonOperator(
        task_id='load_employee_performance',
        python_callable=load_employee_performance,
    )
    
    customers = PythonOperator(
        task_id='load_customer_analysis',
        python_callable=load_customer_analysis,
    )
    
    end = EmptyOperator(task_id='end')
    
    start >> validate >> [orders, employees, customers] >> end