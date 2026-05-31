-- ============================================
-- Model: fct_employee_performance.sql
-- Description: Employee performance fact table
--              with SLA compliance and
--              efficiency metrics
-- Author: Iago Seara Vicente
-- ============================================

WITH orders AS (
    SELECT * FROM {{ ref('stg_service_orders') }}
),

employees AS (
    SELECT * FROM {{ ref('stg_employees') }}
),

categories AS (
    SELECT * FROM {{ ref('stg_categories') }}
),

final AS (
    SELECT
        e.EMPLOYEE_ID,
        e.NAME                                          AS EMPLOYEE_NAME,
        e.DEPARTMENT,
        e.ROLE,
        COUNT(o.ORDER_ID)                               AS TOTAL_ORDERS,
        COUNT(CASE WHEN o.STATUS = 'CLOSED' THEN 1 END) AS CLOSED_ORDERS,
        ROUND(AVG(o.SATISFACTION_SCORE), 2)             AS AVG_SATISFACTION,
        ROUND(AVG(
            CASE
                WHEN o.ACTUAL_HOURS IS NULL OR o.ESTIMATED_HOURS = 0 THEN NULL
                ELSE o.ACTUAL_HOURS / o.ESTIMATED_HOURS
            END
        ), 2)                                           AS AVG_EFFICIENCY_RATIO,
        COUNT(CASE
            WHEN o.RESOLUTION_DATE IS NOT NULL
            AND (o.RESOLUTION_DATE - o.ORDER_DATE) <= cat.SLA_DAYS
            THEN 1
        END)                                            AS SLA_MET_COUNT,
        COUNT(CASE
            WHEN o.RESOLUTION_DATE IS NOT NULL
            AND (o.RESOLUTION_DATE - o.ORDER_DATE) > cat.SLA_DAYS
            THEN 1
        END)                                            AS SLA_BREACH_COUNT,
        SUM(o.AMOUNT)                                   AS TOTAL_AMOUNT,
        SYSDATE                                         AS LOAD_DATE
    FROM employees e
    JOIN orders o       ON e.EMPLOYEE_ID  = o.EMPLOYEE_ID
    JOIN categories cat ON o.CATEGORY_ID  = cat.CATEGORY_ID
    GROUP BY e.EMPLOYEE_ID, e.NAME, e.DEPARTMENT, e.ROLE
)

SELECT * FROM final