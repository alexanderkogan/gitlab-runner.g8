data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "registration_token" {
  type        = string
  description = "registration token for GitLab runner"
}
