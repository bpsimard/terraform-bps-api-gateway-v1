variable "aws_access_key_id" {
  description = "AWS Access key used to assume deployment role in account."
}

variable "aws_secret_access_key" {
  description = "AWS Secret key used to assume deployment role in account."
}

variable "aws_region" {
  description = "AWS Region to deploy resources in."
}

variable "endpoint_url_append" {
  description = "append to to the end of the endpoint url.  Example /create"
  default = "none"
}

variable "payload" {
  description = "Body payload"
}

variable "method" {
  description = "Method to use for the request post, put, patch, get"
}

variable "api_endpoint_configuration" {
  description = "API endpoint configuration to use for this request."
}

locals {
  payload = jsonencode(var.payload)
  role_to_assume = var.api_endpoint_configuration.secret.data.assume_role_arn
  secret_name = var.api_endpoint_configuration.secret.data.name
  endpoint_url = var.api_endpoint_configuration.endpoint_url
  authentication_type = var.api_endpoint_configuration.authentication_type
  method = var.method
  endpoint_url_append = var.endpoint_url_append
}

resource "random_string" "random_for_filename" {
  length  = 8
  special = false
}

resource "null_resource" "api_execute" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
  provisioner "local-exec" {
    command = "python3  ${path.module}/temp_${random_string.random_for_filename.result}.py ${local.role_to_assume} ${local.secret_name} ${local.endpoint_url} '${local.endpoint_url_append}' ${local.authentication_type} ${local.method} ${local.payload}"
    environment = {
      AWS_ACCESS_KEY_ID     = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
      AWS_DEFAULT_REGION    = var.aws_region
    }
  }
  depends_on = [
    local_file.api_request
  ]
}

resource "local_file" "api_request" {
  content = templatefile("${path.module}/execute.py", {
  })
  filename = "${path.module}/temp_${random_string.random_for_filename.result}.py"
}

