# EvoCortexAI Ethical Rules

**Status:** Proposed amendment pending founder approval.  
**Applies to:** All products, infrastructure components, code, internal tooling, communications, partnerships, and decision-making processes.  
**Version:** 1.2-proposed - 2026-08-23  
**Supersedes:** Version 1.1 - 2026-08-21 (approved)

---

## Purpose

These rules establish the non-negotiable ethical boundaries for EvoCortexAI systems. They exist to ensure that artificial intelligence remains a **tool under meaningful human control**, never a system that exerts control over humans or erodes human agency.

This document is the **sole canonical source** for EvoCortexAI ethical principle identifiers, titles, definitions, mandatory constraints, and the ethical decision framework.

---

## Scope

This document applies to:

- **Saturn One** (client interface and Private AI Workspace)
- **EvoIntelligenceFabric** (policy enforcement, orchestration, routing, shared context, and auditability)
- **Saturn-Control** (private control plane)
- **Saturn-Node** (private execution nodes)
- All future products, agents, and vertical applications
- Internal development practices and tooling
- Public communications, investor materials, marketing, and partnerships
- AI-assisted analysis, implementation, and content generation

---

## Canonical Authority: One Ethics Framework, One Source

The following source-control rules are mandatory:

1. The approved version of `ETHICS-RULES.md` is the only authoritative ethical framework for EvoCortexAI.
2. Principle identifiers, titles, and normative definitions originate here. Other documents may provide a clearly labeled, faithful summary, but may not create, rename, reorder, or redefine principles.
3. Public pages, decks, prompts, and policy documents must cite or faithfully paraphrase this document. They must not present an alternative principle set.
4. A proposed ethical change must be made here first as a versioned amendment, reviewed, and approved before it is propagated elsewhere.
5. Derived summaries must identify the source version. When a summary conflicts with this document, this document governs.
6. A proposed revision is not authoritative until approved. Until approval, the last approved version remains in force.

The stable identifiers `E1` through `E11` are intended to prevent reference drift if presentation order changes in a future approved amendment.

---

## Core Ethical Principles

These principles are mandatory. No component, feature, communication, or decision may violate them.

### E1. Human Sovereignty

AI exists to assist people, not to replace human judgment or become the principal decision-maker. The user must remain in control of final decisions that affect their life, work, rights, property, or obligations.

### E2. Privacy by Design and Local-First Execution

User data and sensitive workflows must remain under the user's control by default. Local-first execution and user-owned or user-controlled infrastructure are the preferred paths. External compute is optional and secondary.

**Privacy is not a premium feature.** Core privacy protections must not depend on an upsell, hidden configuration, or surrender of control.

### E3. Transparency and Auditability

**Transparency takes precedence over magic.** Significant system behavior must not be intentionally obscured behind anthropomorphic, mystical, or unverifiable claims.

The user must be able to determine:

- Which model or component was used
- Where the task was executed (device, private node, or external service)
- What data was accessed or transformed
- What policy or approval authorized the action
- What decision, action, or output was produced

There must be a visible, inspectable audit trail for every significant action.

### E4. Explicit Approval and Bounded Agency

Agentic or autonomous behavior is permitted only within clearly defined, narrow boundaries. Sensitive actions require explicit, informed user approval. Agentic behavior must remain:

- Visible
- Interruptible
- Reversible where technically feasible
- Limited by explicit scope, time, resources, and permissions

### E5. Non-Manipulation and Respect for Human Attention

The system must not exploit attention, emotion, cognitive bias, or psychological vulnerability to increase engagement, dependency, compliance, or data extraction. It must remain useful, calm, and respectful.

### E6. Accountability and Explainability

Failures, errors, and harmful outcomes must be explainable and traceable to specific decisions, models, data, policies, approvals, or system components. The organization does not hide behind "the AI did it."

### E7. Bounded Power and Proportionate Responsibility

We deliberately limit the scope and capability of our systems. We are not building general-purpose autonomous agents or systems that seek to maximize their own influence, persistence, or resources.

