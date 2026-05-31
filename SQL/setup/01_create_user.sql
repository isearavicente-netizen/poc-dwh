-- ============================================
-- Script: 01_create_user.sql
-- Description: Creates the POC user and grants
--              necessary permissions
-- Author: Iago Seara Vicente
-- ============================================

-- Connect as SYSDBA to XEPDB1 before running
-- sqlplus sys@localhost:1521/xepdb1 as sysdba

CREATE USER svc_orders IDENTIFIED BY poc123;
GRANT CONNECT, RESOURCE TO svc_orders;
GRANT CREATE SESSION TO svc_orders;
GRANT UNLIMITED TABLESPACE TO svc_orders;