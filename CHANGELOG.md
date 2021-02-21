# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v1.5.0] - 2021-02-25

Companion blog post:

https://thirstydeveloper.io/tf-skeleton/2021/02/25/part-6-protecting-state.html

### Added

* Bucket policy restricting access to state bucket
* Encrypted log bucket
* Explicitly block public access to log bucket

### Removed

* Backend role's ability to create state bucket, log bucket, and lock table since
  those are now managed by CloudFormation

## [v1.4.0] - 2021-02-17

Companion blog post:

https://thirstydeveloper.io/tf-skeleton/2021/02/17/part-5-cfn-terraform-state.html

### Added

* Terraform operational infrastructure to CloudFormation (state bucket, log bucket, and lock table)
* Makefile targets for importing terragrunt-created operational infrastructure to CloudFormation

## [v1.3.0] - 2021-02-10

Companion blog post:

https://thirstydeveloper.io/tf-skeleton/2021/02/10/part-4-backend-role.html

### Added

* TerraformBackend IAM role, created by CloudFormation stack. Access restricted by IAM
  principal tag.
* Use of TerraformBackend IAM role by S3 remote state backend
* CloudFormation pre-commit hook (cfn-python-lint v0.44.5)
* Makefile for deploying CloudFormation stack and initializing all deployments

### Changed

* Excluded .cf.yml / .cf.yaml files from YAML pre-commit hook since it can't handle
  CloudFormation template interpolation

## [v1.2.0] - 2021-01-28

Companion blog post:

https://thirstydeveloper.io/tf-skeleton/2021/01/28/part-3-aws-backend.html

### Changed

* Changed state storage backend from local to S3

## [v1.1.0] - 2020-12-06

Companion blog post:

https://thirstydeveloper.io/tf-skeleton/2021/01/23/part-2-variables.html

### Added

* Loading variable values from config.yml files

## [v1.0.0] - 2020-11-24

Companion blog post:

https://thirstydeveloper.io/2021/01/17/part-1-organizing-terragrunt.html

### Added

* .gitignore from [gitignore.io](https://www.toptal.com/developers/gitignore/api/terraform,terragrunt)
* Set [tfenv](https://github.com/tfutils/tfenv) .terraform-version to 0.13.5
* Set [tgenv](https://github.com/cunymatthieu/tgenv) .terragrunt-version to 0.26.4
* Add initial [pre-commit](https://pre-commit.com/) hooks
* Initial skeleton deployments