**Capability must scale with responsibility.** As capability, agency, impact, or access to sensitive data increases, constraints, approvals, observability, verification, testing, rollback, and human review must strengthen proportionately.

### E8. Long-Term Responsibility

Intelligent systems must be guided, constrained, and evaluated before they are scaled. Ethical constraints must remain inspectable, debatable, enforceable, and improvable by humans over time. Long-term consequences, maintenance obligations, and foreseeable misuse must be considered before deployment.

### E9. Human Flourishing

EvoCortexAI systems should expand human capability, dignity, autonomy, learning, and the ability to pursue legitimate goals. System growth, organizational convenience, or engagement metrics must not be optimized at the expense of human welfare.

### E10. No Monopoly on Intelligence

Core intelligence infrastructure should not require a user or organization to surrender meaningful control to a single model provider, cloud, or platform. EvoCortexAI must preserve meaningful choice, portability, and user-governed execution paths wherever technically feasible.

This principle does not prohibit specialized external services. It prohibits designing core control around unavoidable dependency, exclusive capture, or a provider's unilateral authority over the user's data, execution, or governance.

### E11. Human Privacy

Human privacy is the right of a person to maintain meaningful boundaries around their inner life, relationships, behavior, environment, communications, and information.

AI systems must not treat technical access, observation, inference, or prior consent as unlimited permission to know, retain, correlate, or reuse information about a human.

Privacy protection applies not only to information explicitly supplied by a person, but also to information observed, inferred, derived, predicted, correlated, or reconstructed about them.

EvoCortexAI systems must follow these principles:

* **Necessary knowledge only.** A system should access only the information reasonably necessary for the human's chosen purpose.
* **Observation does not imply retention.** Information legitimately observed for an operation must not automatically become persistent memory.
* **Retention does not imply reuse.** Information retained for one legitimate purpose must not silently become context for another.
* **Inference does not create entitlement.** Deriving sensitive information about a person does not grant the system authority to retain, expose, act upon, or propagate that inference.
* **Local execution is not sufficient by itself.** A system may violate human privacy even when all computation occurs locally if it observes, correlates, remembers, or profiles people beyond legitimate necessity.
* **Privacy must extend to the intelligence itself.** AI components must not receive private context merely because another component within the same trusted environment can technically access it.
* **Context must remain compartmentalized.** Access by one application, agent, workflow, model, or task does not automatically authorize access by another.
* **Ephemeral interaction must remain possible.** Humans must be able to interact with intelligent systems without every interaction becoming durable memory.
* **Sensitive memory requires deliberate promotion.** Movement from transient context into durable user memory must be explicit, understandable, and reversible wherever technically feasible.
* **Purpose must remain bound.** Permission granted for one purpose must not silently authorize unrelated processing.
* **Bystanders retain privacy.** Data concerning people other than the primary user must not be treated as freely usable merely because it entered the user's environment or data.
* **Auditability must not become surveillance.** Systems should record the authority, action, resource class, policy basis, and outcome necessary for accountability without unnecessarily recording private human content.
* **Deletion must have defined semantics.** When a system represents that information has been forgotten or deleted, that statement must correspond to defined, testable behavior across active memory, derived representations, indexes, caches, and controlled persistence layers under EvoCortexAI control. Residual risk in external or third-party layers must be disclosed.
* **Consent cannot legitimize unnecessary intrusion.** User approval must not be used to justify collection, observation, retention, profiling, or external disclosure that is unnecessary for the requested purpose.
* **Privacy must be architectural, not merely contractual.** Where reasonably achievable, EvoCortexAI systems should be designed so that EvoCortexAI, infrastructure operators, model providers, and unrelated components cannot access information they do not need.

**Human Privacy Invariant**  
An intelligent system should know no more about a human than is necessary to serve the human's chosen purpose, remember no longer than necessary, never transform observation into authority, and preserve meaningful human control over what remains private — including privacy from the intelligence serving them.

---

## Mandatory Constraints

The following rules are non-negotiable across all components:

