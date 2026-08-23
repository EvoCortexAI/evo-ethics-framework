# EvoEthics Framework

**Status:** In development; not production-ready  
**Ethics source:** `docs/ETHICS-RULES.md` version **1.1** (approved 2026-08-21).  
A proposed 1.2 amendment (E11 Human Privacy) is under review and is **not** authoritative until approved and merged.

EvoEthics is the proposed deterministic ethics-policy subsystem of EvoIntelligenceFabric. It converts approved EvoCortexAI ethical constraints into inspectable decisions and obligations that Saturn components can enforce.

It is not a separate AI product, a moral-scoring model, or a mandatory remote cloud service.

## Purpose

The canonical ethical principles remain human-governed in `docs/ETHICS-RULES.md`. Product code needs a narrower machine contract for questions such as:

- May this agent deployment start?
- Does a lifecycle or tool action require exact approval?
- Is the requested compute scope bounded and interruptible?
- Is the image, model, network, data, and resource scope covered by policy?
- Must the operation be denied or escalated for human review?

EvoEthics answers from structured metadata. It must not receive raw prompts, document bodies, credentials, or generated content unless a future approved control proves that strictly necessary.

## Saturn architecture position

```mermaid
flowchart TD
    Policy[Approved ETHICS-RULES.md]
    Bundle[Signed policy bundle]
    PDP[EvoEthics deterministic PDP]
    Control[Saturn-Control]
    Approval[Exact human approval when required]
    Authority[Saturn authority / receipt contract]
    Runner[Container Runner PEP]
    Agent[Managed Agent Container]
    Node[Saturn-Node PEP]
    Mesh[saturn-mlx-mesh / MLX]

    Policy --> Bundle --> PDP
    Control -->|structured metadata| PDP
    PDP -->|allow / obligations / approval / review / deny| Control
    Control --> Approval
    Approval --> Control
    Control -->|bound authorization evidence| Authority
    Authority --> Runner
    Authority --> Node
    Runner --> Agent --> Node --> Mesh
```

EvoEthics supplies deterministic governance decisions and obligations. It does **not** itself replace Saturn authentication, authorization, approval capture, workload identity, cryptographic authority binding, sandboxing, or final-side-effect enforcement.

## PAP / PDP / PEP separation

```mermaid
flowchart LR
    PAP[Saturn-Control PAP]
    PDP[EvoEthics PDP]
    PEP1[Container Runner PEP]
    PEP2[Agent protected-tool PEP]
    PEP3[Saturn-Node PEP]

    PAP -->|approved policy bundle| PDP
    PDP -->|decision + obligations| PAP
    PAP -->|exact bound authority| PEP1
    PAP -->|exact bound authority| PEP2
    PAP -->|lease / applicable bound authority| PEP3

    PEP1 -->|verify immediately before side effect| SideEffect1[Apple Container mutation]
    PEP2 -->|verify immediately before side effect| SideEffect2[Protected tool action]
    PEP3 -->|verify immediately before side effect| SideEffect3[MLX generation]
```

Unknown, expired, mismatched, replayed, revoked, or policy-downgraded authority must fail closed at the final enforcement point.

## Ownership boundary

```mermaid
flowchart TB
    Ethics[EvoEthics]
    Authority[SaturnAuthority contract]
    Control[Saturn-Control]

    Ethics -->|owns policy evaluation request / decision semantics| Decision[Decision + obligations + policy version/digest]
    Authority -->|owns executable fingerprint / receipt / lease binding| Receipt[AuthorityReceipt / ComputeLease]
    Control -->|consumes both| Operation[Protected operation]

    Decision -. not execution authority by itself .-> Operation
    Receipt -->|final PEP-verifiable authority| Operation
```

EvoEthics owns policy-evaluation semantics, policy version/digest, principle/control IDs, controls, and obligations. The canonical Saturn authority package owns the executable fingerprint, receipt envelope, compute-lease binding, cryptographic seal metadata, expiry/replay semantics, and verifier compatibility.

## Naming

- Repository: `EvoCortexAI/evo-ethics-framework`
- Framework/subsystem: EvoEthics
- Swift module: `EvoEthics`
- Apple distributable, if needed later: `EvoEthics.xcframework`
- Optional local daemon: `evo-ethicsd`
- API namespace: `ai.evocortex.ethics.v1`

## Decision contract

An evaluation produces:

1. `allow`
2. `allow_with_obligations`
3. `require_approval`
4. `require_review`
5. `deny`

