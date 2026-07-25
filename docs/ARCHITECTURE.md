# EvoEthics Architecture

**Status:** Proposed v0.1 architecture.  
**Scope:** Product policy evaluation inside EvoIntelligenceFabric.

## 1. Design decision

EvoEthics should be a **versioned policy framework with an embedded decision engine and an optional local API adapter**. It should not begin as a mandatory central HTTP service.

This preserves:

- local-first operation
- deterministic behavior
- graceful operation when Saturn-Control or a network path is unavailable
- a single policy contract across Swift and non-Swift components
- auditable, reproducible decisions

## 2. Four-layer model

### 2.1 Normative source

`ETHICS-RULES.md` defines E1-E10, mandatory constraints, and governance. Humans approve changes here first.

The natural-language document is authoritative for meaning. It is not executed directly.

### 2.2 Machine policy bundle

The bundle contains:

- source ethics version
- bundle version and digest
- registered action definitions
- control catalog
- risk classifications
- required approvals and audit behavior
- compatibility metadata

Production bundles must be signed. Components must verify the signature and anti-downgrade metadata before activation.

### 2.3 Policy Decision Point

The embedded `EvoEthics` evaluator is the preferred Policy Decision Point (PDP). It consumes structured metadata and returns a decision with obligations.

Required properties:

- pure and deterministic for the same request and bundle
- no external network calls during evaluation
- no model inference
- no raw user content by default
- fail closed for unknown actions, malformed input, invalid bundles, and unsupported schema versions
- bounded execution time and input size

An optional `evo-ethicsd` process may expose the same contract over a Unix domain socket or private authenticated API for components that cannot embed the SDK.

### 2.4 Policy Enforcement Points

Each component remains responsible for enforcing the decision:

- block a denied operation
- gather exact approval when required
- satisfy obligations before execution
- bind the decision to the actual operation
- emit the audit event
- re-evaluate when material request facts change

The evaluator does not replace sandboxing, OS permissions, authentication, or authorization.

## 3. Decision pipeline

1. Component constructs a metadata-only request.
2. Schema and size limits are validated.
3. The action is resolved from the signed action registry.
4. Hard-deny controls are evaluated.
5. Approval and human-review controls are evaluated.
6. Obligations are accumulated.
7. The decision is bound to policy version, digest, request ID, and request fingerprint.
8. The enforcement point verifies and applies the decision.
9. An audit event records the policy basis and outcome.

Outcome precedence:

`deny` > `require_review` > `require_approval` > `allow_with_obligations` > `allow`

## 4. Runtime controls versus governance reviews

Not every ethical principle should be reduced to a runtime boolean.

### Runtime-enforceable examples

- E2: restricted data may not be sent to an external service
- E3: a registered high-impact action must have an audit path
- E4: sensitive side effects require exact approval
- E4/E7: agentic execution must have bounded scope and interruptibility

### Design- or release-review examples

- E8: foreseeable misuse and maintenance obligations
- E9: whether a capability supports human welfare rather than engagement extraction
- E10: whether core operation creates avoidable single-provider capture

Design-review controls return `require_review`; they do not invent a synthetic ethics score.

## 5. Trust boundaries

### Trusted

- approved policy signing keys
- validated policy bundle
- embedded evaluator binary
- action registry maintained by product owners
- approval service that binds approval to a request fingerprint

### Untrusted or partially trusted

- caller-supplied risk labels
- agent-generated explanations
- external model output
- user-interface state without a signed or transactional approval record
- policy bundles received without successful verification
- audit records containing raw content

Risk and required approval should come from the signed action definition, not from a caller asking to classify itself as low risk.

## 6. Policy distribution

Saturn-Control is the natural Policy Administration Point (PAP) for managed installations, but it must not become a single point of failure for every local decision.

Recommended flow:

1. Approved source change creates a release candidate bundle.
2. CI validates schemas, controls, conformance vectors, and compatibility.
3. Founder or authorized governance owner approves the release.
4. Release bundle is signed.
5. Saturn-Control distributes it to enrolled components.
6. Components verify, stage, and atomically activate it.
7. Components retain the last known-good bundle for rollback.
8. Audit events record bundle version and digest.

## 7. Optional service API

The service adapter should expose only evaluation and read-only policy metadata in v1:

- `POST /v1/evaluations`
- `GET /v1/policy/manifest`
- `GET /v1/health`

Policy mutation must not be exposed through the evaluation API. Administration and signing are separate privileged workflows.

Within Saturn-Control, the typed native route should be mapped under `/api/v1/ethics/evaluations`, not the OpenAI-compatible `/v1` gateway.

## 8. Decision receipts

A production decision receipt should eventually contain:

- request fingerprint
- action ID and resource fingerprint
- outcome and obligations
- policy version and digest
- evaluator identity
- approval reference, when applicable
- issued-at and expiry
- nonce or replay protection
- signature or MAC appropriate to the deployment boundary

A receipt is valid only for the exact operation it authorizes. Material changes require re-evaluation.

## 9. Engine strategy

The v1 API and conformance suite should remain engine-neutral.

Potential implementations may use a constrained native evaluator, Cedar, or OPA behind an adapter. The first public release should not expose Rego, Cedar, or another policy language as part of the stable product API until real product actions and governance workflows demonstrate that it is needed.

The reference Swift evaluator is deliberately constrained and dependency-free. It exists to validate the contract, not to declare the final policy-engine choice.