- **No hidden data exfiltration.** Data leaves user-controlled boundaries only with explicit, informed consent for a clearly stated purpose.
- **No dark patterns.** Interfaces and behavior must not manipulate users into actions they would not otherwise take.
- **No uninspectable agents.** Autonomous or semi-autonomous behavior must have clear logs, limits, approvals, and override mechanisms.
- **No training on user data without consent.** User data is never used to train internal or external models without explicit, revocable consent.
- **External models are secondary.** Frontier models may be used for specific high-value tasks, but are never the default or primary path for core functionality.
- **Responsibility increases with capability.** Higher-impact capabilities require stronger controls, testing, monitoring, and review.
- **No unavoidable single-provider control of core functions.** Core workflows must retain a user-governed path, graceful degradation, or a documented portability strategy wherever technically feasible.
- **Ethical review for material capability changes.** Any feature that increases agency, processes sensitive data, affects human decision-making, or increases external dependency must be reviewed against E1–E11 before implementation.
- **No parallel ethical frameworks.** Ethics-related copy must trace to this document and its approved version.
- **No silent exceptions.** Any unresolved conflict with these rules must be escalated for explicit human review; it may not be hidden in implementation detail or marketing language.

**E11-derived constraints (non-negotiable):**

- No ambient surveillance by default.
- No automatic cross-context aggregation of private information.
- No persistent memory merely because information was available to a model context.
- No silent promotion of transient information into durable memory.
- No unrestricted reuse of data collected for another purpose.
- No sensitive profiling solely because it can be inferred technically.
- No treatment of inferred sensitive characteristics as less protected than equivalent explicitly supplied information.
- No automatic exposure of one agent's private context to another agent.
- No raw-content audit logging unless specifically necessary and explicitly justified.
- No misleading claims that information was forgotten, deleted, private, or local when system behavior does not substantiate those claims.
- No consent flow designed to make privacy-invasive processing the path of least resistance.

---

## Decision Framework

When facing ethical tradeoffs or ambiguity, evaluate the proposal against all eleven principles:

1. **E1 — Human Sovereignty:** Does this preserve meaningful human control and final decision authority?
2. **E2 — Privacy by Design and Local-First:** Does this keep sensitive data and workflows under user control by default?
3. **E3 — Transparency:** Is the behavior visible, understandable, and auditable?
4. **E4 — Approval and Bounded Agency:** Are permissions explicit and is agency narrow, interruptible, and reversible where possible?
5. **E5 — Non-Manipulation:** Does this avoid exploiting attention, emotion, or cognitive bias?
6. **E6 — Accountability:** Can errors, decisions, and outcomes be explained and traced?
7. **E7 — Bounded Power:** Are controls proportionate to capability, impact, and access?
8. **E8 — Long-Term Responsibility:** Have maintenance, foreseeable misuse, and long-term effects been considered?
9. **E9 — Human Flourishing:** Does the proposal serve human capability, dignity, autonomy, or welfare rather than system growth alone?
10. **E10 — No Monopoly on Intelligence:** Does the design preserve meaningful choice and avoid unnecessary exclusive dependency?
11. **E11 — Human Privacy:** Does the proposal limit observation, inference, context access, retention, correlation, reuse, and disclosure to what is genuinely necessary for the human's chosen purpose?

A "no" to any question identifies an ethical conflict that must be resolved. A "no" to E1, E2, E3, or E11 requires immediate rejection or redesign. No principle may be silently traded away for convenience, speed, revenue, or capability.

A system must not justify an E11 conflict solely by demonstrating:

- user acceptance of terms;
- technical authorization;
- local execution;
- encryption;
- absence of external transmission;
- legitimate access to the underlying raw data; or
- usefulness of the additional information.

These properties may strengthen privacy, but none independently establishes that an intrusion is ethically justified.

---

## Relationship to Existing Principles

E11 complements rather than replaces existing principles:

