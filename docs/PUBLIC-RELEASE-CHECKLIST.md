# Public Release Checklist

**Status:** Controlled release gate.

Public visibility and open-source/contribution enrollment are separate phases. Treat every unchecked item in the applicable phase as a hard stop.

## Phase A — public source visibility, contributions closed

### 1. Normative source

- [ ] `docs/ETHICS-RULES.md` on `main` is an approved version.
- [ ] Any proposed normative amendment is clearly marked non-authoritative everywhere it is referenced.
- [ ] Public website ethics copy and external summaries identify the exact approved version.

### 2. Proprietary public-source licensing

- [ ] `LICENSE` permits public inspection without claiming open-source status.
- [ ] `LICENSING.md` states that public visibility and open-source licensing are separate decisions.
- [ ] README clearly states that the repository remains proprietary and external contributions are closed.
- [ ] No public claim of Apache-2.0, CC-BY-4.0, or open-source status is made before Phase B approval.

### 3. Contribution lock

- [ ] `.github/CONTRIBUTING.md` states that external contributions are not accepted.
- [ ] Untrusted public pull requests cannot execute on EvoCortexAI self-hosted/private runners.
- [ ] `main` is protected against unauthorized direct mutation and force-push.
- [ ] Required internal review rules are enabled for canonical policy changes.

### 4. Content hygiene

- [ ] No secrets, private keys, internal hostnames, customer data, operational inventory, unpublished product status, or incident records.
- [ ] Examples and fixtures contain only synthetic data.
- [ ] Public documentation does not expose private runner hostnames or credentials.
- [ ] `MANIFEST.sha256` and any digests are consistent with the publication tree.

### 5. Security and technical readiness

- [ ] Default GitHub Actions token permissions are read-only where possible.
- [ ] Secret scanning + push protection are enabled where available.
- [ ] Private vulnerability reporting is enabled or `SECURITY.md` documents an equivalent private channel.
- [ ] Schemas, control catalog, examples, and conformance vectors pass CI on the publication commit.
- [ ] Reference evaluator and CLI build cleanly on the documented toolchain.
- [ ] No production-enforcement claim is made; status remains `In development; not production-ready`.

### 6. Publication authorization

- [x] Founder authorization for public source visibility recorded on 2026-08-23.
- [ ] Repository description and topics match `PUBLISHING.md`.
- [ ] Final visibility change to `public` performed.
- [ ] Post-flip verification confirms the license/status banner and runner isolation are correct.

## Phase A exit criteria

All Phase A boxes checked. The repository may then remain publicly visible under the proprietary license with external contributions closed.

---

## Phase B — open-source and external contribution enrollment

Phase B is not required for Phase A public visibility.

### 1. Outbound license approval

- [ ] Founder + legal approval of the final dual-license model or approved alternative.
- [ ] Final license texts committed.
- [ ] File-level/SPDX treatment resolves mixed-license files.
- [ ] Third-party notices verified.

### 2. Explicit artifact boundary

- [ ] Executable code, tests, scripts, CI, JSON Schema, OpenAPI, machine-readable conformance vectors, policy bundles/control catalogs, and machine-readable examples are assigned to Apache-2.0 or an approved alternative.
- [ ] Normative and explanatory prose is assigned to CC-BY-4.0 or an approved alternative.
- [ ] Trademark and non-endorsement language is approved and published.

### 3. Contribution governance

- [ ] DCO/CLA or other inbound licensing mechanism approved.
- [ ] Public-safe CI exists for untrusted external pull requests.
- [ ] Contributor review, maintainer, and moderation rules are published.
- [ ] `.github/CONTRIBUTING.md` is intentionally reopened and updated.

## Phase B exit criteria

All Phase B boxes checked + explicit founder/legal authorization. Only then may EvoCortexAI describe the repository as open source and invite external contributions.
