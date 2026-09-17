variable "aws_region" {
  type    = string
  default = "eu-west-1"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "s3_bucket_name" {
  type = string
}
variable "snowflake_iam_user_arn" {
  type    = string
  default = ""
}
variable "snowflake_external_id" {
  type    = string
  default = ""
}