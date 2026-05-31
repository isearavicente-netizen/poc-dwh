-- ============================================
-- Model: stg_service_orders.sql
-- Description: Staging model for Service Orders
--              Reads from source table and
--              applies basic cleaning
-- Author: Iago Seara Vicente
-- ============================================

WITH source AS (
    SELECT
        ORDER_ID,
        CUSTOMER_ID,
        EMPLOYEE_ID,
        CATEGORY_ID,
        ORDER_DATE,
        STATUS,
        PRIORITY,
        RESOLUTION_DATE,
        AMOUNT,
        ESTIMATED_HOURS,
        ACTUAL_HOURS,
        SATISFACTION_SCORE,
        COMMENTS
    FROM SERVICE_ORDERS
),

cleaned AS (
    SELECT
        ORDER_ID,
        CUSTOMER_ID,
        EMPLOYEE_ID,
        CATEGORY_ID,
        ORDER_DATE,
        UPPER(STATUS)                           AS STATUS,
        UPPER(PRIORITY)                         AS PRIORITY,
        RESOLUTION_DATE,
        AMOUNT,
        ESTIMATED_HOURS,
        ACTUAL_HOURS,
        CASE
            WHEN SATISFACTION_SCORE BETWEEN 1 AND 5
            THEN SATISFACTION_SCORE
            ELSE NULL
        END                                     AS SATISFACTION_SCORE,
        COMMENTS
    FROM source
)

SELECT * FROM cleaned