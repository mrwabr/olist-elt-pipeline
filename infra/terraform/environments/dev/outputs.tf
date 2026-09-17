output "s3_bucket_name"                    { value = module.s3_data_lake.bucket_name }
output "iam_role_arn"                      { value = module.iam_snowflake_access.role_arn }
output "snowflake_storage_integration_name" { value = module.snowflake_platform.storage_integration_name }
output "snowflake_stage_name"              { value = module.snowflake_platform.stage_name }
output "snowflake_roles"                   { value = module.snowflake_platform.roles }