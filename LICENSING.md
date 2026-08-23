# Licensing and Public Source Enrollment

Public visibility and open-source licensing are separate decisions.

## Current state: public source, proprietary rights

Until a later licensing transition is explicitly approved and committed:

- `LICENSE` remains the governing license for EvoCortexAI-owned material.
- Public visibility is for transparency, inspection, and evaluation.
- The repository must not be described as open source.
- External contributions are not accepted.
- No public visibility change grants reuse, deployment, redistribution, or commercialization rights beyond the governing license and applicable hosting-platform terms.

## Proposed future dual-license model

The following model is technically recommended but remains **pending founder + legal approval**.

### Apache License 2.0 — implementation artifacts

The Apache-2.0 side should cover artifacts intended to be copied, integrated, tested, or used for interoperability, including:

- `Package.swift`
- `Sources/**`
- `Tests/**`
- `scripts/**`
- `.github/workflows/**`
- machine-readable JSON Schemas under `spec/**`
- OpenAPI documents under `spec/**`
- machine-readable conformance vectors under `conformance/**`
- machine-readable policy bundles and control catalogs under `policy/**`
- machine-readable examples and fixtures under `examples/**`

This classification treats JSON Schema, OpenAPI, conformance vectors, and policy bundles as **implementation/specification artifacts**, not as normative prose. The intent is to avoid imposing documentation-license attribution mechanics on implementers copying machine-readable interoperability material.

### Creative Commons Attribution 4.0 — normative and explanatory prose

CC-BY-4.0 should cover human-authored normative and explanatory documentation, including:

- `docs/ETHICS-RULES.md`
- other human-readable Markdown under `docs/**`
- `README.md`
- `GOVERNANCE.md`
- `PUBLISHING.md`
- `SECURITY.md`
- human-readable explanatory portions of conformance or specification documentation where a file-specific notice identifies CC-BY-4.0

If a file mixes code/machine-readable material with substantial prose, a file-level SPDX/license notice should resolve the boundary before the dual-license transition is activated.

## Trademark and non-endorsement boundary

Copyright licensing does **not** grant trademark rights.

The names `EvoCortexAI`, `EvoEthics`, `Saturn`, associated product names, logos, and service marks remain reserved to EvoCortexAI S.L. unless separately licensed.

A modified or forked version of the ethics framework may not be presented as:

- an EvoCortexAI-approved ethical framework;
- the canonical EvoCortexAI policy;
- certified, endorsed, or validated by EvoCortexAI; or
- an official Saturn/EvoCortexAI implementation,

unless EvoCortexAI S.L. has expressly authorized that representation.

This non-endorsement rule protects identity and provenance; it is not intended to prohibit derivative works that are otherwise permitted by the applicable copyright license.

## Contribution gate

Before external contributions are opened, EvoCortexAI must separately approve:

1. the final outbound license texts and per-file boundary;
2. third-party notices and SPDX/file-level markings;
3. an inbound contribution mechanism (for example DCO or CLA);
4. contributor governance and review requirements;
5. public-CI isolation from private/self-hosted infrastructure; and
6. trademark/non-endorsement language suitable for the public contribution workflow.

Until all six are complete, the repository may be publicly visible but remains **contributions closed**.

See `docs/PUBLIC-RELEASE-CHECKLIST.md` and `PUBLISHING.md`.
