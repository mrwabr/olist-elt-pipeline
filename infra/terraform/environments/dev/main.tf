module "s3_data_lake" {
  source      = "../../modules/s3"
  bucket_name = var.s3_bucket_name
  environment = var.environment
}

module "iam_snowflake_access" {
  source                 = "../../modules/iam"
  bucket_arn             = module.s3_data_lake.bucket_arn
  raw_prefix             = module.s3_data_lake.raw_prefix
  snowflake_iam_user_arn = var.snowflake_iam_user_arn
  snowflake_external_id  = var.snowflake_external_id
}

module "snowflake_platform" {
  source               = "../../modules/snowflake"
  s3_bucket_name       = module.s3_data_lake.bucket_name
  raw_prefix           = module.s3_data_lake.raw_prefix
  storage_aws_role_arn = module.iam_snowflake_access.role_arn
}