A decision includes policy version/digest, applicable ethical principle IDs, executable control IDs, required obligations, a stable audit identifier, and a concise metadata-only explanation.

Principles are normative. Controls are testable implementation rules derived from them.

## Saturn MVP integration

```mermaid
flowchart LR
    One[Saturn One]
    Container[Saturn Container]
    Control[Saturn-Control]
    Runner[Container Runner]
    Agent[Apple Container Agent]
    Node[Saturn-Node]
    Mesh[saturn-mlx-mesh / MLX]

    One --> Control
    Container --> Control
    Control --> Runner --> Agent --> Node --> Mesh
```

Proposed first action IDs:

```text
agent.deploy
agent.start
agent.stop
agent.restart
inference.generate.local
```

Proposed baseline obligations include `local_execution`, `metadata_audit`, `content_logging_disabled`, `interruptible`, `bounded_resources`, `workload_identity`, and `digest_pinned_image`.

Production enforcement remains blocked until the ethical source, action/control catalogs, signed policy-bundle and downgrade resistance, authority/receipt binding, security review, rollback behavior, and enforcement-point conformance are approved and proven.

## Repository contents

- `docs/ETHICS-RULES.md` — canonical ethical source (approved version on `main`)
- `docs/ARCHITECTURE.md` — policy architecture and trust boundaries
- `docs/INTEGRATION-MAP.md` — Saturn component enforcement points
- `docs/THREAT-MODEL.md` — threats and mitigations
- `docs/PUBLIC-RELEASE-CHECKLIST.md` — gates before public visibility
- `spec/v1/` — JSON Schemas and OpenAPI contract
- `policy/` — development policy bundle and control catalog
- `Sources/EvoEthics/` — dependency-free Swift reference SDK
- `Sources/evo-ethicsctl/` — local evaluation CLI
- `conformance/` — engine-neutral test vectors

## Development quick start

Requirements: Swift 6.3 / Xcode 26 / macOS 26 on the organization self-hosted runner (`saturn-ci-apple-01` labels: `self-hosted`, `macOS`, `ARM64`, `apple-ci`, `xcode-26-6`). Python 3.11+.

```sh
swift test
python3 scripts/validate_specs.py
swift run evo-ethicsctl evaluate examples/container-delete.request.json
```

The reference evaluator demonstrates the contract and conformance behavior. It is not approved for production enforcement.

## Integration policy

- Evaluate before a protected side effect.
- Reject unknown, expired, mismatched, replayed, revoked, or unverifiable authority.
- Bind approval to the exact actor, action, resource, image, model, execution target, limits, and expiry through the canonical Saturn authority contract.
- Re-evaluate when any material fact changes.
- Never treat evaluator failure as permission.
- Keep raw prompts, files, credentials, and model output out of policy requests and ordinary audit events.
- Do not use a frontend approval state as authoritative execution authority.
- Do not treat an `allow` decision as authentication, authorization, sandboxing, or proof of a beneficial result.

## Current repository license

The current private source repository is governed by the EvoCortexAI proprietary license in [`LICENSE`](LICENSE). That private-source license does not decide whether EvoEthics should later be released publicly or under an open-source license; any such release requires a separate explicit approval and release-readiness review. See `LICENSING.md` and `docs/PUBLIC-RELEASE-CHECKLIST.md`.

## Residual blockers for public enrollment

1. Founder + legal approval of the public licensing model (`LICENSING.md`).
2. Completion of the gates in `docs/PUBLIC-RELEASE-CHECKLIST.md`.
3. Decision on any open normative amendments (currently E11 / 1.2-proposed) before or concurrent with publication so public surfaces do not mix approved and proposed text.
4. Security review of request, decision, policy-bundle, receipt, workload-identity, and audit schemas.
5. Conformance coverage for the first Saturn enforcement points.

Until these are closed, the repository remains private and the status remains "In development; not production-ready".

## Non-goals

- Using an LLM to decide whether an action is ethical.
- Sending user content to a central ethics service.
- Replacing authentication, authorization, sandboxing, workload identity, or OS controls.
- Treating an `allow` decision as proof that an outcome is beneficial.
- Encoding human welfare as an opaque runtime score.
- Blocking basic local inference on an external network call.
- Letting an agent or frontend self-declare its risk class.

See `docs/ROADMAP.md` and Saturn-Control's `docs/SATURN-MVP.md`.
