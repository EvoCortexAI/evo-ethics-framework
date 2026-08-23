# Governance

## Source authority

The approved `docs/ETHICS-RULES.md` is the sole source for principle identifiers, names, and normative definitions.

The public repository (once published) should contain approved versions on `main` only. Draft changes should be prepared in a controlled workflow and published through reviewed pull requests after explicit approval.

## Change classes

### Normative change

Changes E1–E11, mandatory constraints, or the ethical decision framework.

Requirements:

- versioned amendment to `ETHICS-RULES.md`
- founder approval
- propagation review
- compatibility and migration assessment
- signed release

### Executable control change

Adds or changes an `EC-*` rule without redefining E1–E11.

Requirements:

- principle traceability
- positive, negative, and bypass tests
- residual-risk statement when the control cannot fully eliminate the privacy, memory, or inference exposure it addresses
- security review proportional to impact
- bundle version update
- rollback plan

Prefer controls that map to existing Saturn authority fingerprints, fail-closed PEPs, and deterministic conformance vectors. Do not introduce non-negotiable controls that cannot yet be proven without destroying product utility.

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

## Public enrollment

Before the repository is made public, the gates in `docs/PUBLIC-RELEASE-CHECKLIST.md` must be completed and founder + legal approval recorded. Public visibility does not itself grant reuse rights; see `LICENSING.md`.
