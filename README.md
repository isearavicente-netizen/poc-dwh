# Modernización de Data Warehouse basado en PL/SQL mediante Modern Data Stack

## Descripción
Prueba de concepto desarrollada como parte del Trabajo Fin de Máster en Análisis y Visualización de Datos Masivos (UNIR).

El proyecto demuestra la migración progresiva de un pipeline ETL basado en PL/SQL hacia un stack moderno compuesto por Apache Airflow, DBT Core y Power BI, sobre una base de datos Oracle XE con datos sintéticos.

## Stack tecnológico
- **Base de datos:** Oracle XE 21c
- **ETL Legacy:** PL/SQL (procedures y jobs Oracle)
- **Orquestación:** Apache Airflow 2.9.0
- **Transformación:** DBT Core 1.11
- **Visualización:** Power BI Desktop
- **Contenedores:** Docker

## Estructura del repositorio
poc-dwh/
├── sql/
│   ├── setup/          # Creación de usuario y permisos
│   ├── tables/         # Creación de tablas origen y destino
│   ├── data/           # Datos sintéticos
│   └── procedures/     # ETL legacy en PL/SQL y jobs
├── airflow/
│   ├── dags/           # DAGs de Airflow
│   └── dbt/            # Proyecto DBT montado en Docker
├── svc_orders_dbt/     # Proyecto DBT Core
│   ├── models/
│   │   ├── staging/    # Modelos de limpieza y estandarización
│   │   └── marts/      # Modelos analíticos finales
│   └── profiles.yml    # Configuración de conexión
├── powerbi/            # Dashboards Power BI
└── README.md

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
-- Ejecutar sql/tables/02_create_tables.sql
-- Ejecutar sql/data/03_insert_data.sql
-- Ejecutar sql/tables/04_create_dwh_tables.sql
-- Ejecutar sql/procedures/05_etl_procedure.sql
-- Ejecutar sql/procedures/06_etl_job.sql
```

**2. Arrancar Airflow**
```bash
cd airflow
docker compose up
```

**3. Ejecutar DBT de forma independiente**
```bash
cd svc_orders_dbt
dbt run
dbt docs serve --port 8081
```

**4. Acceder a Airflow**
- URL: http://localhost:8080
- Usuario: airflow
- Contraseña: airflow

**5. DAGs disponibles**
- `etl_service_orders` — pipeline ETL Python con Airflow
- `etl_dbt_service_orders` — pipeline moderno Airflow + DBT integrados

## Autor
Iago Seara Vicente — TFM UNIR 2025-2026

