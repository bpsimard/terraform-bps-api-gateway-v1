variable "service_role" {

}
variable "environment_to_deploy" {

}
variable "deployment_id" {
  
}

resource "aws_iam_role" "service_role" {
  name = "${var.environment_to_deploy}-${var.deployment_id}-${var.service_role.name_append}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
          AWS = "${var.service_role.allowed_assume_users}"
        }
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

output "role" {
  value = aws_iam_role.service_role
}