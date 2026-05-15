locals {
  path_config = read_terragrunt_config("${get_repo_root()}/common/infer_config_from_path.hcl")
  yml_config  = read_terragrunt_config("${get_repo_root()}/common/read_yml_config.hcl")

  root_deployments_dir     = local.path_config.locals.root_deployments_dir
  relative_deployment_path = local.path_config.locals.relative_deployment_path
  tier                     = local.path_config.locals.tier
  stack                    = local.path_config.locals.stack
  merged_config            = local.yml_config.locals.merged_config
}

# Pass the merged config to terraform as variable values using TF_VAR_
# environment variables
inputs = local.merged_config

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket   = "terraform-skeleton-state"
    region   = "us-east-1"
    encrypt  = true

    assume_role = {
      role_arn = "arn:aws:iam::${get_aws_account_id()}:role/terraform/TerraformBackend"
    }

    key = "${dirname(local.relative_deployment_path)}/${local.stack}.tfstate"

    dynamodb_table            = "terraform-skeleton-state-locks"
    accesslogging_bucket_name = "terraform-skeleton-state-logs"
  }
}

# Default the stack each deployment deploys based on its directory structure
# Can be overridden by redefining this block in a child terragrunt.hcl
terraform {
  source = "${local.root_deployments_dir}/../modules/stacks/${local.tier}/${local.stack}"
}
