"""Tests for root.hcl and common/*.hcl as resolved for each deployment."""

import re
from pathlib import Path

import pytest

from conftest import DEPLOYMENTS, MODULES_DIR, Deployment


def by_module(module_name: str) -> list[Deployment]:
    return [d for d in DEPLOYMENTS if d.module_name == module_name]


# --- Generic: every deployment -------------------------------------------


@pytest.mark.parametrize("deployment", DEPLOYMENTS, ids=str)
def test_source_points_at_matching_module(rendered, deployment):
    source = Path(rendered[deployment.path]["terraform"]["source"]).resolve()
    expected = (MODULES_DIR / deployment.tier / deployment.module_name).resolve()
    assert source == expected
    assert source.is_dir()


@pytest.mark.parametrize("deployment", DEPLOYMENTS, ids=str)
def test_remote_state(rendered, deployment):
    remote_state = rendered[deployment.path]["remote_state"]
    config = remote_state["config"]

    assert remote_state["backend"] == "s3"
    assert config["key"] == f"{deployment.tier}/{deployment.env}/{deployment.module_name}.tfstate"
    assert config["bucket"] == "terraform-skeleton-state"
    assert config["dynamodb_table"] == "terraform-skeleton-state-locks"
    assert config["accesslogging_bucket_name"] == "terraform-skeleton-state-logs"
    assert config["region"] == "us-east-1"
    assert config["encrypt"] is True
    assert re.fullmatch(
        r"arn:aws:iam::\d{12}:role/terraform/TerraformBackend",
        config["assume_role"]["role_arn"],
    )


def test_state_keys_are_unique(rendered):
    keys = [r["remote_state"]["config"]["key"] for r in rendered.values()]
    assert len(keys) == len(set(keys))


@pytest.mark.parametrize("deployment", DEPLOYMENTS, ids=str)
def test_standard_tags(rendered, deployment):
    tags = rendered[deployment.path]["inputs"]["tags"]
    assert tags["tf.deployment"] == deployment.path
    assert re.fullmatch(r"[\w.-]+/[\w.-]+", tags["tf.repo"])


@pytest.mark.parametrize("deployment", DEPLOYMENTS, ids=str)
def test_inherits_global_config(rendered, deployment):
    # deployments/config.yml sets `unused: true`; every deployment inherits it
    assert rendered[deployment.path]["inputs"]["unused"] is True


# --- test-stack: YAML hierarchy ------------------------------------------


@pytest.mark.parametrize("deployment", by_module("test-stack"), ids=str)
def test_yaml_hierarchy_merge(rendered, deployment):
    inputs = rendered[deployment.path]["inputs"]

    # deployments/app/config.yml overrides deployments/config.yml
    assert inputs["global_var"] == "overridden in deployments/app"
    assert inputs["tier_var"] == "set in deployments/app/"
    assert inputs["env_var"] == f"set in deployments/app/{deployment.env}"
    assert inputs["stack_var"] == f"set in deployments/app/{deployment.env}/test-stack/"
    # No config.yml sets layer_var, so the module default should apply
    assert "layer_var" not in inputs


# --- ssm-parameter -------------------------------------------------------


@pytest.mark.parametrize("deployment", by_module("ssm-parameter"), ids=str)
def test_ssm_parameter_inputs(rendered, deployment):
    inputs = rendered[deployment.path]["inputs"]
    assert inputs["parameter_name"] == f"/skeleton/{deployment.env}/example"
    assert inputs["parameter_value"] == f"hello from {deployment.env}"


@pytest.mark.parametrize("deployment", by_module("ssm-parameter"), ids=str)
def test_ssm_parameter_tags_merge_yaml_and_standard(rendered, deployment):
    tags = rendered[deployment.path]["inputs"]["tags"]
    assert tags["environment"] == deployment.env
    assert tags["managed_by"] == "terraform"
    assert tags["tf.deployment"] == deployment.path
    assert "tf.repo" in tags


def test_ssm_parameter_names_unique(rendered):
    names = [rendered[d.path]["inputs"]["parameter_name"] for d in by_module("ssm-parameter")]
    assert len(names) == len(set(names))
