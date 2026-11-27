locals {
  root_live_dir = "${get_repo_root()}/live"

  # path_relative_to_include() won't work here because this file is read by read_terragrunt_config
  # path_relative_to_include will return a path relative to th efile that performs the read_terragrunt_config
  # which is the root.hcl, not the unit (terragrunt.hcl) that is being operated on.
  relative_unit_path   = trimprefix(get_original_terragrunt_dir(), "${local.root_live_dir}/")
  unit_path_components = compact(split("/", local.relative_unit_path))

  tier        = local.unit_path_components[0]
  module_name = reverse(local.unit_path_components)[0]

  # Every path between root_live_dir and the unit path
  possible_config_dirs = [
    for i in range(0, length(local.unit_path_components) + 1) :
    join("/", concat(
      [local.root_live_dir],
      slice(local.unit_path_components, 0, i)
    ))
  ]
}
