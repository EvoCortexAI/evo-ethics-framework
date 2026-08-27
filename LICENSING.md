# Licensing and Public Source Enrollment

Public visibility and open-source licensing are separate decisions. External contribution enrollment remains a separate decision.

## Current state: Apache License 2.0 on current main

Current `main` first-party materials are offered under the Apache License, Version 2.0. See `LICENSE` and `NOTICE`.

- `LICENSE` is the unmodified official Apache License 2.0 text.
- First-party copyright and trademark/non-endorsement notices live in `NOTICE`.
- Changelog version `0.1.0` remains under the proprietary terms present when that section was recorded and must not be rewritten as Apache-2.0.
- The next published semantic release is the first Apache-2.0 release.
- Repository visibility and inbound contribution policy are unchanged by this license text.
- External contributions remain closed until the remaining enrollment gates below are complete.

## Optional follow-up: dual-license prose under CC-BY-4.0

A later, separately approved change may place human-authored normative and explanatory documentation under Creative Commons Attribution 4.0, including:

- `docs/ETHICS-RULES.md`
- other human-readable Markdown under `docs/**`
- `README.md`, `GOVERNANCE.md`, `PUBLISHING.md`, `SECURITY.md`

Until that follow-up is approved and committed, those files remain under Apache 2.0 with the rest of the first-party Work.

Machine-readable interoperability artifacts stay under Apache 2.0 in either model:

- `Package.swift`, `Sources/**`, `Tests/**`, `scripts/**`, `.github/workflows/**`
- JSON Schemas and OpenAPI under `spec/**`
- conformance vectors under `conformance/**`
- policy bundles and control catalogs under `policy/**`
- examples and fixtures under `examples/**`

## Trademark and non-endorsement boundary

Copyright licensing does **not** grant trademark rights.

The names `EvoCortexAI`, `EvoEthics`, `Saturn`, associated product names, logos, and service marks remain reserved to EvoCortexAI S.L. unless separately licensed.

A modified or forked version of the ethics framework may not be presented as:

- an EvoCortexAI-approved ethical framework;
- the canonical EvoCortexAI policy;
- certified, endorsed, or validated by EvoCortexAI; or
- an official Saturn/EvoCortexAI implementation,

unless EvoCortexAI S.L. has expressly authorized that representation.

## Contribution gate

Before external contributions are opened, EvoCortexAI must separately approve:

1. any optional CC-BY-4.0 prose split and per-file SPDX boundary;
2. third-party notices and file-level markings;
3. an inbound contribution mechanism (for example DCO or CLA);
4. contributor governance and review requirements;
5. public-CI isolation from private/self-hosted infrastructure; and
6. trademark/non-endorsement language suitable for the public contribution workflow.

Until those remaining gates are complete, the repository remains **contributions closed**.

See `docs/PUBLIC-RELEASE-CHECKLIST.md` and `PUBLISHING.md`.
