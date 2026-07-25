# EvoEthics Threat Model

**Status:** Initial public-safe threat model.

## Assets

- approved ethical source and policy bundle
- policy signing keys
- action registry and risk classifications
- user approval records
- decision receipts
- audit events
- product enforcement hooks

## Primary threats and controls

| Threat | Consequence | Required control |
|---|---|---|
| Enforcement bypass | Sensitive operation executes without evaluation | Place checks at the final side-effect boundary; test direct-call paths |
| Caller lowers its own risk | High-impact action receives permissive treatment | Risk and approval requirements come from signed action definitions |
| Policy downgrade | Old permissive bundle is reactivated | Monotonic version policy, minimum accepted version, signed manifests |
| Bundle tampering | Rules are altered in transit or at rest | Signature verification, digest pinning, atomic activation |
| Approval replay | One approval authorizes another action | Bind approval to request fingerprint, resource, expiry, and nonce |
| Time-of-check/time-of-use change | Evaluated facts differ at execution | Recheck material facts at enforcement; short-lived receipts |
| Fail-open error handling | Crash or timeout grants permission | Explicit fail-closed behavior and bounded evaluation |
| Audit suppression | No evidence of harmful or denied action | Enforcement emits event independently; monitor missing sequence/correlation |
| Audit privacy leak | Logs expose prompts, files, or credentials | Metadata-only schemas, redaction, field allowlists, retention controls |
| Central service outage | Local products cannot function | Embedded evaluator and last known-good signed bundle |
| Confused deputy | Trusted component performs action for an unauthorized caller | Bind actor, action, resource, and approval in the receipt |
| Policy semantic drift | Swift and service implementations disagree | Shared conformance vectors and compatibility tests |
| Malicious policy contribution | Backdoor introduced as policy change | Mandatory review, CODEOWNERS, signed releases, control-level tests |
| Unbounded policy input | Resource exhaustion | Strict schemas, input-size limits, bounded rule language |
| Model-generated policy | Opaque or unstable rules enter enforcement | Human-authored, reviewed policy only; no runtime LLM rule generation |

## Security invariants

- The evaluator never grants permission for an unknown action.
- Invalid or unverifiable policy bundles are never activated.
- The last known-good bundle is retained for rollback.
- Approval is evidence, not a UI boolean.
- Audit records contain identifiers and classifications, not raw sensitive content.
- Product sandbox and OS authorization remain authoritative enforcement layers.
- A decision receipt cannot authorize an operation with a different request fingerprint.

## Out of scope for v0.1

- public multi-tenant policy service
- user-authored arbitrary policy code
- remote policy evaluation over the open internet
- automated ethical scoring of people or content
- replacement of platform security controls
