variable "environment_to_deploy" {
}
variable "deployment_id" {
}


locals {
  lambda_functions_config = try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/functions.json")), {}) 
  environment_to_deploy = var.environment_to_deploy
  service_roles =  try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/service_roles.json")), {}) 
  deployment_polices =  try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/policies.json")), {}) 
  api_gateway_config =  try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/api_gateways.json")), {}) 
  api_keys =  try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/api_keys.json")), {}) 
  api_gateway_usage_plans = try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/api_gateway_usage_plans.json")), {}) 
  dynamodb_tables_config = try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/dynamodb_tables.json")), {}) 
  deployment_sqs_queue_config = try(jsondecode(file("${path.module}/configurations/${var.environment_to_deploy}/sqs_queues.json")), {})
  deployment_api_gateways_rest_apis = aws_api_gateway_rest_api.api_gateways_rest_api
  active_environment_functions = { for k,v in local.lambda_functions_config : k => v if v.environment == var.environment_to_deploy && v.deploy == true }
#   queue_resource_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Resource": "arn:aws:sqs:us-east-1:638050436593:${var.environment_to_deploy}-${var.deployment_id}-tcf-service",
#       "Action": [
#                 "sqs:GetQueueUrl",
#                 "sqs:ListQueues",
#                 "sqs:SendMessage",
#                 "sqs:ReceiveMessage",
#                 "sqs:GetQueueAttributes",
#                 "sqs:ListDeadLetterSourceQueues",
#                 "sqs:ListQueueTags"
#       ],
#       "Effect": "Allow",
#       "Principal": {
#          "AWS": "arn:aws:iam::638050436593:role/development-DOP8HY88-service_catalog_sender"
#       }
      
#     }
#   ]
# }
# EOF
}

resource "aws_sqs_queue" "function_queue" {
  name                       = "${var.environment_to_deploy}-${var.deployment_id}-tcf-service"
  delay_seconds              = lookup(local.deployment_sqs_queue_config, "delay_seconds", 90)
  max_message_size           = lookup(local.deployment_sqs_queue_config, "max_message_size", 2048)
  message_retention_seconds  = lookup(local.deployment_sqs_queue_config, "message_retention_seconds", 864000)
  receive_wait_time_seconds  = lookup(local.deployment_sqs_queue_config, "receive_wait_time_seconds", 1)
  visibility_timeout_seconds = lookup(local.deployment_sqs_queue_config, "visibility_timeout_seconds", 300)
  
  #policy                     = local.queue_resource_policy
  tags = {
    Environment = var.environment_to_deploy
  }
}

module "lambda_function" {
  depends_on = [
    module.dynamodb_tables
  ]
  source           = "../../../modules/terraform/lambda-function"
  for_each         = local.active_environment_functions
  environment_name = var.environment_to_deploy
  function_name    = each.value.name

  service_roles    = module.service_roles
  deployment_api_gateways_rest_apis = aws_api_gateway_rest_api.api_gateways_rest_api
  deployment_id = var.deployment_id
  deployment_sqs_queue = aws_sqs_queue.function_queue
  deployment_policies = aws_iam_policy.deployment_policies
  deployment_api_gateway_request_validator = null #aws_api_gateway_request_validator.api_gateways_request_validators
  deployment_api_records_resource = null #aws_api_gateway_resource.records_resource
  deployment_api_changes_resource = null #aws_api_gateway_resource.id_proxy_resource
  #function_methods = null #aws_api_gateway_method.proxy
  function_resources = aws_api_gateway_resource.function_resource
  function_resource_proxies = null #aws_api_gateway_resource.proxy
}

module "service_roles" {
  depends_on = [
    module.dynamodb_tables
  ]
  source = "../modules/service-roles"
  deployment_id = var.deployment_id
  for_each = local.service_roles
  service_role = each.value
  environment_to_deploy = var.environment_to_deploy
}


