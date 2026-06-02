-- ============================================
-- Model: stg_employees.sql
-- Description: Staging model for Employees
-- Author: Iago Seara Vicente
-- ============================================

WITH source AS (
    SELECT
        EMPLOYEE_ID,
        NAME,
        DEPARTMENT,
        ROLE,
        EMAIL,
        HIRE_DATE,
        SALARY,
        LOCATION
    FROM EMPLOYEES
),

cleaned AS (
    SELECT
        EMPLOYEE_ID,
        INITCAP(NAME)                           AS NAME,
        UPPER(DEPARTMENT)                       AS DEPARTMENT,
        UPPER(ROLE)                             AS ROLE,
        LOWER(EMAIL)                            AS EMAIL,
        HIRE_DATE,
        SALARY,
        UPPER(LOCATION)                         AS LOCATION
    FROM source
)

SELECT * FROM cleaned