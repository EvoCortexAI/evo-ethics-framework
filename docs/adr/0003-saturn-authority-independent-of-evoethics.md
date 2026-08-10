# ADR 0003: SaturnAuthority independent of EvoEthics

**Status:** Accepted
**Date:** 2026-08-10

## Context

`SaturnAuthority` (fingerprint, receipt, compute lease) and `EvoEthics` (evaluation request/decision, policy evaluator) shipped as two products in one package. The `EvoEthics` target previously listed a dependency on `SaturnAuthority` even though no EvoEthics source file imports it.

SUA §9 assigns ownership separately:

- EvoEthics owns evaluation semantics, policy version/digest, principle/control IDs, obligations.
- SaturnAuthority owns executable fingerprint, receipt envelope, compute-lease binding, seal metadata, expiry/replay, canonical serialization.

A false SPM edge invites accidental imports and blocks a future extract of `saturn-authority` into its own repository.

## Decision

1. Remove the `EvoEthics` → `SaturnAuthority` package dependency.
2. Keep both products in this repository until a dedicated `saturn-authority` package exists and is consumed by Control/Runner/Node.
3. Consumers must declare each product they need (e.g. Saturn-Control Application depends on both; Domain only on SaturnAuthority).

## Consequences

- Cleaner module graph; CI cannot hide a new import behind an accidental transitive link.
- Tests that only cover evaluation no longer pull authority types.
- Extracting SaturnAuthority later is a packaging change, not a code untangle.
