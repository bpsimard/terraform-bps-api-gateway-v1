variable "lambda_invoke_arn" {
}

variable "function_deployment_api_gateways_rest_api_resource" {
  default = null

}
variable "deployment_api_gateways_rest_api" {
  default = null
}

variable "deployment_api_gateway_request_validator" {
  default = null
}

variable "environment_name" {

}

variable "key" {

}

variable "deployment_id" {
  
}

variable "function_name" {

}

# module "api_gateways_resource" {
#   source                                             = "../api-gateway-resource"
#   for_each                                           = var.function_deployment_api_gateways_rest_api_resource
#   parent_id                                          = var.deployment_api_gateways_rest_api.root_resource_id
#   function_deployment_api_gateways_rest_api_resource = each.value
#   deployment_api_gateways_rest_api                   = var.deployment_api_gateways_rest_api
#   environment_name                                   = var.environment_name
#   lambda_invoke_arn                                  = module.lambda_function.lambda_function_invoke_arn
#   deployment_id                                      = var.deployment_id
#   function_name                                      = local.function_name
#   deployment_api_gateway_request_validator           = var.deployment_api_gateway_request_validator
# }

# API Gateway resource for path Zones/{ZoneHostedId}/Records
# resource "aws_api_gateway_resource" "zones_resource" {
#   count = (var.key == "Zones") ? 1 : 0
#   rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   parent_id   = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].root_resource_id
#   path_part   = "Zones"
# }

# # API Gateway resource for path Zones/{ZoneHostedId}/Records
# resource "aws_api_gateway_resource" "proxy_resource" {
#   count = (var.key == "Zones") ? 1 : 0
#   rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   parent_id   = aws_api_gateway_resource.zones_resource[count.index].id
#   path_part   = "{ZoneHostedId}"
# }

# # API Gateway resource for path Zones/{ZoneHostedId}/Records
# resource "aws_api_gateway_resource" "records_resource" {
#   count = (var.key == "Zones") ? 1 : 0
#   rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   parent_id   = aws_api_gateway_resource.proxy_resource[count.index].id
#   path_part   = "Records"
# }

# # API Gateway resource for path Changes/GetById/{53id}
# resource "aws_api_gateway_resource" "changes_resource" {
#   count = (var.key == "Changes") ? 1 : 0
#   rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   parent_id   = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].root_resource_id
#   path_part   = "Changes"
# }

# # API Gateway resource for path Changes/GetById/{53id}
# resource "aws_api_gateway_resource" "get_by_id_resource" {
#   count = (var.key == "Changes") ? 1 : 0
#   rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   parent_id   = aws_api_gateway_resource.changes_resource[count.index].id
#   path_part   = "GetById"
# }

# # API Gateway resource for path Changes/GetById/{53id}
# resource "aws_api_gateway_resource" "id_proxy_resource" {
#   count = (var.key == "Changes") ? 1 : 0
#   rest_api_id = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   parent_id   = aws_api_gateway_resource.get_by_id_resource[count.index].id
#   path_part   = "{53id}"
# }

# module "api_gateways_resource_methods" {
#   count                 =  deployment_api_gateways_rest_api != null && deployment_api_gateways_rest_api != null function_deployment_api_gateways_rest_api_resource != null ? 0 : 1
#   source                = "../api-gateway-method"
#   for_each              = var.function_deployment_api_gateways_rest_api_resource.methods
#   resource_id           = (var.key == "Zones") ? aws_api_gateway_resource.records_resource[0].id : (var.key == "Changes") ? aws_api_gateway_resource.id_proxy_resource[0].id : var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].root_resource_id
#   api_gateway_id        = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   request_validator_id  = var.deployment_api_gateway_request_validator[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].id
#   environment_to_deploy = var.environment_name
#   lambda_invoke_arn     = var.lambda_invoke_arn
#   method                = each.value
#   deployment_id         = var.deployment_id
#   function_name         = var.function_name
#   api_source_arn        = var.deployment_api_gateways_rest_api[var.function_deployment_api_gateways_rest_api_resource.aws_api_gateway_rest_api_key].execution_arn
#   api_resource_key      = var.key
# }