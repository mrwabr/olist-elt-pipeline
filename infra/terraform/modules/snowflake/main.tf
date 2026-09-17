# Module Snowflake : warehouse, database/schemas (RAW/bronze, STAGING/silver via dbt,
# ANALYTICS/gold via dbt), storage integration vers S3, rôles RBAC least-privilege.

resource "snowflake_warehouse" "olist_wh" {
  name                = var.warehouse_name
  warehouse_size      = var.warehouse_size
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse dédié au pipeline ELT Olist (ingestion + dbt)."
}

resource "snowflake_database" "olist" {
  name    = var.database_name
  comment = "Data warehouse Olist - bronze (RAW) / silver (STAGING) / gold (ANALYTICS)."
}

resource "snowflake_schema" "raw" {
  database = snowflake_database.olist.name
  name     = "RAW"
  comment  = "Zone bronze : données brutes chargées depuis S3 via COPY INTO."
}

resource "snowflake_schema" "staging" {
  database = snowflake_database.olist.name
  name     = "STAGING"
  comment  = "Zone silver, gérée par dbt (models/staging + intermediate)."
}

resource "snowflake_schema" "analytics" {
  database = snowflake_database.olist.name
  name     = "ANALYTICS"
  comment  = "Zone gold, gérée par dbt (models/marts) : tables consommées par le BI."
}

# ---- Storage integration vers S3 (bronze) ----
resource "snowflake_storage_integration" "s3_integration" {
  name                      = "OLIST_S3_INTEGRATION"
  storage_provider          = "S3"
  enabled                   = true
  storage_aws_role_arn      = var.storage_aws_role_arn
  storage_allowed_locations = ["s3://${var.s3_bucket_name}/${var.raw_prefix}/"]
  comment                   = "Intégration de stockage pour charger les CSV Olist depuis S3 (bronze)."
}

resource "snowflake_stage" "s3_raw_stage" {
  name                = "OLIST_S3_STAGE"
  database            = snowflake_database.olist.name
  schema              = snowflake_schema.raw.name
  url                 = "s3://${var.s3_bucket_name}/${var.raw_prefix}/"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '\"' SKIP_HEADER = 1 NULL_IF = ('', 'NULL')"
  comment             = "Stage externe pointant vers la zone bronze S3."
}

# ---- Rôles RBAC (nouvelle ressource: snowflake_account_role) ----
resource "snowflake_account_role" "loader" {
  name    = var.loader_role_name
  comment = "Rôle Airflow : COPY INTO RAW uniquement."
}

resource "snowflake_account_role" "transformer" {
  name    = var.transformer_role_name
  comment = "Rôle dbt : lecture RAW, écriture STAGING/ANALYTICS."
}

resource "snowflake_account_role" "bi_reader" {
  name    = var.bi_role_name
  comment = "Rôle BI (Power BI / Metabase) : lecture ANALYTICS (gold) uniquement."
}

# ---- Grants : usage warehouse pour les 3 rôles ----
resource "snowflake_grant_privileges_to_account_role" "wh_usage" {
  for_each = toset([
    snowflake_account_role.loader.name,
    snowflake_account_role.transformer.name,
    snowflake_account_role.bi_reader.name,
  ])

  account_role_name = each.value
  privileges         = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.olist_wh.name
  }
}

# ---- Grants : usage database pour les 3 rôles ----
resource "snowflake_grant_privileges_to_account_role" "db_usage" {
  for_each = toset([
    snowflake_account_role.loader.name,
    snowflake_account_role.transformer.name,
    snowflake_account_role.bi_reader.name,
  ])

  account_role_name = each.value
  privileges         = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.olist.name
  }
}

# ---- Grants : ALL PRIVILEGES sur RAW pour le loader (Airflow) ----
resource "snowflake_grant_privileges_to_account_role" "loader_raw" {
  account_role_name = snowflake_account_role.loader.name
  privileges         = ["ALL PRIVILEGES"]
  on_schema {
    schema_name = "\"${snowflake_database.olist.name}\".\"${snowflake_schema.raw.name}\""
  }
}

# ---- Grants : USAGE sur RAW pour dbt (lecture des sources) ----
resource "snowflake_grant_privileges_to_account_role" "transformer_raw_read" {
  account_role_name = snowflake_account_role.transformer.name
  privileges         = ["USAGE"]
  on_schema {
    schema_name = "\"${snowflake_database.olist.name}\".\"${snowflake_schema.raw.name}\""
  }
}

# ---- Grants : ALL PRIVILEGES sur STAGING pour dbt ----
resource "snowflake_grant_privileges_to_account_role" "transformer_staging" {
  account_role_name = snowflake_account_role.transformer.name
  privileges         = ["ALL PRIVILEGES"]
  on_schema {
    schema_name = "\"${snowflake_database.olist.name}\".\"${snowflake_schema.staging.name}\""
  }
}

# ---- Grants : ALL PRIVILEGES sur ANALYTICS pour dbt ----
resource "snowflake_grant_privileges_to_account_role" "transformer_analytics" {
  account_role_name = snowflake_account_role.transformer.name
  privileges         = ["ALL PRIVILEGES"]
  on_schema {
    schema_name = "\"${snowflake_database.olist.name}\".\"${snowflake_schema.analytics.name}\""
  }
}

# ---- Grants : USAGE sur ANALYTICS pour le BI (lecture gold) ----
resource "snowflake_grant_privileges_to_account_role" "bi_reader_analytics" {
  account_role_name = snowflake_account_role.bi_reader.name
  privileges         = ["USAGE"]
  on_schema {
    schema_name = "\"${snowflake_database.olist.name}\".\"${snowflake_schema.analytics.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_create_schema" {
  account_role_name = snowflake_account_role.transformer.name
  privileges         = ["CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.olist.name
  }
}