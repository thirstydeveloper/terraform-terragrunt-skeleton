# terraform-terragrunt-skeleton [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

This repository implements a skeleton repository for teams to use when first
getting started with [terraform](https://www.terraform.io/). It uses
[terragrunt](https://terragrunt.gruntwork.io/) as a workflow tool.

For a step-by-step guide for how this repo was built, the why behind it, and
how to use it, see this blog series:

https://thirstydeveloper.io/series/tf-skeleton

## Prerequisites

You will need:

1. An AWS account for storing remote state in S3
1. An IAM user in that account with
    1. Administrative access
    1. An [IAM user tag](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_tags_users.html)
       of `Terraformer` set to `Admin`
1. Credentials for the above IAM user configured in the terminal used for running
   `terraform` and `terragrunt` commands

If you prefer to work from a very basic version of this skeleton that instead
uses the local filesystem backend, use branch
[release/1.1](https://github.com/thirstydeveloper/terraform-terragrunt-skeleton/tree/release/1.1).

This project uses:

* [tenv](https://github.com/tofuutils/tenv) for managing terraform and terragrunt versions
* [pre-commit](https://pre-commit.com/) for running syntax, semantic, and style checks on `git commit`

After installing those tools run `tenv tf install` and `tenv tg install` from
the clone of this repository to install the versions of terraform and terragrunt
pinned in `.terraform-version` and `.terragrunt-version`. Then, run
`pre-commit install` to install the pre-commit hooks.

## Initialization

1. Create an [AWS credentials profile](https://docs.aws.amazon.com/sdk-for-php/v3/developer-guide/guide_credentials_profiles.html)
named `tf-admin-account`
2. Run `make init-admin` to deploy a CloudFormation stack to that account containing
[the infrastructure terraform needs to run](https://thirstydeveloper.io/tf-skeleton/2021/02/17/part-5-cfn-terraform-state.html)

## Usage

Each directory under `deployments/` that contains a `terragrunt.hcl` file is a
terragrunt [unit](https://docs.terragrunt.com/features/units/). Run
`terragrunt` commands from a unit directory to operate on that unit.

Any directory above a set of units is an
[implicit stack](https://docs.terragrunt.com/features/stacks/). Use
[`terragrunt run --all`](https://docs.terragrunt.com/reference/cli/commands/run/)
from the repository root, `deployments/`, or any directory underneath it to
operate on every unit in that stack. For instance:

* Run `terragrunt run --all plan` from the repository root to generate terraform
  plans for all units.
* Run `terragrunt run --all plan` from `deployments/app/dev` to generate plans
  for all `app/dev` units.

## Testing

Run `make test` to run all tests, or run each layer on its own:

* `make test-modules` runs [`terraform test`](https://developer.hashicorp.com/terraform/language/tests)
  for every stack module under `modules/stacks/`. Test files live in each
  module's `tests/` directory. The AWS provider is mocked, so no credentials
  are needed.
* `make test-config` runs the pytest suite in `tests/`. It runs
  `terragrunt render --json` for every unit and checks the resolved
  inputs (YAML config merging), tags, remote state key, and module source.
  `root.hcl` calls `get_aws_account_id()`, so these tests need AWS
  credentials and are skipped without them.

For additional guidance, see the companion blog series:

https://thirstydeveloper.io/series/tf-skeleton
