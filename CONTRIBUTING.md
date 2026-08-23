# Contributing

This repository defines security-sensitive policy infrastructure.

Before proposing a change:

1. Identify whether it is normative, executable, schema/API, documentation, or implementation-only.
2. Cite the affected E1–E11 principles.
3. Add or update conformance vectors.
4. Describe failure behavior and rollback.
5. Confirm that examples contain no secrets, personal data, internal addresses, or proprietary operational details.
6. For any control touching observation, inference, retention, deletion, context sharing, or bystander data: state the residual risk that remains after the control and how it is disclosed or bounded.

Pull requests that introduce policy behavior must include:

- exact control IDs
- expected decision precedence
- allow, deny, approval, review, and malformed-input cases as applicable
- bypass analysis
- compatibility impact
- residual-risk statement when the control cannot fully eliminate the privacy or memory exposure it addresses

**Prioritization rule**  
Prefer controls that map to existing Saturn authority fingerprints, fail-closed PEPs, and deterministic conformance vectors. Do not introduce non-negotiable controls that cannot yet be proven without destroying product utility. Residual risk must be written and reviewable.

Do not generate production policy through an LLM and commit it without line-by-line human review.
