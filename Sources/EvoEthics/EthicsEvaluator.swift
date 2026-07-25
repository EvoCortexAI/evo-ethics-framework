import Foundation

public protocol EthicsEvaluating: Sendable {
    func evaluate(_ request: EvaluationRequest) -> EvaluationDecision
}

public struct ReferenceEthicsEvaluator: EthicsEvaluating, Sendable {
    private let policy: PolicyBundle

    public init(policy: PolicyBundle) {
        self.policy = policy
    }

    public func evaluate(_ request: EvaluationRequest) -> EvaluationDecision {
        var outcome: DecisionOutcome = .allow
        var principles = Set<EthicsPrincipleID>()
        var controls = [String]()
        var obligations = [DecisionObligation]()

        func hasControl(_ id: String) -> Bool {
            controls.contains(id)
        }

        func add(
            _ candidate: DecisionOutcome,
            control: String,
            principles newPrinciples: [EthicsPrincipleID],
            obligation: DecisionObligation? = nil
        ) {
            if candidate.precedence > outcome.precedence {
                outcome = candidate
            }
            if !hasControl(control) {
                controls.append(control)
            }
            principles.formUnion(newPrinciples)
            if let obligation, !obligations.contains(obligation) {
                obligations.append(obligation)
            }
        }

        guard !request.requestId.isEmpty,
              !request.component.isEmpty,
              !request.action.isEmpty,
              !request.actor.id.isEmpty,
              !request.resource.kind.isEmpty,
              !request.resource.id.isEmpty else {
            add(
                .deny,
                control: "EC-CORE-001",
                principles: [.e3, .e6]
            )
            return makeDecision(
                request: request,
                outcome: outcome,
                principles: principles,
                controls: controls,
                obligations: obligations
            )
        }

        guard let action = policy.actionDefinition(for: request.action) else {
            add(
                .deny,
                control: "EC-CORE-002",
                principles: [.e3, .e6, .e7]
            )
            return makeDecision(
                request: request,
                outcome: outcome,
                principles: principles,
                controls: controls,
                obligations: obligations
            )
        }

        if !action.allowedPhases.contains(request.phase) {
            add(
                .deny,
                control: "EC-CORE-003",
                principles: [.e3, .e6, .e7]
            )
        }

        if action.requiresAudit {
            if request.context.auditReady != .confirmed {
                add(
                    .deny,
                    control: "EC-E3-001",
                    principles: [.e3, .e6]
                )
            } else {
                add(
                    .allowWithObligations,
                    control: "EC-E3-002",
                    principles: [.e3, .e6],
                    obligation: DecisionObligation(
                        kind: .recordAudit,
                        detail: "Record the decision basis and final enforcement outcome without raw user content."
                    )
                )
            }
        }

        if request.context.executionTarget == .externalService {
            if !request.context.networkEgress || request.context.externalProvider?.isEmpty != false {
                add(
                    .deny,
                    control: "EC-E3-003",
                    principles: [.e2, .e3, .e6]
                )
            }

            if request.context.dataSensitivity == .restricted {
                add(
                    .deny,
                    control: "EC-E2-001",
                    principles: [.e1, .e2, .e4]
                )
            } else if request.context.dataSensitivity == .confidential,
                      request.context.explicitApproval != .confirmed {
                add(
                    .requireApproval,
                    control: "EC-E2-002",
                    principles: [.e1, .e2, .e4],
                    obligation: DecisionObligation(
                        kind: .obtainExplicitApproval,
                        detail: "Obtain approval bound to the external provider, data class, action, and request fingerprint."
                    )
                )
            }

            add(
                .allowWithObligations,
                control: "EC-E2-003",
                principles: [.e2, .e3, .e10],
                obligation: DecisionObligation(
                    kind: .discloseExternalProvider,
                    detail: "Disclose the external provider and execution target before execution."
                )
            )
            if request.phase == .runtime {
                add(
                    .allowWithObligations,
                    control: "EC-E2-004",
                    principles: [.e2],
                    obligation: DecisionObligation(
                        kind: .minimizeData,
                        detail: "Send only the minimum data required for the approved purpose."
                    )
                )
            }
        }

        if action.requiresApproval {
            if request.context.explicitApproval != .confirmed {
                add(
                    .requireApproval,
                    control: "EC-E4-001",
                    principles: [.e1, .e4, .e7],
                    obligation: DecisionObligation(
                        kind: .obtainExplicitApproval,
                        detail: "Obtain exact, informed approval before the side effect."
                    )
                )
            } else {
                add(
                    .allowWithObligations,
                    control: "EC-E4-004",
                    principles: [.e1, .e4, .e6],
                    obligation: DecisionObligation(
                        kind: .verifyApprovalBinding,
                        detail: "Verify that approval matches the action, resource, request fingerprint, and expiry."
                    )
                )
            }
        }

        if request.context.agency == .boundedAgentic {
            if request.context.boundedScope != .confirmed {
                add(
                    .deny,
                    control: "EC-E4-002",
                    principles: [.e1, .e4, .e7]
                )
            }
            if request.context.interruptible != .confirmed {
                add(
                    .deny,
                    control: "EC-E4-003",
                    principles: [.e1, .e4, .e7]
                )
            }
            if request.context.explicitApproval != .confirmed {
                add(
                    .requireApproval,
                    control: "EC-E4-005",
                    principles: [.e1, .e4, .e7],
                    obligation: DecisionObligation(
                        kind: .obtainExplicitApproval,
                        detail: "Approve the bounded agentic scope, duration, permissions, and resources."
                    )
                )
            }
        }

        if action.destructive,
           request.context.reversible != .confirmed {
            if action.risk == .critical {
                add(
                    .requireReview,
                    control: "EC-E7-001",
                    principles: [.e6, .e7, .e8],
                    obligation: DecisionObligation(
                        kind: .humanDesignReview,
                        detail: "Review the irreversible critical action, safeguards, and recovery plan."
                    )
                )
            } else {
                add(
                    .requireApproval,
                    control: "EC-E7-002",
                    principles: [.e1, .e6, .e7],
                    obligation: DecisionObligation(
                        kind: .acknowledgeIrreversibility,
                        detail: "Make irreversibility and available recovery options explicit before approval."
                    )
                )
            }
        }

        if request.phase == .design,
           request.context.providerPortability != .confirmed {
            add(
                .requireReview,
                control: "EC-E10-001",
                principles: [.e8, .e10],
                obligation: DecisionObligation(
                    kind: .humanDesignReview,
                    detail: "Document portability, graceful degradation, or a justified exception to provider independence."
                )
            )
        }

        return makeDecision(
            request: request,
            outcome: outcome,
            principles: principles,
            controls: controls,
            obligations: obligations
        )
    }

    private func makeDecision(
        request: EvaluationRequest,
        outcome: DecisionOutcome,
        principles: Set<EthicsPrincipleID>,
        controls: [String],
        obligations: [DecisionObligation]
    ) -> EvaluationDecision {
        let sortedPrinciples = principles.sorted { left, right in
            principleNumber(left) < principleNumber(right)
        }
        let explanation: String
        if controls.isEmpty {
            explanation = "The action is registered and no blocking or escalation control applied."
        } else {
            explanation = "Decision produced by controls: \(controls.joined(separator: ", "))."
        }

        let finalObligations: [DecisionObligation]
        if outcome == .deny {
            finalObligations = obligations.filter { $0.kind == .recordAudit }
        } else {
            finalObligations = obligations
        }

        return EvaluationDecision(
            requestId: request.requestId,
            decision: outcome,
            principles: sortedPrinciples,
            controls: controls,
            obligations: finalObligations,
            policyVersion: policy.policyVersion,
            policyDigest: policy.digest,
            auditId: "ethics:\(request.requestId):\(policy.policyVersion)",
            explanation: explanation
        )
    }

    private func principleNumber(_ principle: EthicsPrincipleID) -> Int {
        Int(principle.rawValue.dropFirst()) ?? Int.max
    }
}
