variable "database_name" {
  type    = string
  default = "OLIST"
}

variable "warehouse_name" {
  type    = string
  default = "OLIST_WH"
}

variable "warehouse_size" {
  type    = string
  default = "XSMALL"
}

variable "loader_role_name" {
  description = "Rôle utilisé par Airflow pour charger les données brutes (COPY INTO)."
  type        = string
  default     = "OLIST_LOADER"
}

variable "transformer_role_name" {
  description = "Rôle utilisé par dbt pour transformer (staging -> intermediate -> marts)."
  type        = string
  default     = "OLIST_TRANSFORMER"
}

variable "bi_role_name" {
  description = "Rôle en lecture seule pour les outils BI (Power BI / Metabase) sur la couche gold."
  type        = string
  default     = "OLIST_BI_READER"
}

variable "s3_bucket_name" {
  description = "Nom du bucket S3 (sans s3://) contenant la zone bronze."
  type        = string
}

variable "raw_prefix" {
  type    = string
  default = "raw"
}

variable "storage_aws_role_arn" {
  description = "ARN du rôle IAM (module iam) que Snowflake doit assumer pour lire S3."
  type        = string
}