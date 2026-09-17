terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 0.100"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "snowflake" {
  role = "ACCOUNTADMIN"
}