# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

* TerraformBackend IAM role, created by CloudFormation stack. Access restricted by IAM
  principal tag.
* Use of TerraformBackend IAM role by S3 remote state backend
* CloudFormation pre-commit hook (cfn-python-lint v0.44.1)

### Changed

* Excluded .cf.yml / .cf.yaml files from YAML pre-commit hook since it can't handle
  CloudFormation template interpolation

## [v2.0.0] - 2020-12-29

### Changed

* Changed state storage backend from local to S3

## [v1.1.0] - 2020-12-06

### Added

* Loading variable values from config.yml files

## [v1.0.0] - 2020-11-24

### Added

* .gitignore from [gitignore.io](https://www.toptal.com/developers/gitignore/api/terraform,terragrunt)
* Set [tfenv](https://github.com/tfutils/tfenv) .terraform-version to 0.13.5
* Set [tgenv](https://github.com/cunymatthieu/tgenv) .terragrunt-version to 0.26.4
* Add initial [pre-commit](https://pre-commit.com/) hooks
* Initial skeleton deployments
