
variable "aws_access_key_commercial" {
  default = null

}
variable "aws_access_secret_key_commercial" {
  default = null
}
variable "aws_region" {
  default = null
}
variable "aws_assume_role_arn" {
  default = null
}


provider "aws" {
  access_key = var.aws_access_key_commercial
  secret_key = var.aws_access_secret_key_commercial
  region     = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::638050436593:role/Terraform/Terraform"
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