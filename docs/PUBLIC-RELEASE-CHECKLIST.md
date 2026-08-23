# Public Release Checklist

**Status:** Preparation only. This document does not authorize publication.

Public visibility is irreversible for practical purposes. Treat every item as a hard gate.

## 1. Normative source

- [ ] `docs/ETHICS-RULES.md` on `main` is an **approved** version (currently 1.1). Proposed amendments (e.g. 1.2 E11) must either be approved and merged or clearly marked as non-authoritative in all public surfaces.
- [ ] Public website ethics page and any external summaries cite the exact approved version and do not present proposed text as current policy.
- [ ] Stable principle IDs (E1–E11 once approved) are frozen for reference drift control.

## 2. Licensing

- [ ] Founder + legal approval of the dual-license model proposed in `LICENSING.md` (Apache-2.0 for code, CC-BY-4.0 for normative docs/specs) or an alternative.
- [ ] Final license texts committed and `LICENSE` / `LICENSING.md` updated.
- [ ] Third-party license notices verified.
- [ ] No residual proprietary-only claims left in public-facing files after the switch.

## 3. Content hygiene

- [ ] No secrets, private keys, internal hostnames, customer data, operational inventory, unpublished product status, or incident records.
- [ ] Examples and fixtures contain only synthetic data.
- [ ] CI and workflow files do not expose private runner details or credentials beyond what is already public policy.
- [ ] `MANIFEST.sha256` and any digests are consistent with the published tree.

## 4. Security & governance

- [ ] Private vulnerability reporting enabled (or equivalent private channel documented in `SECURITY.md`).
- [ ] Branch protection on `main`: required reviews, no force-push, signed commits/tags preferred.
- [ ] Default GitHub Actions token permissions set to read-only where possible.
- [ ] Secret scanning + push protection enabled.
- [ ] `GOVERNANCE.md` and `CONTRIBUTING.md` accurately describe the change classes and residual-risk rules that will apply once public.

## 5. Technical readiness

- [ ] Schemas, control catalog, and conformance vectors pass CI on the publication commit.
- [ ] Reference evaluator and CLI build cleanly on the documented toolchain (Swift 6.3 / Xcode 26).
- [ ] No production-enforcement claim is made. Status remains "In development; not production-ready" until the roadmap gates are closed.

## 6. Communication

- [ ] Repository description and topics match `PUBLISHING.md`.
- [ ] README blockers list is reduced to only residual open items that survive publication.
- [ ] External links (website, decks) updated to the public URL only after the flip.

## Exit criteria

All boxes checked + explicit founder approval recorded. Then follow the `gh repo` visibility change and protection steps in `PUBLISHING.md`.
