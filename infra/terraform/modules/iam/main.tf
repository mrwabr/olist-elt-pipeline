# Module IAM : rôle en lecture seule assumable par Snowflake (storage integration)
# pour charger les fichiers S3 (bronze) via COPY INTO / stage externe.

data "aws_caller_identity" "current" {}

locals {
  # Tant que Snowflake n'a pas encore donné son IAM user ARN (1er apply),
  # on fait confiance au root du compte AWS courant (placeholder sûr en dev).
  trust_principal = var.snowflake_iam_user_arn != "" ? var.snowflake_iam_user_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.trust_principal]
    }

    dynamic "condition" {
      for_each = var.snowflake_external_id != "" ? [1] : []
      content {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [var.snowflake_external_id]
      }
    }
  }
}

resource "aws_iam_role" "snowflake_access" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = merge(var.tags, { Project = "olist-elt-pipeline" })
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    sid     = "ListBucketRawPrefixOnly"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [var.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.raw_prefix}/*"]
    }
  }

  statement {
    sid       = "ReadRawObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${var.bucket_arn}/${var.raw_prefix}/*"]
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "${var.role_name}-s3-read"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.snowflake_access.name
  policy_arn = aws_iam_policy.s3_read.arn
}