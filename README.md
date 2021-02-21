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

* [tfenv](https://github.com/tfutils/tfenv) for managing terraform versions
* [tgenv](https://github.com/cunymatthieu/tgenv) for managing terragrunt versions
* [pre-commit](https://pre-commit.com/) for running syntax, semantic, and style checks on `git commit`

After installing those tools run `tfenv install` and `tgenv install` from the
clone of this repository to install the configured versions of terraform and
terragrunt. Then, run `pre-commit install` to install the pre-commit hooks.

## Initialization

1. Create an [AWS credentials profile](https://docs.aws.amazon.com/sdk-for-php/v3/developer-guide/guide_credentials_profiles.html)
named `tf-admin-account`
2. Run `make init-admin` to deploy a CloudFormation stack to that account containing
[the infrastructure terraform needs to run](https://thirstydeveloper.io/tf-skeleton/2021/02/17/part-5-cfn-terraform-state.html)

## Usage

Run `terragrunt` commands from directories under `deployments/` containing
`terragrunt.hcl` files.

terragrunt `*-all` commands can be run from the repository root, or the
`deployments/` and any directory underneath it. For instance:

* Run `terragrunt plan-all` from the repository root to generate terraform
  plans for all deployments.
* Run `terragrunt plan-all` from `deployments/app/dev` to generate plans for
  all `app/dev` deployments.

For additional guidance, see the companion blog series:

https://thirstydeveloper.io/series/tf-skeleton
