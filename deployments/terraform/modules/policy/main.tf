variable "policy_key" {

}
variable "policy_value" {

}
variable "environment_to_deploy" {

}
variable "deployment_id" {
  
}

resource "aws_iam_policy" "policy" {
  name        = "${var.environment_to_deploy}-${var.deployment_id}-${var.policy_key}"
  path        = "/"
  description = var.policy_value.description

  policy = jsonencode(var.policy_value.policy)
}

output "policy" {
  value = aws_iam_policy.policy
}