variable "function_name" {
  description = "Name of the function to deploy.  Do not add the environment name to the function name.  This will be added for you."
}


variable "environment_name" {
  description = "Name of the environment being deployed."
}

variable "service_roles" {
  description = "List of service roles that have been created."
}

variable "deployment_api_gateways_rest_apis" {
  description = "Rest API gateways created from the deployment"
}

variable "deployment_api_gateway_request_validator" {
  description = "API Gateway request validator created from the deployment"
}

variable "deployment_id" {
}

variable "deployment_sqs_queue" {
  description = "SQS queue created from the deployment"
}

variable "deployment_policies" {
 description = "IAM policies created from the deployment"
}

variable "deployment_api_records_resource" {
  description = "Lowest API Gateway resource for Zones/{ZoneHostedId}/Records"
}

variable "deployment_api_changes_resource" {
  description = "Lowest API Gateway resource for Changes/GetById/{53Id}"
}

resource "random_string" "random_name" {
  length  = 6
  special = false
}

variable "function_resources" {

  
}

variable "function_resource_proxies" {
}




locals {
  sqs_queue_config               = try(jsondecode(file("../../../functions/${var.function_name}/configurations/${var.environment_name}/sqs_queue.json")), {})
  lambda_config                  = try(jsondecode(file("../../../functions/${var.function_name}/configurations/${var.environment_name}/lambda.json")), {})
  policy_config                  = try(jsondecode(file("../../../functions/${var.function_name}/configurations/${var.environment_name}/policies.json")), {})
  default_config                 = try(jsondecode(file("../../../default-configurations/${local.lambda_config.runtime}/defaults.json")), {})
  function_api_gateway_resources = try(jsondecode(file("../../../functions/${var.function_name}/configurations/${var.environment_name}/api_gateway_resources.json")), {})
  function_api_gateway_models    = try(jsondecode(file("../../../functions/${var.function_name}/configurations/${var.environment_name}/api_gateway_models.json")), {})
  function_api_gateway_methods   = try(jsondecode(file("../../../functions/${var.function_name}/configurations/${var.environment_name}/api_gateway_methods.json")), {})
  
  function_name                  = "${var.environment_name}-${var.deployment_id}-${var.function_name}"
  //sender_role_attachment_key     = lookup(local.sqs_queue_config, "sender_role_attachment_key", lookup(local.default_config.sqs_queue, "sender_role_attachment_key"))
  //sender_role_attachment         = local.sender_role_attachment_key != "" ? ["${var.service_roles[local.sender_role_attachment_key]["role"].arn}"] : []
}

#resource "aws_lambda_event_source_mapping" "event_source_mapping" {
#  count            = (var.function_name == "python-aws-route-53-consumer") ? 1 : 0
#  event_source_arn = var.deployment_sqs_queue.arn
#  enabled          = true
#  function_name    = module.lambda_function.lambda_function_name
#  batch_size       = 1
#}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachments" {
  #for_each   = local.lambda_config.lambda_role_policy_attachments
  for_each   = setunion(lookup(local.lambda_config, "lambda_role_policy_attachments", lookup(local.default_config.lambda, "lambda_role_policy_attachments")))
  role       = module.lambda_function.lambda_role_name
  policy_arn = each.value
}

module "lambda_function" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "6.2.0"
  description   = lookup(local.lambda_config, "function_description", "")
  function_name = local.function_name
  role_name     = local.function_name
  handler       = lookup(local.lambda_config, "handler", "index.handler")
  runtime       = lookup(local.lambda_config, "runtime", "python3.9")

  local_existing_package = lookup(local.lambda_config, "use_existing_zip", null) == true ? "../../../functions/${var.function_name}/src/${lookup(local.lambda_config, "filename", "lambda.zip")}" : null
  create_package         = lookup(local.lambda_config, "use_existing_zip", null) == true ? false : true
  source_path            = lookup(local.lambda_config, "use_existing_zip", null) != true ? "../../../functions/${var.function_name}/src" : null

  vpc_subnet_ids         = lookup(local.lambda_config, "vpc_subnet_ids", null)
  vpc_security_group_ids = lookup(local.lambda_config, "vpc_security_group_ids", null)
  attach_network_policy  = lookup(local.lambda_config, "attach_network_policy", false)
  layers                 = lookup(local.lambda_config, "layers", [])
  environment_variables  = lookup(local.lambda_config, "environment_variables", {})

  timeout     = lookup(local.lambda_config, "timeout", 300)
  memory_size = lookup(local.lambda_config, "memory_size", 128)
}



# resource "aws_api_gateway_method" "proxy" {
#   rest_api_id   = var.deployment_api_gateways_rest_apis["tcf-service"].id
#   resource_id   = var.function_resources[var.function_name].id
#   http_method   = "POST"
#   authorization = "NONE"
# }


# resource "aws_api_gateway_integration" "lambda" {
#   rest_api_id = var.deployment_api_gateways_rest_apis["tcf-service"].id
#   resource_id = var.function_resources[var.function_name].id
#   http_method = aws_api_gateway_method.proxy.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = module.lambda_function.lambda_function_invoke_arn
# }



# resource "aws_lambda_permission" "apigw" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda_function.lambda_function_name
#   principal     = "apigateway.amazonaws.com"

#   # The /*/* portion grants access from any method on any resource
#   # within the API Gateway "REST API".
#   source_arn = "${var.deployment_api_gateways_rest_apis[local.lambda_config.api_gateway_key].execution_arn}/*/*"
# }

module "api_gateways_resource_methods" {
 source                = "../api-gateway-method"
 for_each              = local.function_api_gateway_methods
 resource_id           = var.function_resources[var.function_name].id
 api_gateway        = var.deployment_api_gateways_rest_apis[each.value.rest_api_key]
 request_validator_id  = null #var.deployment_api_gateway_request_validator[each.value.rest_api_key].id
 environment_to_deploy = var.environment_name
 lambda_invoke_arn     = module.lambda_function.lambda_function_invoke_arn
 method                = each.value
 deployment_id         = var.deployment_id
 function_name         = local.function_name
}


#resource "aws_api_gateway_model" "models" {
#  for_each     = local.function_api_gateway_models
#  rest_api_id  = var.deployment_api_gateways_rest_api[each.value.deployment_rest_api_key].id
#  name         = each.value.name
#  description  = each.value.description
#  content_type = each.value.content_type
#  schema = <<EOF
#${jsonencode(each.value.value)}
#EOF
#}

#output "api_gateway_resources" {
#  value = local.function_api_gateway_resources
#}