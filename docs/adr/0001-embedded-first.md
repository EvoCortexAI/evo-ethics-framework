# ADR 0001: Embedded-first evaluation with optional local service

**Status:** Proposed

## Context

Saturn products require a shared policy contract, but local-first operation and graceful degradation prohibit a mandatory external decision service.

## Decision

Use a deterministic embedded evaluator as the primary integration. Provide an optional local service adapter for components that cannot embed the SDK.

## Consequences

- local operation does not depend on network reachability
- conformance tests must keep implementations semantically aligned
- policy bundles must be distributable and verifiable
- product enforcement points remain responsible for side-effect blocking
