"""
DAG d'orchestration du pipeline ELT Olist.

Enchaîne :
1. COPY INTO (chargement des CSV S3 -> tables RAW Snowflake, zone bronze)
2. dbt run (staging -> intermediate -> marts, silver -> gold) - lancé dans un
   conteneur Docker dédié (olist-dbt:latest), isolé des dépendances Airflow.
3. dbt test (46 tests dbt)
"""
import os
from datetime import datetime

from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SQLExecuteQueryOperator
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount

SNOWFLAKE_CONN_ID = "snowflake_default"
S3_STAGE = "@OLIST_S3_STAGE"

TABLES_TO_LOAD = {
    "orders": "orders/olist_orders_dataset.csv",
    "order_items": "order_items/olist_order_items_dataset.csv",
    "customers": "customers/olist_customers_dataset.csv",
    "products": "products/olist_products_dataset.csv",
    "payments": "payments/olist_order_payments_dataset.csv",
    "reviews": "reviews/olist_order_reviews_dataset.csv",
    "sellers": "sellers/olist_sellers_dataset.csv",
    "geolocation": "geolocation/olist_geolocation_dataset.csv",
    "category_translation": "category_translation/product_category_name_translation.csv",
}
FILE_FORMAT = "FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '\"' SKIP_HEADER = 1)"

# Chemins HOTE (pas ceux internes au conteneur Airflow) : DockerOperator parle
# au démon Docker de la machine hôte pour lancer un conteneur frère dbt.
HOST_DBT_PROJECT_DIR = os.environ["HOST_DBT_PROJECT_DIR"]
HOST_DBT_PROFILES_DIR = os.environ["HOST_DBT_PROFILES_DIR"]

DBT_ENV = {
    "SNOWFLAKE_ACCOUNT": os.environ.get("SNOWFLAKE_ACCOUNT", ""),
    "SNOWFLAKE_USER": os.environ.get("SNOWFLAKE_USER", ""),
    "SNOWFLAKE_PASSWORD": os.environ.get("SNOWFLAKE_PASSWORD", ""),
    "SNOWFLAKE_ROLE": os.environ.get("SNOWFLAKE_ROLE", ""),
    "SNOWFLAKE_WAREHOUSE": os.environ.get("SNOWFLAKE_WAREHOUSE", ""),
    "SNOWFLAKE_DATABASE": os.environ.get("SNOWFLAKE_DATABASE", ""),
}

default_args = {"owner": "data-engineering", "retries": 1}

with DAG(
    dag_id="olist_elt_pipeline",
    description="Pipeline ELT Olist : S3 (bronze) -> Snowflake RAW -> dbt (silver/gold, conteneur dédié)",
    default_args=default_args,
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["olist", "elt", "dbt", "snowflake", "docker"],
) as dag:

    use_context = SQLExecuteQueryOperator(
        task_id="use_warehouse_and_schema",
        conn_id=SNOWFLAKE_CONN_ID,
        sql="USE WAREHOUSE OLIST_WH; USE DATABASE OLIST; USE SCHEMA RAW;",
    )

    load_tasks = [
        SQLExecuteQueryOperator(
            task_id=f"copy_into_{table_name}",
            conn_id=SNOWFLAKE_CONN_ID,
            sql=f"COPY INTO {table_name} FROM {S3_STAGE}/{s3_path} {FILE_FORMAT};",
        )
        for table_name, s3_path in TABLES_TO_LOAD.items()
    ]

    dbt_mounts = [
        Mount(source=HOST_DBT_PROJECT_DIR, target="/usr/app/dbt", type="bind"),
        Mount(source=HOST_DBT_PROFILES_DIR, target="/root/.dbt", type="bind"),
    ]

    dbt_run = DockerOperator(
        task_id="dbt_run",
        image="olist-dbt:latest",
        command="run --profiles-dir /root/.dbt --project-dir /usr/app/dbt",
        docker_url="unix://var/run/docker.sock",
        network_mode="bridge",
        auto_remove="success",
        mounts=dbt_mounts,
        environment=DBT_ENV,
        mount_tmp_dir=False,
    )

    dbt_test = DockerOperator(
        task_id="dbt_test",
        image="olist-dbt:latest",
        command="test --profiles-dir /root/.dbt --project-dir /usr/app/dbt",
        docker_url="unix://var/run/docker.sock",
        network_mode="bridge",
        auto_remove="success",
        mounts=dbt_mounts,
        environment=DBT_ENV,
        mount_tmp_dir=False,
    )

    use_context >> load_tasks >> dbt_run >> dbt_test