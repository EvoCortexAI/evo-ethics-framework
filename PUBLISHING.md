# Publishing Plan

Target repository:

`EvoCortexAI/evo-ethics-framework`

Recommended description:

> Local-first, deterministic ethics-policy framework and conformance contract for EvoIntelligenceFabric and Saturn products.

Recommended topics:

- policy-as-code
- local-first
- swift
- governance
- auditability
- responsible-ai
- apple-silicon

## Phase A — public source visibility, contributions closed

Purpose: make the repository publicly inspectable without representing it as open source or accepting external changes.

Required repository state before the visibility flip:

1. `LICENSE` and `LICENSING.md` clearly state that the repository remains proprietary/source-available.
2. `.github/CONTRIBUTING.md` states that external contributions are not accepted.
3. The private/self-hosted CI workflow does **not** execute on public pull requests or forks.
4. `main` protection and review rules are configured before or immediately as part of the visibility change.
5. Secret scanning, push protection, private vulnerability reporting, and read-only default Actions permissions are enabled where available.
6. Content-hygiene and manifest checks are complete.
7. Founder authorization for Phase A is recorded.

Visibility action:

```sh
gh repo edit EvoCortexAI/evo-ethics-framework --visibility public
```

After the flip, verify that the repository displays the proprietary license/status correctly and that no workflow from an untrusted pull request can reach EvoCortexAI self-hosted infrastructure.

Do **not** describe Phase A as open source.

## Phase B — open-source and contribution enrollment

Phase B is a separate future decision. It requires:

- founder + legal approval of the final outbound licensing model;
- final Apache-2.0 / CC-BY-4.0 texts or an approved alternative;
- file-level/SPDX boundary for mixed or ambiguous artifacts;
- third-party notice verification;
- inbound contribution terms (DCO or CLA decision);
- public-safe CI for external contributions;
- contributor governance and review rules; and
- trademark/non-endorsement language.

Only after Phase B is approved should the repository be described as open source or external pull requests be invited.

## Public hygiene

Do not publish internal audit reports, operational addresses, secrets, current infrastructure inventory, unpublished product status, or incident records in this repository.
