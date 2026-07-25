#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parents[1]
VECTOR_DIR = ROOT / "conformance" / "vectors"
DECISION_SCHEMA = json.loads(
    (ROOT / "spec" / "v1" / "evaluation-decision.schema.json").read_text(encoding="utf-8")
)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: run_conformance.py <path-to-evo-ethicsctl>", file=sys.stderr)
        return 2

    executable = Path(sys.argv[1]).resolve()
    if not executable.is_file():
        print(f"Executable not found: {executable}", file=sys.stderr)
        return 2

    validator = Draft202012Validator(DECISION_SCHEMA, format_checker=FormatChecker())
    vectors = sorted(VECTOR_DIR.glob("*.json"))
    failures: list[str] = []

    for vector_path in vectors:
        vector = json.loads(vector_path.read_text(encoding="utf-8"))
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", encoding="utf-8", delete=False
        ) as handle:
            json.dump(vector["request"], handle)
            request_path = Path(handle.name)

        try:
            completed = subprocess.run(
                [str(executable), "evaluate", str(request_path)],
                check=False,
                capture_output=True,
                text=True,
            )
        finally:
            request_path.unlink(missing_ok=True)

        if completed.returncode != 0:
            failures.append(
                f"{vector_path.name}: evaluator exited {completed.returncode}: "
                f"{completed.stderr.strip()}"
            )
            continue

        try:
            decision = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            failures.append(f"{vector_path.name}: invalid JSON output: {error}")
            continue

        schema_errors = sorted(
            validator.iter_errors(decision), key=lambda item: list(item.path)
        )
        if schema_errors:
            failures.extend(
                f"{vector_path.name}: decision schema at {list(error.path)}: {error.message}"
                for error in schema_errors
            )
            continue

        expected = vector["expected"]
        if decision["decision"] != expected["decision"]:
            failures.append(
                f"{vector_path.name}: expected {expected['decision']}, "
                f"got {decision['decision']}"
            )

        actual_controls = set(decision["controls"])
        missing = set(expected["required_controls"]) - actual_controls
        forbidden = set(expected.get("forbidden_controls", [])) & actual_controls
        if missing:
            failures.append(
                f"{vector_path.name}: missing controls {sorted(missing)}"
            )
        if forbidden:
            failures.append(
                f"{vector_path.name}: forbidden controls present {sorted(forbidden)}"
            )

    if failures:
        print("Conformance failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"Conformance passed: {len(vectors)} vectors.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
