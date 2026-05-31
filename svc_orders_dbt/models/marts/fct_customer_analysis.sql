-- ============================================
-- Model: fct_customer_analysis.sql
-- Description: Customer analysis fact table
--              with order metrics and
--              SLA compliance
-- Author: Iago Seara Vicente
-- ============================================

WITH orders AS (
    SELECT * FROM {{ ref('stg_service_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

categories AS (
    SELECT * FROM {{ ref('stg_categories') }}
),

final AS (
    SELECT
        c.CUSTOMER_ID,
        c.NAME                                          AS CUSTOMER_NAME,
        c.COUNTRY,
        c.SEGMENT,
        c.CONTRACT_TYPE,
        COUNT(o.ORDER_ID)                               AS TOTAL_ORDERS,
        COUNT(CASE WHEN o.STATUS = 'CLOSED' THEN 1 END) AS CLOSED_ORDERS,
        SUM(o.AMOUNT)                                   AS TOTAL_AMOUNT,
        ROUND(AVG(o.SATISFACTION_SCORE), 2)             AS AVG_SATISFACTION,
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
        SYSDATE                                         AS LOAD_DATE
    FROM customers c
    JOIN orders o       ON c.CUSTOMER_ID  = o.CUSTOMER_ID
    JOIN categories cat ON o.CATEGORY_ID  = cat.CATEGORY_ID
    GROUP BY c.CUSTOMER_ID, c.NAME, c.COUNTRY, c.SEGMENT, c.CONTRACT_TYPE
)

SELECT * FROM final