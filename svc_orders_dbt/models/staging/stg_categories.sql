-- ============================================
-- Model: stg_categories.sql
-- Description: Staging model for Categories
-- Author: Iago Seara Vicente
-- ============================================

WITH source AS (
    SELECT
        CATEGORY_ID,
        NAME,
        SLA_DAYS
    FROM CATEGORIES
),

cleaned AS (
    SELECT
        CATEGORY_ID,
        UPPER(NAME)                             AS NAME,
        SLA_DAYS
    FROM source
)

SELECT * FROM cleaned