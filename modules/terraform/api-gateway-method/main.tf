variable "method" {

}

variable "api_gateway" {

}

variable "resource_id" {

}

variable "lambda_invoke_arn" {

}

variable "environment_to_deploy" {

}

variable "deployment_id" {
  
}

variable "function_name" {

}

variable "request_validator_id" {

}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id          = var.api_gateway.id
  resource_id          = var.resource_id
  http_method          = var.method.http_method
  authorization        = var.method.authorization
  api_key_required     = var.method.api_key_required
  #request_validator_id = null #var.request_validator_id

  # request_models = (var.method.http_method != "GET") ? {
  #   "application/json" = "route53records"
  # } : null
  # request_parameters = lookup(var.method, "query_params", null) != null ? {
  #   for s in var.method.query_params : "method.request.querystring.${s}" => false
  # } : null
}


resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = var.api_gateway.id
  resource_id = var.resource_id
  http_method = var.method.http_method

  integration_http_method = var.method.integration.integration_http_method
  type                    = var.method.integration.type
  uri                     = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${var.api_gateway.execution_arn}/*/*"
}