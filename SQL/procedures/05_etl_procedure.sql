-- ============================================
-- Script: 05_etl_procedure.sql
-- Description: ETL procedure that extracts,
--              transforms and loads data into
--              the DWH destination tables
-- Author: Iago Seara Vicente
-- ============================================

CREATE OR REPLACE PROCEDURE PRC_ETL_SERVICE_ORDERS AS

BEGIN

    -- ----------------------------------------
    -- STEP 1: Truncate destination tables
    -- ----------------------------------------
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DWH_ORDERS_SUMMARY';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DWH_EMPLOYEE_PERFORMANCE';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DWH_CUSTOMER_ANALYSIS';

    -- ----------------------------------------
    -- STEP 2: Load DWH_ORDERS_SUMMARY
    -- ----------------------------------------
    INSERT INTO DWH_ORDERS_SUMMARY (
        ORDER_ID,
        CUSTOMER_NAME,
        EMPLOYEE_NAME,
        CATEGORY_NAME,
        ORDER_DATE,
        RESOLUTION_DATE,
        STATUS,
        PRIORITY,
        AMOUNT,
        ESTIMATED_HOURS,
        ACTUAL_HOURS,
        RESOLUTION_DAYS,
        SLA_DAYS,
        SLA_MET,
        EFFICIENCY_RATIO,
        SATISFACTION_SCORE,
        LOAD_DATE
    )
    SELECT
        SO.ORDER_ID,
        C.NAME                                          AS CUSTOMER_NAME,
        E.NAME                                          AS EMPLOYEE_NAME,
        CAT.NAME                                        AS CATEGORY_NAME,
        SO.ORDER_DATE,
        SO.RESOLUTION_DATE,
        SO.STATUS,
        SO.PRIORITY,
        SO.AMOUNT,
        SO.ESTIMATED_HOURS,
        SO.ACTUAL_HOURS,
        CASE
            WHEN SO.RESOLUTION_DATE IS NOT NULL
            THEN SO.RESOLUTION_DATE - SO.ORDER_DATE
            ELSE NULL
        END                                             AS RESOLUTION_DAYS,
        CAT.SLA_DAYS,
        CASE
            WHEN SO.RESOLUTION_DATE IS NULL THEN 'N/A'
            WHEN (SO.RESOLUTION_DATE - SO.ORDER_DATE) <= CAT.SLA_DAYS THEN 'YES'
            ELSE 'NO'
        END                                             AS SLA_MET,
        CASE
            WHEN SO.ACTUAL_HOURS IS NULL OR SO.ESTIMATED_HOURS = 0 THEN NULL
            ELSE ROUND(SO.ACTUAL_HOURS / SO.ESTIMATED_HOURS, 2)
        END                                             AS EFFICIENCY_RATIO,
        SO.SATISFACTION_SCORE,
        SYSDATE                                         AS LOAD_DATE
    FROM SERVICE_ORDERS SO
    JOIN CUSTOMERS C    ON SO.CUSTOMER_ID  = C.CUSTOMER_ID
    JOIN EMPLOYEES E    ON SO.EMPLOYEE_ID  = E.EMPLOYEE_ID
    JOIN CATEGORIES CAT ON SO.CATEGORY_ID = CAT.CATEGORY_ID;

    -- ----------------------------------------
    -- STEP 3: Load DWH_EMPLOYEE_PERFORMANCE
    -- ----------------------------------------
    INSERT INTO DWH_EMPLOYEE_PERFORMANCE (
        EMPLOYEE_ID,
        EMPLOYEE_NAME,
        DEPARTMENT,
        ROLE,
        TOTAL_ORDERS,
        CLOSED_ORDERS,
        AVG_SATISFACTION,
        AVG_EFFICIENCY_RATIO,
        SLA_MET_COUNT,
        SLA_BREACH_COUNT,
        TOTAL_AMOUNT,
        LOAD_DATE
    )
    SELECT
        E.EMPLOYEE_ID,
        E.NAME                                          AS EMPLOYEE_NAME,
        E.DEPARTMENT,
        E.ROLE,
        COUNT(SO.ORDER_ID)                              AS TOTAL_ORDERS,
        COUNT(CASE WHEN SO.STATUS = 'closed' THEN 1 END) AS CLOSED_ORDERS,
        ROUND(AVG(SO.SATISFACTION_SCORE), 2)            AS AVG_SATISFACTION,
        ROUND(AVG(
            CASE
                WHEN SO.ACTUAL_HOURS IS NULL OR SO.ESTIMATED_HOURS = 0 THEN NULL
                ELSE SO.ACTUAL_HOURS / SO.ESTIMATED_HOURS
            END
        ), 2)                                           AS AVG_EFFICIENCY_RATIO,
        COUNT(CASE
            WHEN SO.RESOLUTION_DATE IS NOT NULL
            AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) <= CAT.SLA_DAYS
            THEN 1
        END)                                            AS SLA_MET_COUNT,
        COUNT(CASE
            WHEN SO.RESOLUTION_DATE IS NOT NULL
            AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) > CAT.SLA_DAYS
            THEN 1
        END)                                            AS SLA_BREACH_COUNT,
        SUM(SO.AMOUNT)                                  AS TOTAL_AMOUNT,
        SYSDATE                                         AS LOAD_DATE
    FROM EMPLOYEES E
    JOIN SERVICE_ORDERS SO  ON E.EMPLOYEE_ID  = SO.EMPLOYEE_ID
    JOIN CATEGORIES CAT     ON SO.CATEGORY_ID = CAT.CATEGORY_ID
    GROUP BY E.EMPLOYEE_ID, E.NAME, E.DEPARTMENT, E.ROLE;

    -- ----------------------------------------
    -- STEP 4: Load DWH_CUSTOMER_ANALYSIS
    -- ----------------------------------------
    INSERT INTO DWH_CUSTOMER_ANALYSIS (
        CUSTOMER_ID,
        CUSTOMER_NAME,
        COUNTRY,
        SEGMENT,
        CONTRACT_TYPE,
        TOTAL_ORDERS,
        CLOSED_ORDERS,
        TOTAL_AMOUNT,
        AVG_SATISFACTION,
        SLA_MET_COUNT,
        SLA_BREACH_COUNT,
        LOAD_DATE
    )
    SELECT
        C.CUSTOMER_ID,
        C.NAME                                          AS CUSTOMER_NAME,
        C.COUNTRY,
        C.SEGMENT,
        C.CONTRACT_TYPE,
        COUNT(SO.ORDER_ID)                              AS TOTAL_ORDERS,
        COUNT(CASE WHEN SO.STATUS = 'closed' THEN 1 END) AS CLOSED_ORDERS,
        SUM(SO.AMOUNT)                                  AS TOTAL_AMOUNT,
        ROUND(AVG(SO.SATISFACTION_SCORE), 2)            AS AVG_SATISFACTION,
        COUNT(CASE
            WHEN SO.RESOLUTION_DATE IS NOT NULL
            AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) <= CAT.SLA_DAYS
            THEN 1
        END)                                            AS SLA_MET_COUNT,
        COUNT(CASE
            WHEN SO.RESOLUTION_DATE IS NOT NULL
            AND (SO.RESOLUTION_DATE - SO.ORDER_DATE) > CAT.SLA_DAYS
            THEN 1
        END)                                            AS SLA_BREACH_COUNT,
        SYSDATE                                         AS LOAD_DATE
    FROM CUSTOMERS C
    JOIN SERVICE_ORDERS SO  ON C.CUSTOMER_ID  = SO.CUSTOMER_ID
    JOIN CATEGORIES CAT     ON SO.CATEGORY_ID = CAT.CATEGORY_ID
    GROUP BY C.CUSTOMER_ID, C.NAME, C.COUNTRY, C.SEGMENT, C.CONTRACT_TYPE;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('ETL completado correctamente: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error en ETL: ' || SQLERRM);
        RAISE;

END PRC_ETL_SERVICE_ORDERS;
/