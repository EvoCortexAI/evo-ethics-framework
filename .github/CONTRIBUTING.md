# Contributing

This repository defines security-sensitive policy infrastructure.

Before proposing a change:

1. Identify whether it is normative, executable, schema/API, documentation, or implementation-only.
2. Cite the affected E1-E10 principles.
3. Add or update conformance vectors.
4. Describe failure behavior and rollback.
5. Confirm that examples contain no secrets, personal data, internal addresses, or proprietary operational details.

Pull requests that introduce policy behavior must include:

- exact control IDs
- expected decision precedence
- allow, deny, approval, review, and malformed-input cases as applicable
- bypass analysis
- compatibility impact

Do not generate production policy through an LLM and commit it without line-by-line human review.
