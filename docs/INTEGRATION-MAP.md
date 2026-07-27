# Saturn Integration Map

**Status:** Proposed enforcement boundaries for the current Saturn architecture

## EvoIntelligenceFabric

EvoEthics is EvoIntelligenceFabric's deterministic ethics-policy subsystem. EvoIntelligenceFabric carries shared identity, context, routing, policy, receipt, and audit semantics; EvoEthics supplies one bounded decision contract.

Every protected task envelope should carry:

- action ID;
- actor and component identity;
- workload/deployment identity when applicable;
- data classification metadata;
- execution target;
- image and model identity;
- resource and compute limits;
- requested side effects;
- policy decision or receipt;
- policy version and digest;
- exact approval reference when required.

## Saturn One

Role:

- user-facing agent, consent, and approval surface;
- execution disclosure;
- stop/revoke controls;
- user-facing audit history.

Integration:

- present policy obligations and exact approval scope;
- send intent to Saturn-Control;
- show authoritative decision and operation state returned by Saturn-Control;
- never mint, alter, or downgrade a decision receipt;
- never reduce denial to a dismissible warning;
- never receive agent workload or Saturn-Node credentials.

An embedded evaluator may support local preview or fail-fast UX, but Saturn-Control remains authoritative for managed actions.

## Saturn Container

Role:

- advanced remote agent-container configuration, deployment, lifecycle, monitoring, and logs UI.

Integration:

- collect exact deployment and lifecycle intent;
- present Runner, compute-node, model, resource, image, and approval scope;
- call Saturn-Control only;
- display policy denial, approval-required, receipt expiry, and operation state distinctly;
- never enforce through the deprecated local `ContainerCLI`;
- never connect directly to Container Runner, agent workloads, or Saturn-Node.

Saturn Container is a policy presentation point, not the authoritative policy decision or side-effect boundary.

## Saturn-Control

Role:

- policy administration and distribution;
- identity, authentication, and authorization;
- desired state and container orchestration;
- compute-node assignment and lease issuance;
- authoritative decision and approval validation;
- audit persistence and correlation.

Integration:

- evaluate before creating a protected operation;
- bind the decision to actor, workload, image digest, Runner, node, model, limits, tools, and expiry;
- persist the decision/approval reference with the operation;
- issue only short-lived workload-scoped compute credentials;
- re-evaluate material changes;
- deny unknown actions;
- distribute signed policy bundles to trusted enforcement points.

Saturn-Control does not pass raw policy internals or user content to downstream executors.

## Container Runner

Role:

- Saturn-Control-owned typed Apple Container adapter;
- local runtime reconciliation;
- immediate enforcement before container side effects.

Integration:

- accept only typed Saturn-Control operations;
- verify operation identity, receipt, deployment fingerprint, image digest, resources, and expiry;
- reject shell strings, free-form Apple Container arguments, host mounts, privilege, devices, and host networking in the MVP;
- emit metadata-only result evidence;
- remain inaccessible to frontends and workloads.

This is the authoritative enforcement point for Apple Container side effects.

## Agent container

Role:

- isolated agent loop;
- task state;
- explicitly approved tool adapters;
- consumer of assigned Saturn-Node inference.

Integration:

- establish workload identity through bounded bootstrap;
- accept only deployment-scoped configuration;
- present protected tool intent to Saturn-Control for approval;
- verify the returned receipt before a protected tool adapter runs;
- use only the assigned Saturn-Node and allowed model;
- stop on deployment termination, lease revocation, or incompatible policy;
- never self-declare risk or mint approval.

## Saturn-Node

Role:

- private MLX inference service;
- model capability reporting;
- workload authentication;
- inference limits, streaming, cancellation, and usage evidence.

Integration:

- validate the workload compute credential;
- verify deployment, node, model, context/output limits, concurrency, budget, expiry, and applicable decision receipt;
- reject frontend credentials and direct public work;
- run inference through `saturn-mlx-mesh`;
- emit metadata-only outcome evidence;
- never orchestrate Apple Container or run agent tools.

Saturn-Node is the enforcement point for inference compute, not container lifecycle.

## saturn-mlx-mesh

Role:

- in-process MLX inference library.

Integration:

- receive only a validated internal inference request;
- enforce library-level bounds and cancellation;
- emit metadata-only inference telemetry;
- remain independent of workload tokens, user authentication, container control, policy administration, and networking.

## Initial action classifications

| Action | Proposed treatment |
|---|---|
| `agent.list` | Read-only; allow with authorization and metadata audit |
| `agent.deploy` | Require reviewed image, bounded resources, workload identity, compute scope, and explicit approval when tools or sensitive data are enabled |
| `agent.start` | Allow only with valid deployment receipt and compatible Runner/compute state |
| `agent.stop` | User-authorized protective action; permit promptly with metadata audit |
| `agent.restart` | Require valid deployment scope and audit |
| `agent.delete` | Destructive; require exact approval and retention/rollback disclosure |
| `agent.tool.invoke` | Classify by tool and side effect; exact approval where required |
| `inference.generate.local` | Allow with local execution, bounded compute, content logging disabled, and interruptibility |

## Cross-component invariants

1. Unknown action IDs are denied.
2. A caller cannot self-declare a lower risk class.
3. Approval binds to the exact request fingerprint.
4. Changing actor, workload, image, model, target, data class, tool, side effect, resource, or expiry invalidates the previous decision.
5. Policy-engine failure never becomes permission.
6. Protected actions record policy version, digest, controls, receipt, and enforcement outcome.
7. Raw prompts, files, credentials, and model outputs are excluded by default.
8. Frontend approval state is not an authoritative receipt.
9. Container Runner and Saturn-Node verify their own bounded execution scope.
10. A stopped workload or revoked lease cannot initiate new compute.
