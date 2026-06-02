## Cómo reproducir la POC

### Prerrequisitos
- Oracle XE 21c instalado
- Docker Desktop instalado
- Python 3.11 instalado

### Pasos

**1. Configurar Oracle**
```sql
-- Ejecutar como sysdba
sqlplus / as sysdba
ALTER SESSION SET CONTAINER = XEPDB1;
-- Ejecutar sql/setup/01_create_user.sql
-- Ejecutar sql/tablas/02_create_tables.sql
-- Ejecutar sql/datos/03_insert_data.sql
-- Ejecutar sql/tablas/04_create_dwh_tables.sql
-- Ejecutar sql/procedures/05_etl_procedure.sql
-- Ejecutar sql/procedures/06_etl_job.sql
```

**2. Arrancar Airflow**
```bash
cd airflow
docker compose up
```

**3. Ejecutar DBT**
```bash
cd svc_orders_dbt
dbt run
dbt docs serve --port 8081
```

**4. Acceder a Airflow**
- URL: http://localhost:8080
- Usuario: airflow
- Contraseña: airflow

## Autor
Iago Seara Vicente — TFM UNIR 2025-2026