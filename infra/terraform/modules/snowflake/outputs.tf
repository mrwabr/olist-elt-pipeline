output "storage_integration_name" {
  value = snowflake_storage_integration.s3_integration.name
}

output "stage_name" {
  value = "${snowflake_database.olist.name}.${snowflake_schema.raw.name}.${snowflake_stage.s3_raw_stage.name}"
}

output "warehouse_name" {
  value = snowflake_warehouse.olist_wh.name
}

output "database_name" {
  value = snowflake_database.olist.name
}

output "roles" {
  value = {
    loader      = snowflake_account_role.loader.name
    transformer = snowflake_account_role.transformer.name
    bi_reader   = snowflake_account_role.bi_reader.name
  }
}