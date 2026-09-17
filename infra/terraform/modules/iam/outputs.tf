output "role_arn" {
  description = "ARN du rôle IAM à fournir à Snowflake (STORAGE_AWS_ROLE_ARN)."
  value       = aws_iam_role.snowflake_access.arn
}

output "role_name" {
  value = aws_iam_role.snowflake_access.name
}