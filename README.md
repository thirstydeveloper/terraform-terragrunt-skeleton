# terraform-terragrunt-skeleton [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

This repository implements a skeleton repository for teams to use when first getting started with [terraform](https://www.terraform.io/). It uses [terragrunt](https://terragrunt.gruntwork.io/) as a workflow tool.

For a step-by-step guide for how this repo was built, the why behind it, and
how to use it, see this blog series:

https://thirstydeveloper.io/series/tf-skeleton

## Prerequisites

This project uses:

* [tfenv](https://github.com/tfutils/tfenv) for managing terraform versions
* [tgenv](https://github.com/cunymatthieu/tgenv) for managing terragrunt versions
* [pre-commit](https://pre-commit.com/) for running syntax, semantic, and style checks on `git commit`

After installing those tools run `tfenv install` and `tgenv install` from the
clone of this repository to install the configured versions of terraform and
terragrunt. Then, run `pre-commit install` to install the pre-commit hooks.

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
