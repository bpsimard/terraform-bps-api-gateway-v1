variable "parent_id" { }

variable "lambda_invoke_arn" { }

variable "function_deployment_api_gateways_rest_api_resource" { }

variable "deployment_api_gateways_rest_api" { }

variable "deployment_api_gateway_request_validator" { }

variable "environment_name" { }

variable "deployment_id" { }

variable "function_name" { }

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
  parent_id   = var.parent_id
  path_part   = var.function_deployment_api_gateways_rest_api_resource.path_part
}

module "api_gateways_resource_methods" {
  source                = "../api-gateway-method"
  for_each              = var.function_deployment_api_gateways_rest_api_resource.methods
  resource_id           = aws_api_gateway_resource.resource.id
  api_gateway_id        = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
  request_validator_id  = var.deployment_api_gateway_request_validator[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
  environment_to_deploy = var.environment_name
  lambda_invoke_arn     = var.lambda_invoke_arn
  method                = each.value
  deployment_id         = var.deployment_id
  function_name         = var.function_name
  api_source_arn        = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].execution_arn
}

module "api_gateway_resource" {
  source = "../api-gateway-resource"
  for_each = var.function_deployment_api_gateways_rest_api_resource.child_resources
  parent_id = aws_api_gateway_resource.resource.id
  lambda_invoke_arn = var.lambda_invoke_arn
  function_deployment_api_gateways_rest_api_resource = each.value
  deployment_api_gateways_rest_api = var.deployment_api_gateways_rest_api
  deployment_api_gateway_request_validator = var.deployment_api_gateway_request_validator
  deployment_id = var.deployment_id
}