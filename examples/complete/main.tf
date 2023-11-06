variable "aws_access_key" {
}
variable "aws_access_secret_key" {
}
variable "aws_region" {
  default = null
}
variable "aws_assume_role_arn" {
  default = null
}
variable "environment_to_deploy" {
}

module "lambda_function_gw" {
  source           = "/modules/terraform/lambda-function"
  environment_to_deploy = var.environment_to_deploy
}
