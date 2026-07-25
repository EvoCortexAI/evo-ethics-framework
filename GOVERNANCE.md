# Governance

## Source authority

The approved `docs/ETHICS-RULES.md` is the sole source for principle identifiers, names, and normative definitions.

The public repository should contain approved versions on `main` only. Draft changes should be prepared in a controlled private workflow and published through reviewed pull requests after explicit approval.

## Change classes

### Normative change

Changes E1-E10, mandatory constraints, or the ethical decision framework.

Requirements:

- versioned amendment to `ETHICS-RULES.md`
- founder approval
- propagation review
- compatibility and migration assessment
- signed release

### Executable control change

Adds or changes an `EC-*` rule without redefining E1-E10.

Requirements:

- principle traceability
- positive, negative, and bypass tests
- security review proportional to impact
- bundle version update
- rollback plan

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
