# Proposed Roadmap

## Gate 0 - Canonical decisions

- approve or amend `ETHICS-RULES.md` 1.1-proposed;
- confirm this repository as the canonical source or define a generated-mirror rule;
- approve public licensing;
- define governance owners and release-signing authority;
- approve the agent-container, workload-identity, and Saturn-Node action taxonomy.

**Exit:** Source, location, licensing, owners, and initial action boundaries are approved.

## v0.1 - Contract and conformance

- publish request, decision, policy-manifest, receipt, and audit schemas;
- publish the control catalog with ethical-principle traceability;
- publish the optional adapter OpenAPI contract;
- publish the dependency-free Swift reference SDK and CLI;
- validate conformance vectors in CI;
- complete the initial threat model.

**Status target:** In development; no production enforcement claim.

## v0.2 - Saturn-Control policy authority

- add policy administration and bundle verification;
- evaluate agent deploy/start/stop/restart and compute assignment;
- bind decisions to actor, workload, image digest, Runner, node, model, resources, and expiry;
- persist approval and decision receipts;
- implement atomic policy rollout and rollback.

**Exit:** Protected Saturn-Control operations carry verifiable, request-bound decisions.

## v0.3 - Container Runner enforcement

- verify receipt, operation, deployment fingerprint, image digest, resource scope, and expiry immediately before Apple Container side effects;
- deny shell strings, free-form arguments, mounts, privilege, devices, and host networking in the MVP;
- emit metadata-only result evidence;
- run bypass, replay, stale-receipt, and failure-mode tests.

**Exit:** A protected Apple Container side effect cannot bypass the Runner enforcement point.

## v0.4 - Agent workload and Saturn-Node enforcement

- establish one-time workload bootstrap;
- issue short-lived, revocable compute credentials;
- validate deployment, node, model, context/output limits, concurrency, budget, and expiry;
- require protected tool requests to return through Saturn-Control;
- reject direct frontend work and cross-workload credential use;
- add end-to-end correlation.

**Exit:** Protected tool or inference work is denied when identity, lease, receipt, or scope is absent, stale, revoked, or mismatched.

## v0.5 - Saturn One and Saturn Container UX

- present exact approval scope and execution target;
- show authoritative policy and operation state;
- disclose agent image, Runner, model, node, and execution location;
- support stop, revocation, and expiry;
- show audit history without exposing sensitive content;
- verify that neither frontend can mint or modify a decision.

**Exit:** Users can understand, approve, interrupt, and review protected actions.

## v1.0 - Production eligibility review

- external security review;
- signed policy-bundle release process;
- workload-identity and receipt cryptographic review;
- compatibility and migration policy;
- conformance across Saturn-Control, Container Runner, agent workload, Saturn-Node, and clients;
- rollback and revocation drills;
- privacy review of logs and audit retention;
- documented incident and exception process.

**Exit:** Founder-approved production status using the canonical status vocabulary.
