terraform {
  backend "s3" {
    bucket  = "olist-tfstate-mrwabr"
    key     = "envs/dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}