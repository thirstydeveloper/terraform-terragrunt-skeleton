locals {
  path_config = read_terragrunt_config("${get_repo_root()}/common/infer_config_from_path.hcl")

  # Expand each possible_config_dir to both .yml and .yaml candidates
  possible_config_paths = flatten([
    for dir in local.path_config.locals.possible_config_dirs : [
      "${dir}/config.yml",
      "${dir}/config.yaml"
    ]
  ])

  # Load every YAML config file that exists into an HCL map
  file_configs = [
    for path in local.possible_config_paths :
    yamldecode(file(path)) if fileexists(path)
  ]

  # Merge the maps together, with deeper configs overriding higher configs
  merged_config = merge(local.file_configs...)
}
