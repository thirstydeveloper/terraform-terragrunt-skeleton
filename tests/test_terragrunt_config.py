"""Tests for root.hcl and common/*.hcl as resolved for each unit."""

import re
from pathlib import Path

import pytest

from conftest import MODULES_DIR, UNITS, Unit


def by_module(module_name: str) -> list[Unit]:
    return [d for d in UNITS if d.module_name == module_name]


# --- Generic: every unit -------------------------------------------------


@pytest.mark.parametrize("unit", UNITS, ids=str)
def test_source_points_at_matching_module(rendered, unit):
    source = Path(rendered[unit.path]["terraform"]["source"]).resolve()
    expected = (MODULES_DIR / unit.tier / unit.module_name).resolve()
    assert source == expected
    assert source.is_dir()


@pytest.mark.parametrize("unit", UNITS, ids=str)
def test_remote_state(rendered, unit):
    remote_state = rendered[unit.path]["remote_state"]
    config = remote_state["config"]

    assert remote_state["backend"] == "s3"
    assert config["key"] == f"{unit.tier}/{unit.env}/{unit.module_name}.tfstate"
    assert config["bucket"] == "terraform-skeleton-state"
    assert config["use_lockfile"] is True
    assert "dynamodb_table" not in config
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


@pytest.mark.parametrize("unit", UNITS, ids=str)
def test_standard_tags(rendered, unit):
    tags = rendered[unit.path]["inputs"]["tags"]
    assert tags["tf.unit"] == unit.path
    assert re.fullmatch(r"[\w.-]+/[\w.-]+", tags["tf.repo"])


@pytest.mark.parametrize("unit", UNITS, ids=str)
def test_inherits_global_config(rendered, unit):
    # live/config.yml sets `unused: true`; every unit inherits it
    assert rendered[unit.path]["inputs"]["unused"] is True


# --- test-stack: YAML hierarchy ------------------------------------------


@pytest.mark.parametrize("unit", by_module("test-stack"), ids=str)
def test_yaml_hierarchy_merge(rendered, unit):
    inputs = rendered[unit.path]["inputs"]

    # live/app/config.yml overrides live/config.yml
    assert inputs["global_var"] == "overridden in live/app"
    assert inputs["tier_var"] == "set in live/app/"
    assert inputs["env_var"] == f"set in live/app/{unit.env}"
    assert inputs["stack_var"] == f"set in live/app/{unit.env}/test-stack/"
    # No config.yml sets layer_var, so the module default should apply
    assert "layer_var" not in inputs


# --- ssm-parameter -------------------------------------------------------


@pytest.mark.parametrize("unit", by_module("ssm-parameter"), ids=str)
def test_ssm_parameter_inputs(rendered, unit):
    inputs = rendered[unit.path]["inputs"]
    assert inputs["parameter_name"] == f"/skeleton/{unit.env}/example"
    assert inputs["parameter_value"] == f"hello from {unit.env}"


@pytest.mark.parametrize("unit", by_module("ssm-parameter"), ids=str)
def test_ssm_parameter_tags_merge_yaml_and_standard(rendered, unit):
    tags = rendered[unit.path]["inputs"]["tags"]
    assert tags["environment"] == unit.env
    assert tags["managed_by"] == "terraform"
    assert tags["tf.unit"] == unit.path
    assert "tf.repo" in tags


def test_ssm_parameter_names_unique(rendered):
    names = [rendered[d.path]["inputs"]["parameter_name"] for d in by_module("ssm-parameter")]
    assert len(names) == len(set(names))
