# Module S3 : data lake "bronze" pour le pipeline Olist
# - 1 bucket versionné, chiffré, avec accès public bloqué
# - Organisation logique en préfixes : raw/<table>/... (bronze)

resource "aws_s3_bucket" "data_lake" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Project     = "olist-elt-pipeline"
    Environment = var.environment
    Layer       = "bronze"
  })
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket                  = aws_s3_bucket.data_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "raw-transition-to-ia"
    status = "Enabled"

    filter {
      prefix = "${var.raw_prefix}/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

# "Dossiers" logiques créés vides pour matérialiser l'organisation bronze
# (un objet S3 par table source Olist).
resource "aws_s3_object" "raw_prefixes" {
  for_each = toset([
    "orders", "order_items", "customers", "products", "payments",
    "reviews", "sellers", "geolocation", "category_translation"
  ])

  bucket       = aws_s3_bucket.data_lake.id
  key          = "${var.raw_prefix}/${each.value}/.keep"
  content      = ""
  content_type = "text/plain"
}