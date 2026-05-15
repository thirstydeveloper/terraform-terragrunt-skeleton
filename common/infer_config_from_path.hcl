locals {
  root_deployments_dir = "${get_repo_root()}/deployments"

  # path_relative_to_include() won't work here because this file is read by read_terragrunt_config
  # path_relative_to_include will return a path relative to th efile that performs the read_terragrunt_config
  # which is the root.hcl, not the deployment (terragrunt.hcl) that is being operated on.
  relative_deployment_path   = trimprefix(get_original_terragrunt_dir(), "${local.root_deployments_dir}/")
  deployment_path_components = compact(split("/", local.relative_deployment_path))

  tier  = local.deployment_path_components[0]
  stack = reverse(local.deployment_path_components)[0]

  # Every path between root_deployments_dir and the deployment path
  possible_config_dirs = [
    for i in range(0, length(local.deployment_path_components) + 1) :
    join("/", concat(
      [local.root_deployments_dir],
      slice(local.deployment_path_components, 0, i)
    ))
  ]
}
