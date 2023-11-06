
variable "usage_plan" { }
variable "api_gateway_id" { }


resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = var.api_gateway_id
  key_type      = "API_KEY"
  usage_plan_id = var.usage_plan.id
}