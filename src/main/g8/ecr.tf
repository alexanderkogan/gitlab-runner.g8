module "build_image" {
  source              = "modules/ecr-repository"
  repository_name     = "build"
  repository_accounts = [data.aws_caller_identity.current.account_id]
}