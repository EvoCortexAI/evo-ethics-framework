# ADR 0002: Separate ethical principles from executable controls

**Status:** Proposed

## Context

E1-E10 express normative commitments. Some are directly enforceable at runtime; others require design or governance judgment.

## Decision

Retain E1-E10 as stable normative identifiers. Give machine-enforceable rules independent `EC-*` control IDs with explicit traceability to one or more principles.

## Consequences

- runtime code does not pretend to compute abstract ethical value
- controls can evolve without renaming principles
- every decision can explain both its normative basis and executable rule
- design-review controls may return `require_review` instead of a synthetic score
