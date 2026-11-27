"""Fixtures for testing the Terragrunt configuration layer.

Each unit under deployments/ is rendered once per session with
`terragrunt render --json`, and tests assert on the resolved config
(inputs, remote_state, terraform.source).

root.hcl calls get_aws_account_id(), so rendering needs working AWS
credentials (STS GetCallerIdentity only). Without them the tests are skipped.
"""

import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
DEPLOYMENTS_DIR = REPO_ROOT / "deployments"
MODULES_DIR = REPO_ROOT / "modules"


@dataclass(frozen=True)
class Unit:
    path: str  # relative to deployments/, e.g. "app/dev/test-stack"

    @property
    def tier(self) -> str:
        return self.path.split("/")[0]

    @property
    def env(self) -> str:
        return self.path.split("/")[1]

    @property
    def module_name(self) -> str:
        return self.path.split("/")[-1]

    def __str__(self) -> str:
        return self.path


def discover_units() -> list[Unit]:
    return sorted(
        (
            Unit(str(p.parent.relative_to(DEPLOYMENTS_DIR)))
            for p in DEPLOYMENTS_DIR.rglob("terragrunt.hcl")
            if ".terragrunt-cache" not in p.parts
        ),
        key=str,
    )


UNITS = discover_units()


class RenderError(Exception):
    pass


def _render(unit: Unit) -> dict:
    result = subprocess.run(
        ["terragrunt", "render", "--json", "--log-level", "error"],
        cwd=DEPLOYMENTS_DIR / unit.path,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RenderError(result.stderr)
    return json.loads(result.stdout)


@pytest.fixture(scope="session")
def rendered() -> dict[str, dict]:
    """Rendered config for every unit, keyed by unit path."""
    with ThreadPoolExecutor() as pool:
        futures = {d.path: pool.submit(_render, d) for d in UNITS}

    results, errors = {}, {}
    for path, future in futures.items():
        try:
            results[path] = future.result()
        except RenderError as e:
            errors[path] = str(e)

    if errors:
        if any("get_aws_account_id" in e for e in errors.values()):
            pytest.skip(
                "terragrunt render needs AWS credentials for get_aws_account_id()"
            )
        details = "\n".join(f"--- {p}\n{e}" for p, e in errors.items())
        pytest.fail(f"terragrunt render failed:\n{details}")

    return results
