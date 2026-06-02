# ============================================
# DAG: dag_etl_dbt_service_orders.py
# Description: Modern ETL pipeline integrating
#              Apache Airflow and DBT Core
# Author: Iago Seara Vicente
# ============================================

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from datetime import datetime, timedelta
import oracledb
import logging

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

def extract_and_validate():
    conn = get_connection()
    cursor = conn.cursor()
    
    logging.info("Starting extraction and validation...")
    
    cursor.execute("""
        SELECT COUNT(*) FROM SERVICE_ORDERS 
        WHERE EMPLOYEE_ID IS NULL
    """)
    null_employees = cursor.fetchone()[0]
    if null_employees > 0:
        logging.warning(f"Found {null_employees} orders without employee assigned")
    
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

with DAG(
    'etl_dbt_service_orders',
    default_args=default_args,
    description='Modern ETL pipeline with Airflow + DBT',
    schedule_interval='0 6 * * *',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'dbt', 'service_orders'],
) as dag:

    start = EmptyOperator(task_id='start')

    validate = PythonOperator(
        task_id='extract_and_validate',
        python_callable=extract_and_validate,
    )

    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir /opt/airflow/dbt',
    )

    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt && dbt test --profiles-dir /opt/airflow/dbt',
    )

    end = EmptyOperator(task_id='end')

    start >> validate >> dbt_run >> dbt_test >> end