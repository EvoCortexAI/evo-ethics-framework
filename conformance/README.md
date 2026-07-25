# Conformance Vectors

Every implementation of the EvoEthics v1 contract must produce the expected outcome and include every `required_control` for each vector.

An implementation may add controls only when they do not lower decision precedence or contradict a `forbidden_control` assertion.

Decision precedence is:

`deny` > `require_review` > `require_approval` > `allow_with_obligations` > `allow`

Conformance vectors never contain raw user content, secrets, real identifiers, or internal operational addresses.