- **E1 — Human Sovereignty:** the human determines the legitimate boundaries of AI participation.
- **E2 — Privacy by Design and Local-First Execution:** establishes control of data and execution boundaries; E11 extends this to observation, inference, memory, and contextual knowledge.
- **E3 — Transparency and Auditability:** humans must be able to understand what information was accessed, inferred, retained, or disclosed.
- **E4 — Explicit Approval and Bounded Agency:** access to private information is part of the agent's bounded authority.
- **E5 — Non-Manipulation:** consent must not be manufactured through coercive or manipulative interaction design.
- **E6 — Accountability and Explainability:** privacy-sensitive actions and failures must remain traceable.
- **E7 — Bounded Power:** greater observational and inferential capability requires proportionately stronger privacy controls.
- **E8 — Long-Term Responsibility:** accumulated memory and inferred profiles create long-term obligations.
- **E9 — Human Flourishing:** private mental and social space is necessary for autonomy, dignity, experimentation, and human development.
- **E10 — No Monopoly on Intelligence:** privacy should not require surrendering personal context to a centralized provider.

---

## Proposed Runtime and Architectural Controls

Future EvoEthics controls derived from E11 should include, where applicable and prioritized by enforceability and residual risk:

- context-access minimization;
- purpose binding;
- context compartmentalization;
- ephemeral-session designation;
- explicit durable-memory promotion;
- retention limits;
- sensitive-inference classification;
- cross-agent disclosure restrictions;
- bystander-data protection;
- derived-data deletion propagation (with defined residual-risk disclosure);
- metadata-only auditing;
- external-context disclosure controls;
- user-visible memory inspection and deletion;
- policy re-evaluation when context scope materially expands.

These controls must remain deterministic, inspectable, and enforceable. An LLM must not decide for itself whether its desire for additional context constitutes sufficient justification for accessing that context.

**Prioritization rule:** Implement first the controls that map cleanly to existing Saturn authority fingerprints, fail-closed PEPs, and deterministic conformance vectors. Defer or accept residual risk on controls that cannot yet be proven without destroying product utility. Residual risk must be written and reviewable.

---

## Governance and Change Control

- Any change to principle identifiers, titles, definitions, constraints, or decision rules requires a versioned amendment to this document.
- Proposed changes require explicit review and approval by the founder and, when established, the ethics or product council.
- The release sequence is: amend this document, review, approve, propagate faithful summaries, run the drift check, and publish.
- Violations and near-misses must be logged, reviewed, and used to improve controls.
- All team members, contributors, partners, and AI collaborators are expected to understand and uphold the approved version.
- Public ethics pages must be generated from or reviewed directly against the approved version of this document.

---

## Related Documents

- `MISSION.md` - Highest-level purpose and non-goals.
- `north-star.md` - Positioning, platform thesis, and values; not an alternative ethical source.
- `ARCHITECTURAL-LAW.md` - Technical constraints that operationalize these principles.
- `LANGUAGE-DISCIPLINE.md` - Rules for faithful public and internal communication.
- `AI-COLLABORATION-POLICY.md` - Enforcement rules for AI systems and agents.
- `CONTEXT-FOR-AI.md` - Derived AI context that must identify this document as the ethical authority.
- `ALIGNMENT-IMPROVEMENTS.md` - Audit-derived remediation controls.

---

## Revision History

| Version | Date | Status | Summary |
|---|---|---|---|
| 1.2-proposed | 2026-08-23 | Proposed | Adds E11 Human Privacy, extending privacy protection beyond data location and confidentiality to observation, inference, memory, purpose limitation, contextual compartmentalization, bystander privacy, defined deletion semantics, and privacy from the AI system itself. Keeps E2 focused on architectural/data control. |
| 1.1 | 2026-08-21 | Approved | Founder approval of the 1.1 revision. Establishes one-source governance, stable principle IDs E1–E10, privacy-not-premium, transparency-over-magic, capability-scales-with-responsibility, E9 Human Flourishing, and E10 No Monopoly on Intelligence. |
| 1.1-proposed | July 2026 | Superseded | Proposed revision pending founder approval. |
| 1.0 | July 2026 | Superseded | Initial eight-principle ethical framework. |

---

**These rules are not aspirational. They are operational constraints that define what EvoCortexAI will and will not build.**

*Proposed as an amendment to the sole canonical ethical reference for the EvoCortexAI ecosystem. Not authoritative until founder approval.*
