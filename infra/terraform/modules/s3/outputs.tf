output "bucket_name" {
  description = "Nom du bucket S3 data lake."
  value       = aws_s3_bucket.data_lake.id
}

output "bucket_arn" {
  description = "ARN du bucket S3 data lake."
  value       = aws_s3_bucket.data_lake.arn
}

output "raw_prefix" {
  description = "Préfixe de la zone bronze/raw."
  value       = var.raw_prefix
}