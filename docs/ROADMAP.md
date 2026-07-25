# Proposed Roadmap

## Gate 0 - Canonical decisions

- approve or amend `ETHICS-RULES.md` 1.1-proposed
- choose the canonical repository location
- canonize Saturn Container spelling and role
- approve public licensing
- define governance owners and release-signing authority

**Exit criterion:** approved source, location, naming, licensing, and owner decisions are recorded.

## v0.1 - Contract and conformance

- publish schemas for requests, decisions, policy manifests, and audit events
- publish control catalog with E1-E10 traceability
- publish OpenAPI adapter contract
- publish dependency-free Swift reference SDK and CLI
- validate conformance vectors in CI
- complete initial threat model

**Status target:** In development. No production enforcement claim.

## v0.2 - Saturn Container pilot

- integrate checks at the `ContainerCLI` command boundary
- cover start, stop, delete, exec, and image-pull actions
- bind approvals to command fingerprints
- emit metadata-only OSLog/audit events
- run bypass and failure-mode tests

**Exit criterion:** direct execution paths cannot bypass required decisions in the pilot scope.

## v0.3 - Saturn-Control integration

- add policy administration and bundle verification
- evaluate before dispatch to Saturn-Node
- persist approval and decision receipts
- expose private typed evaluation route where embedding is unavailable
- implement atomic policy rollout and rollback

**Exit criterion:** orchestration requests carry verifiable policy receipts.

## v0.4 - Saturn-Node enforcement

- verify receipts at execution boundary
- enforce execution target, model/provider, network, and resource obligations
- reject direct protected work without valid governance metadata
- add end-to-end trace correlation

**Exit criterion:** protected execution is denied when the receipt is absent, invalid, stale, or mismatched.

## v0.5 - Saturn One approval and transparency UX

- embed evaluator
- present exact approval scope and execution target
- show policy basis and audit history without exposing internal implementation noise
- support revocation and expiry

**Exit criterion:** users can understand, approve, interrupt, and review protected actions.

## v1.0 - Production eligibility review

- external security review
- signed bundle and release process
- compatibility and migration policy
- conformance across every supported implementation
- policy rollback drills
- privacy review of logs and audit retention
- documented incident and exception process

**Exit criterion:** founder-approved production status using the canonical status vocabulary.
