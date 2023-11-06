



resource "aws_api_gateway_usage_plan" "api_gateways_usage_plans" {
  for_each    = aws_api_gateway_stage.api_gateways_stages
  name        = "${var.environment_to_deploy}-${var.deployment_id}-dns-service-usage-plan-${each.value.stage_name}"
  description = "API usage plan for dns-service ${each.value.stage_name} stage."
  api_stages {
    api_id = each.value.rest_api_id
    stage  = each.value.stage_name
  }
}

resource "aws_api_gateway_api_key" "api_gateways_api_keys" {
  name        = "${var.environment_to_deploy}-${var.deployment_id}-dns-service-api-key"
  description = "API key for service."
  enabled     = true
}

resource "aws_api_gateway_usage_plan_key" "api_gateways_usage_plan_keys" {
  for_each      = aws_api_gateway_usage_plan.api_gateways_usage_plans
  key_id        = aws_api_gateway_api_key.api_gateways_api_keys.id
  key_type      = "API_KEY"
  usage_plan_id = each.value.id
}