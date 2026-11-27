locals {
  path_config = read_terragrunt_config("${get_repo_root()}/common/infer_config_from_path.hcl")
  yml_config  = read_terragrunt_config("${get_repo_root()}/common/read_yml_config.hcl")

  root_live_dir      = local.path_config.locals.root_live_dir
  relative_unit_path = local.path_config.locals.relative_unit_path
  tier               = local.path_config.locals.tier
  module_name        = local.path_config.locals.module_name
  merged_config      = local.yml_config.locals.merged_config

  repo_remote = trimspace(run_cmd("--terragrunt-quiet", "git", "remote", "get-url", "origin"))
  repo        = regex("[:/]([^/:]+/[^/:]+?)(?:\\.git)?$", local.repo_remote)[0]

  tags = merge(
    {
      "tf.repo" = local.repo
      "tf.unit" = local.relative_unit_path
    },
    lookup(local.merged_config, "tags", {}),
  )
}

# Pass the merged config to terraform as variable values using TF_VAR_
# environment variables
inputs = merge(local.merged_config, { tags = local.tags })

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket  = "terraform-skeleton-state"
    region  = "us-east-1"
    encrypt = true

    assume_role = {
      role_arn = "arn:aws:iam::${get_aws_account_id()}:role/terraform/TerraformBackend"
    }

    key = "${dirname(local.relative_unit_path)}/${local.module_name}.tfstate"

    # S3 native state locking via <key>.tflock objects
    use_lockfile = true
  }
}

# Default the module each unit deploys based on its directory structure
# Can be overridden by redefining this block in a child terragrunt.hcl
terraform {
  source = "${local.root_live_dir}/../modules/${local.tier}/${local.module_name}"
}
