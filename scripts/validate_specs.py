#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "spec" / "v1"
VALID_PRINCIPLES = {f"E{number}" for number in range(1, 11)}
CONTROL_PATTERN = re.compile(r"^EC-[A-Z0-9]+-[0-9]{3}$")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate(instance: Any, schema_path: Path, label: str) -> None:
    schema = load_json(schema_path)
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors = sorted(validator.iter_errors(instance), key=lambda item: list(item.path))
    if errors:
        formatted = "\n".join(
            f"  - {label} at {list(error.path)}: {error.message}" for error in errors
        )
        raise ValueError(f"Schema validation failed:\n{formatted}")


def assert_unique(values: list[str], label: str) -> None:
    duplicates = sorted({value for value in values if values.count(value) > 1})
    if duplicates:
        raise ValueError(f"Duplicate {label}: {', '.join(duplicates)}")


def main() -> int:
    schema_files = sorted(SPEC.glob("*.schema.json"))
    for schema_path in schema_files:
        Draft202012Validator.check_schema(load_json(schema_path))

    request_schema = SPEC / "evaluation-request.schema.json"
    decision_schema = SPEC / "evaluation-decision.schema.json"
    policy_schema = SPEC / "policy-bundle.schema.json"
    vector_schema = SPEC / "conformance-vector.schema.json"
    catalog_schema = SPEC / "control-catalog.schema.json"

    policy_path = ROOT / "policy" / "development-policy.json"
    policy = load_json(policy_path)
    validate(policy, policy_schema, str(policy_path.relative_to(ROOT)))
    action_ids = [action["id"] for action in policy["actions"]]
    assert_unique(action_ids, "action IDs")

    bundled_policy = load_json(
        ROOT / "Sources" / "EvoEthics" / "Resources" / "development-policy.json"
    )
    if bundled_policy != policy:
        raise ValueError("The SDK development policy and policy/development-policy.json differ")

    catalog_path = ROOT / "policy" / "control-catalog.yaml"
    with catalog_path.open("r", encoding="utf-8") as handle:
        catalog = yaml.safe_load(handle)
    validate(catalog, catalog_schema, str(catalog_path.relative_to(ROOT)))
    control_ids = [control["id"] for control in catalog["controls"]]
    assert_unique(control_ids, "control IDs")
    for control in catalog["controls"]:
        if not CONTROL_PATTERN.fullmatch(control["id"]):
            raise ValueError(f"Invalid control ID: {control['id']}")
        unknown = set(control["principles"]) - VALID_PRINCIPLES
        if unknown:
            raise ValueError(f"{control['id']} references unknown principles: {sorted(unknown)}")

    example_requests = sorted((ROOT / "examples").glob("*.request.json"))
    for path in example_requests:
        validate(load_json(path), request_schema, str(path.relative_to(ROOT)))

    example_decisions = sorted((ROOT / "examples").glob("*.decision.json"))
    for path in example_decisions:
        validate(load_json(path), decision_schema, str(path.relative_to(ROOT)))

    vector_paths = sorted((ROOT / "conformance" / "vectors").glob("*.json"))
    for path in vector_paths:
        vector = load_json(path)
        validate(vector, vector_schema, str(path.relative_to(ROOT)))
        validate(vector["request"], request_schema, f"{path.relative_to(ROOT)} request")
        expected_controls = vector["expected"]["required_controls"]
        expected_controls += vector["expected"].get("forbidden_controls", [])
        unknown_controls = set(expected_controls) - set(control_ids)
        if unknown_controls:
            raise ValueError(
                f"{path.relative_to(ROOT)} references unknown controls: {sorted(unknown_controls)}"
            )

    openapi_path = SPEC / "openapi.yaml"
    with openapi_path.open("r", encoding="utf-8") as handle:
        openapi = yaml.safe_load(handle)
    if openapi.get("openapi") != "3.1.0":
        raise ValueError("OpenAPI document must declare 3.1.0")
    allowed_paths = {"/v1/evaluations", "/v1/policy/manifest", "/v1/health"}
    actual_paths = set(openapi.get("paths", {}))
    if actual_paths != allowed_paths:
        raise ValueError(f"Unexpected OpenAPI paths: {sorted(actual_paths ^ allowed_paths)}")
    if any(
        method.lower() in {"put", "patch", "delete"}
        for operations in openapi["paths"].values()
        for method in operations
    ):
        raise ValueError("The v1 evaluation API must not expose policy mutation")

    ethics_text = (ROOT / "docs" / "ETHICS-RULES.md").read_text(encoding="utf-8")
    headings = set(re.findall(r"^### (E(?:10|[1-9]))\.", ethics_text, flags=re.MULTILINE))
    if headings != VALID_PRINCIPLES:
        raise ValueError(
            f"ETHICS-RULES.md principle headings differ from E1-E10: {sorted(headings)}"
        )

    print(
        "Validation passed: "
        f"{len(schema_files)} schemas, "
        f"{len(action_ids)} actions, "
        f"{len(control_ids)} controls, "
        f"{len(example_requests)} request examples, "
        f"{len(example_decisions)} decision examples, "
        f"{len(vector_paths)} conformance vectors."
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"Validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
