# Governance

## Source authority

The approved `docs/ETHICS-RULES.md` is the sole source for principle identifiers, names, and normative definitions.

`main` contains the currently approved normative source. Draft normative changes remain non-authoritative until their explicit approval transition is completed and merged.

## Change classes

### Normative change

Changes the currently approved ethical principles, mandatory constraints, or ethical decision framework.

Requirements:

- versioned amendment to `docs/ETHICS-RULES.md`
- founder approval
- propagation review
- compatibility and migration assessment
- signed release when promoted as an approved release

### Executable control change

Adds or changes an `EC-*` rule without redefining the approved normative source.

Requirements:

- principle traceability
- positive, negative, and bypass tests
- residual-risk statement when a control cannot fully eliminate the exposure it addresses
- security review proportional to impact
- bundle version update
- rollback plan

Prefer controls that map cleanly to authority fingerprints, fail-closed policy-enforcement points, and deterministic conformance vectors. Absence of a preferred implementation control does not authorize a violation of an applicable ethical constraint. Where a preferred control cannot yet be proven, the affected capability must be bounded, withheld, or protected by an alternative control sufficient to preserve the applicable constraint. Residual implementation risk must be explicit, attributable, reviewable, and approved.

### Schema or API change

Requirements:

- semantic-version analysis
- conformance-vector update
- compatibility tests
- migration notes

## Release rules

- no mutable `latest` policy without a digest-pinned equivalent
- signed tags for approved releases
- generated artifacts are rebuilt from source; they are not edited independently
- product repositories pin a version and digest
- emergency rollback never permits a version below the configured minimum accepted policy

## Exceptions

Exceptions must be explicit, time-bounded, attributable, auditable, and approved by an authorized human. There are no silent implementation exceptions.

## Public source enrollment

Public visibility and external contribution acceptance are separate governance states.

The repository may be publicly visible under the proprietary `LICENSE` for transparency, inspection, and evaluation while external contributions remain closed. Public visibility does not itself grant reuse rights or make the repository open source.

Before public visibility:

- untrusted pull requests must not execute on private/self-hosted infrastructure;
- public-facing status and licensing language must be accurate;
- content-hygiene and manifest checks must pass; and
- founder authorization for public source visibility must be recorded.

## External contributions

External contributions remain closed until `LICENSING.md` and `docs/PUBLIC-RELEASE-CHECKLIST.md` identify the contribution/open-source gates as complete and EvoCortexAI explicitly changes this policy.

Unsolicited pull requests do not acquire normative standing, approval, or an implied license merely by being submitted.
