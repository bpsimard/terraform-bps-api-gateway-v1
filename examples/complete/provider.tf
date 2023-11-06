provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_access_secret_key
  region     = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::111111111:role/Terraform/Terraform"
  }
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.21.0"
    }
  }
}