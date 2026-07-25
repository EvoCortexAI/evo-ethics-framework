# Saturn Integration Map

**Status:** Proposed integration boundaries based on the currently visible repositories.

## EvoIntelligenceFabric

EvoEthics belongs inside EvoIntelligenceFabric as its ethics-policy subsystem. EvoIntelligenceFabric remains responsible for orchestration, routing, shared context, policy coordination, and auditability; EvoEthics supplies one bounded policy decision contract within that framework.

Every task envelope routed by EvoIntelligenceFabric should carry:

- action ID
- component and actor identity
- data classification metadata
- execution target
- requested side effects
- policy decision or decision receipt
- policy version and digest
- approval reference when required

## Saturn One

Role:

- user-facing control surface
- approval presentation and collection
- disclosure of local, private-node, or external execution
- user-facing audit history

Integration:

- embed the Swift `EvoEthics` package
- evaluate before dispatching sensitive requests
- display obligations as exact, understandable approval prompts
- bind approval to action, resource, execution target, provider, and expiry
- never reduce a denial to a dismissible warning

The currently visible repository README is a placeholder, so exact source-level insertion points require a separate code inspection.

## Saturn-Control

Role:

- policy administration and distribution
- orchestration-time decision enforcement
- approval-record validation
- audit persistence and correlation
- optional private evaluation endpoint for non-Swift clients

Integration with the existing Swift/Vapor architecture:

- add `EvoEthics` as a Swift package dependency
- define the policy-evaluation protocol in the domain/application boundary
- keep bundle storage and signature verification in infrastructure
- invoke evaluation in the application service before dispatching work to Saturn-Node
- expose a typed route through Interfaces only when a remote evaluator is required
- keep ethics routes under the native Saturn API namespace, not the OpenAI-compatible gateway

Saturn-Control should issue a short-lived decision receipt after evaluation. It should not pass raw policy internals or sensitive input content to downstream executors.

## Saturn-Node

Role:

- heavy execution and inference
- secondary enforcement before execution
- local audit evidence and result metadata

Integration:

- accept work only through the governed Saturn-Control path
- verify the decision receipt, action, request fingerprint, expiry, and obligations
- reject direct work that lacks a valid receipt for protected actions
- enforce execution-target, provider, network, data-access, and resource limits locally
- report completion, denial, and policy mismatch back to the audit stream

This is defense in depth: Saturn-Control makes the orchestration decision; Saturn-Node independently verifies that the dispatched operation matches it.

## Saturn Container

Role:

- native macOS control surface for Apple's `container` CLI
- local side-effect execution through `ContainerCLI`

Recommended enforcement point:

- place the policy check inside the `ContainerCLI` actor immediately before command execution
- keep the UI responsible for collecting exact approval
- pass a bound approval record into `ContainerCLI`
- log control IDs and policy metadata through the existing OSLog path without logging secrets or raw container content

Initial action classifications:

| Action | Initial treatment |
|---|---|
| `container.list` | Low risk; allow with audit metadata |
| `container.inspect` | Low risk; allow with audit metadata |
| `container.start` | Moderate local side effect; allow with audit |
| `container.stop` | Moderate local side effect; allow with audit |
| `container.delete` | High-impact/destructive; require explicit approval and review rollback expectations |
| `container.exec` | High impact; require bounded command, resource, network, and approval context |
| `container.image.pull` | External network/data ingress; require source, integrity, and audit obligations |

The exact product spelling must be canonized in the company document set before public framework documentation treats it as final.

## Cross-component invariants

1. Unknown action IDs are denied.
2. A caller cannot self-declare a lower risk class.
3. Approval must be bound to the exact request fingerprint.
4. Changing provider, execution target, data classification, side effects, or resource invalidates the previous decision.
5. A policy-engine error never becomes implicit permission.
6. Every protected action records policy version, digest, controls, and final enforcement outcome.
7. Raw prompts, files, credentials, and model outputs do not belong in the policy request or audit event by default.
