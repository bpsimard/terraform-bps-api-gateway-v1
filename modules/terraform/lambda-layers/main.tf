variable "layer_name" {
  description = "Name of the function to deploy.  Do not add the environment name to the function name.  This will be added for you."
}

variable "environment_name" {
  description = "Name of the environment being deployed."
}

resource "random_string" "random_name" {
  length  = 6
  special = false
}

locals {
  lambda_config = jsondecode(file("../../../layers/${var.layer_name}/configurations/${var.environment_name}/lambda.json"))
  layer_name    = "${var.environment_name}-${var.layer_name}"
}

module "lambda_layer_local" {
  source              = "terraform-aws-modules/lambda/aws"
  create_layer        = true
  layer_name          = local.layer_name
  description         = lookup(local.lambda_config, "description", null)
  compatible_runtimes = lookup(local.lambda_config, "compatible_runtimes", null)
  source_path         = "../../../layers/${var.layer_name}/src"
}
