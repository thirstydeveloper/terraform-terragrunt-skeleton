# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
