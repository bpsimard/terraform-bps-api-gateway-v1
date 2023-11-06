
variable "aws_access_key" {
  description = "AWS Access key used to assume deployment role in account."
}

variable "aws_secret_key" {
  description = "AWS Secret key used to assume deployment role in account."
}

variable "aws_region" {
  description = "AWS Region to deploy resources in."
}

variable "customer_configuration" {
  description = "Customer configuration"
}

variable "customer_loadbalancers" {
  description = "Customer load balancer resources"
}

variable "shared_loadbalancers" {
  description = "Shared customer load balancer resources"
}

variable "route53_record_configuration" {
  description = "Customer route53 configuration"
}

variable "customer_aws_lb_listener_rule_configurations" {
  description = "aws_lb_listener_rule configuration for the customer."
}

variable "deployment_configuration" {
  description = "Deployment configuration (JSON)."
}

variable "api_endpoint_configurations" {
  description = "API endpoint configurations"
}

locals {
  record_comment = "D:${var.deployment_configuration.id}"
}

module "api_records" {
  #for_each                   = var.customer_aws_lb_listener_rule_configurations
  source                     = "../../modules/api-endpoint-request"
  aws_access_key_id          = var.aws_access_key
  aws_secret_access_key      = var.aws_secret_key
  aws_region                 = var.aws_region
  api_endpoint_configuration = var.api_endpoint_configurations[var.route53_record_configuration.resource_references.api_endpoint_key]
  endpoint_url_append        = "/${var.route53_record_configuration.hosted_zone_id}/Records?Comment=${local.record_comment}"
  method                     = "put"
  payload = templatefile(
    "${path.module}/route53_records_payload.tftpl",
    {
      urlcount = 1
      urls     = [var.route53_record_configuration.name]
      record = {
        "type"                   = var.route53_record_configuration.type
        "zone_id"                = var.route53_record_configuration.zone_id == null ? "" : var.route53_record_configuration.zone_id
        "value"                  = var.route53_record_configuration.value == null ? "" : var.route53_record_configuration.value
        "ttl"                    = var.route53_record_configuration.ttl == null ? "" : var.route53_record_configuration.ttl
        "alias"                  = var.route53_record_configuration.alias == null ? "" : var.route53_record_configuration.alias
        "evaluate_target_health" = var.route53_record_configuration.evaluate_target_health == null ? false : var.route53_record_configuration.evaluate_target_health
      }
    }
  )
}
