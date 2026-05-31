-- ============================================
-- Model: stg_customers.sql
-- Description: Staging model for Customers
-- Author: Iago Seara Vicente
-- ============================================

WITH source AS (
    SELECT
        CUSTOMER_ID,
        NAME,
        COUNTRY,
        CITY,
        SEGMENT,
        CONTRACT_TYPE,
        REGISTRATION_DATE
    FROM CUSTOMERS
),

cleaned AS (
    SELECT
        CUSTOMER_ID,
        INITCAP(NAME)                           AS NAME,
        INITCAP(COUNTRY)                        AS COUNTRY,
        INITCAP(CITY)                           AS CITY,
        UPPER(SEGMENT)                          AS SEGMENT,
        UPPER(CONTRACT_TYPE)                    AS CONTRACT_TYPE,
        REGISTRATION_DATE
    FROM source
)

SELECT * FROM cleaned