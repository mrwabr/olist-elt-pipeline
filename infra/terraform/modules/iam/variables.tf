variable "role_name" {
  description = "Nom du rôle IAM assumé par Snowflake (storage integration) pour lire le bucket S3."
  type        = string
  default     = "olist-snowflake-s3-access"
}

variable "bucket_arn" {
  description = "ARN du bucket S3 data lake auquel Snowflake doit accéder en lecture."
  type        = string
}

variable "raw_prefix" {
  description = "Préfixe (dossier) auquel restreindre l'accès en lecture."
  type        = string
  default     = "raw"
}

# Renseignés APRES la première création de la storage integration Snowflake
# (voir l'explication du cycle ci-dessus).
variable "snowflake_iam_user_arn" {
  description = "ARN de l'IAM user Snowflake (STORAGE_AWS_IAM_USER_ARN, obtenu via DESC STORAGE INTEGRATION)."
  type        = string
  default     = ""
}

variable "snowflake_external_id" {
  description = "External ID Snowflake (STORAGE_AWS_EXTERNAL_ID, obtenu via DESC STORAGE INTEGRATION)."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}