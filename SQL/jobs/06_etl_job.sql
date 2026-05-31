-- ============================================
-- Script: 06_etl_job.sql
-- Description: Scheduled job that executes
--              the ETL procedure daily
-- Author: Iago Seara Vicente
-- ============================================

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'JOB_ETL_SERVICE_ORDERS',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PRC_ETL_SERVICE_ORDERS',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=6; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Daily ETL job for Service Orders DWH'
    );
END;
/