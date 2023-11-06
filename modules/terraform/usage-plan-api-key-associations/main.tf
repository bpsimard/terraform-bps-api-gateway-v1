
variable "usage_plan_id" {
  description = ""
}

variable "usage_plan_configuration" {
  description = ""
}

resource "aws_api_gateway_usage_plan_key" "main" {
  for_each      = var.usage_plan_configuration.uages_plan_key_associations
  key_id        = each.value.api_key_id
  key_type      = "API_KEY"
  usage_plan_id = var.usage_plan_id
}