resource "aws_iam_policy" "deployment_policies" {
  depends_on = [
    module.dynamodb_tables
  ]
  for_each = local.deployment_polices
  name        = "${var.environment_to_deploy}-${var.deployment_id}-${each.key}"
  path        = "/"
  description = each.value.description

  policy = jsonencode(each.value.policy)
}

resource "aws_api_gateway_rest_api" "api_gateways_rest_api" {
  for_each       = local.api_gateway_config
  name           = "${var.environment_to_deploy}-${var.deployment_id}-${each.key}"
  description    = each.value.description
  api_key_source = each.value.api_key_source
  endpoint_configuration {
    types = each.value.endpoint_configuration.types
  }
}

resource "aws_api_gateway_resource" "function_resource" {
  for_each = local.active_environment_functions
  rest_api_id = local.deployment_api_gateways_rest_apis[each.value.api_gateway_key].id
  parent_id   = local.deployment_api_gateways_rest_apis[each.value.api_gateway_key].root_resource_id
  path_part   = each.value.name
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    module.lambda_function
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  rest_api_id = aws_api_gateway_rest_api.api_gateways_rest_api["tcf-service"].id
  stage_name  = (var.environment_to_deploy == "production") ? "prod" : "dev"
}

# resource "aws_api_gateway_request_validator" "api_gateways_request_validators" {
#   for_each                    = aws_api_gateway_rest_api.api_gateways_rest_api
#   name                        = "body-only"
#   rest_api_id                 = each.value.id
#   validate_request_body       = true
#   validate_request_parameters = false
# }

resource "aws_api_gateway_usage_plan" "api_gateways_usage_plans" {
  for_each         = local.api_gateway_usage_plans
  depends_on = [aws_api_gateway_deployment.deployment]
  name        = "${var.environment_to_deploy}-${var.deployment_id}-${each.value.name}"
  description = each.value.description
  api_stages {
      api_id = local.deployment_api_gateways_rest_apis[each.value.stages[var.environment_to_deploy]["api_gateway_key"]].id
      stage = (var.environment_to_deploy == "production") ? "prod" : "dev"
  }
}

module "usages_plan_api_key_associations" {
  source                    = "../../../modules/terraform/usage-plan-api-key-associations"
  for_each                  = local.api_gateway_usage_plans
  usage_plan_id     = aws_api_gateway_usage_plan.api_gateways_usage_plans[each.key].id
  usage_plan_configuration  = each.value
  #api_gateway_resources     = aws_api_gateway_rest_api.api_gateways_rest_api
}


# resource "aws_api_gateway_domain_name" "example" {
#   certificate_arn = aws_acm_certificate_validation.example.certificate_arn
#   domain_name     = "api.example.com"
# }

# # Example DNS record using Route53.
# # Route53 is not specifically required; any DNS host can be used.
# resource "aws_route53_record" "example" {
#   name    = aws_api_gateway_domain_name.example.domain_name
#   type    = "A"
#   zone_id = aws_route53_zone.example.id

#   alias {
#     evaluate_target_health = true
#     name                   = aws_api_gateway_domain_name.example.cloudfront_domain_name
#     zone_id                = aws_api_gateway_domain_name.example.cloudfront_zone_id
#   }
# }

module "dynamodb_tables" {
  for_each = local.dynamodb_tables_config
  source   = "terraform-aws-modules/dynamodb-table/aws"
  

  name     = each.value.name != null ? each.value.name : "${var.environment_to_deploy}-${var.deployment_id}-${each.key}"
  hash_key = each.value.hash_key

  attributes = each.value.attributes
}

output "deployment_polcies" {
 value =  aws_iam_policy.deployment_policies
}

# output "deployment_api_gateways_rest_api" {
#  value =  aws_api_gateway_rest_api.api_gateways_rest_api
# }

output "deployment_service_roles" {
  value = module.service_roles
}

output "deployment_lambda_outputs" {
  value = module.lambda_function
}

