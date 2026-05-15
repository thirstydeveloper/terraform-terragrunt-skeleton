locals {
  root_deployments_dir       = get_parent_terragrunt_dir()
  relative_deployment_path   = path_relative_to_include()
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
