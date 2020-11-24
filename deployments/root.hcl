locals {
  root_deployments_dir       = get_parent_terragrunt_dir()
  relative_deployment_path   = path_relative_to_include()
  deployment_path_components = compact(split("/", local.relative_deployment_path))

  tier  = local.deployment_path_components[0]
  stack = reverse(local.deployment_path_components)[0]
}

# Default the stack each deployment deploys based on its directory structure
# Can be overridden by redefining this block in a child terragrunt.hcl
terraform {
  source = "${local.root_deployments_dir}/../modules/stacks/${local.tier}/${local.stack}"
}
