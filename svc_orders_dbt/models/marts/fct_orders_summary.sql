-- ============================================
-- Model: fct_orders_summary.sql
-- Description: Orders summary fact table with
--              SLA compliance and efficiency
--              calculations
-- Author: Iago Seara Vicente
-- ============================================

WITH orders AS (
    SELECT * FROM {{ ref('stg_service_orders') }}
),

employees AS (
    SELECT * FROM {{ ref('stg_employees') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

categories AS (
    SELECT * FROM {{ ref('stg_categories') }}
),

final AS (
    SELECT
        o.ORDER_ID,
        c.NAME                                          AS CUSTOMER_NAME,
        e.NAME                                          AS EMPLOYEE_NAME,
        cat.NAME                                        AS CATEGORY_NAME,
        o.ORDER_DATE,
        o.RESOLUTION_DATE,
        o.STATUS,
        o.PRIORITY,
        o.AMOUNT,
        o.ESTIMATED_HOURS,
        o.ACTUAL_HOURS,
        CASE
            WHEN o.RESOLUTION_DATE IS NOT NULL
            THEN o.RESOLUTION_DATE - o.ORDER_DATE
            ELSE NULL
        END                                             AS RESOLUTION_DAYS,
        cat.SLA_DAYS,
        CASE
            WHEN o.RESOLUTION_DATE IS NULL THEN 'N/A'
            WHEN (o.RESOLUTION_DATE - o.ORDER_DATE) <= cat.SLA_DAYS THEN 'YES'
            ELSE 'NO'
        END                                             AS SLA_MET,
        CASE
            WHEN o.ACTUAL_HOURS IS NULL OR o.ESTIMATED_HOURS = 0 THEN NULL
            ELSE ROUND(o.ACTUAL_HOURS / o.ESTIMATED_HOURS, 2)
        END                                             AS EFFICIENCY_RATIO,
        o.SATISFACTION_SCORE,
        SYSDATE                                         AS LOAD_DATE
    FROM orders o
    JOIN customers c    ON o.CUSTOMER_ID  = c.CUSTOMER_ID
    JOIN employees e    ON o.EMPLOYEE_ID  = e.EMPLOYEE_ID
    JOIN categories cat ON o.CATEGORY_ID  = cat.CATEGORY_ID
)

SELECT * FROM final