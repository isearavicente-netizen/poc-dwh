-- ============================================
-- Script: 04_create_dwh_tables.sql
-- Description: Creates the destination tables
--              for the ETL process
-- Author: Iago Seara Vicente
-- ============================================

CREATE TABLE DWH_ORDERS_SUMMARY (
    ORDER_ID              NUMBER PRIMARY KEY,
    CUSTOMER_NAME         VARCHAR2(100),
    EMPLOYEE_NAME         VARCHAR2(100),
    CATEGORY_NAME         VARCHAR2(50),
    ORDER_DATE            DATE,
    RESOLUTION_DATE       DATE,
    STATUS                VARCHAR2(20),
    PRIORITY              VARCHAR2(20),
    AMOUNT                NUMBER(10,2),
    ESTIMATED_HOURS       NUMBER(5,2),
    ACTUAL_HOURS          NUMBER(5,2),
    RESOLUTION_DAYS       NUMBER,
    SLA_DAYS              NUMBER,
    SLA_MET               VARCHAR2(3),
    EFFICIENCY_RATIO      NUMBER(5,2),
    SATISFACTION_SCORE    NUMBER(2),
    LOAD_DATE             DATE
);

CREATE TABLE DWH_EMPLOYEE_PERFORMANCE (
    EMPLOYEE_ID           NUMBER PRIMARY KEY,
    EMPLOYEE_NAME         VARCHAR2(100),
    DEPARTMENT            VARCHAR2(50),
    ROLE                  VARCHAR2(50),
    TOTAL_ORDERS          NUMBER,
    CLOSED_ORDERS         NUMBER,
    AVG_SATISFACTION      NUMBER(4,2),
    AVG_EFFICIENCY_RATIO  NUMBER(5,2),
    SLA_MET_COUNT         NUMBER,
    SLA_BREACH_COUNT      NUMBER,
    TOTAL_AMOUNT          NUMBER(10,2),
    LOAD_DATE             DATE
);

CREATE TABLE DWH_CUSTOMER_ANALYSIS (
    CUSTOMER_ID           NUMBER PRIMARY KEY,
    CUSTOMER_NAME         VARCHAR2(100),
    COUNTRY               VARCHAR2(50),
    SEGMENT               VARCHAR2(30),
    CONTRACT_TYPE         VARCHAR2(20),
    TOTAL_ORDERS          NUMBER,
    CLOSED_ORDERS         NUMBER,
    TOTAL_AMOUNT          NUMBER(10,2),
    AVG_SATISFACTION      NUMBER(4,2),
    SLA_MET_COUNT         NUMBER,
    SLA_BREACH_COUNT      NUMBER,
    LOAD_DATE             DATE
);