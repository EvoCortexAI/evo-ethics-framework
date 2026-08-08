import Testing
@testable import EvoEthics

@Suite("EvoEthics reference evaluator")
struct EvoEthicsTests {

    private let policy: PolicyBundle
    private let evaluator: ReferenceEthicsEvaluator

    init() throws {
        self.policy = try PolicyBundleLoader.bundledDevelopmentPolicy()
        self.evaluator = ReferenceEthicsEvaluator(policy: policy)
    }

    @Test("local inference allows with audit obligation")
    func localInferenceAllowsWithAuditObligation() {
        let decision = evaluator.evaluate(request(
            action: "model.infer.local",
            context: safeLocalContext()
        ))

        #expect(decision.decision == .allowWithObligations)
        #expect(decision.controls.contains("EC-E3-002"))
        #expect(decision.obligations.contains { $0.kind == .recordAudit })
    }

    @Test("restricted external inference is denied")
    func restrictedExternalInferenceIsDenied() {
        let context = EvaluationContext(
            executionTarget: .externalService,
            dataSensitivity: .restricted,
            externalProvider: "example-provider",
            networkEgress: true,
            agency: .humanInitiated,
            explicitApproval: .confirmed,
            auditReady: .confirmed,
            boundedScope: .notApplicable,
            interruptible: .notApplicable,
            reversible: .notApplicable,
            providerPortability: .confirmed
        )

        let decision = evaluator.evaluate(request(
            action: "model.infer.external",
            context: context
        ))

        #expect(decision.decision == .deny)
        #expect(decision.controls.contains("EC-E2-001"))
        #expect(decision.principles.contains(.e2))
        #expect(decision.obligations.map(\.kind) == [.recordAudit])
    }

    @Test("container delete requires approval and irreversibility acknowledgement")
    func containerDeleteRequiresApprovalAndIrreversibilityAcknowledgement() {
        let context = EvaluationContext(
            executionTarget: .localDevice,
            dataSensitivity: .internalData,
            networkEgress: false,
            agency: .humanInitiated,
            explicitApproval: .absent,
            auditReady: .confirmed,
            boundedScope: .notApplicable,
            interruptible: .notApplicable,
            reversible: .absent,
            providerPortability: .notApplicable
        )

        let decision = evaluator.evaluate(request(
            component: "saturn-container",
            action: "container.delete",
            context: context
        ))

        #expect(decision.decision == .requireApproval)
        #expect(decision.controls.contains("EC-E4-001"))
        #expect(decision.controls.contains("EC-E7-002"))
        #expect(decision.obligations.contains { $0.kind == .acknowledgeIrreversibility })
    }

    @Test("unbounded agentic action is denied")
    func unboundedAgenticActionIsDenied() {
        let context = EvaluationContext(
            executionTarget: .privateNode,
            dataSensitivity: .confidential,
            networkEgress: false,
            agency: .boundedAgentic,
            explicitApproval: .confirmed,
            auditReady: .confirmed,
            boundedScope: .absent,
            interruptible: .confirmed,
            reversible: .confirmed,
            providerPortability: .confirmed
        )

        let decision = evaluator.evaluate(request(
            action: "agent.execute.bounded",
            context: context
        ))

        #expect(decision.decision == .deny)
        #expect(decision.controls.contains("EC-E4-002"))
    }

    @Test("unknown action fails closed")
    func unknownActionFailsClosed() {
        let decision = evaluator.evaluate(request(
            action: "unknown.action",
            context: safeLocalContext()
        ))

        #expect(decision.decision == .deny)
        #expect(decision.controls == ["EC-CORE-002"])
    }

    @Test("design dependency without portability requires review")
    func designDependencyWithoutPortabilityRequiresReview() {
        let context = EvaluationContext(
            executionTarget: .externalService,
            dataSensitivity: .internalData,
            externalProvider: "single-provider",
            networkEgress: true,
            agency: .assisted,
            explicitApproval: .notApplicable,
            auditReady: .confirmed,
            boundedScope: .notApplicable,
            interruptible: .notApplicable,
            reversible: .confirmed,
            providerPortability: .absent
        )

        let decision = evaluator.evaluate(request(
            phase: .design,
            action: "architecture.external-provider-dependency",
            context: context
        ))

        #expect(decision.decision == .requireReview)
        #expect(decision.controls.contains("EC-E10-001"))
    }

    @Test("evaluation is deterministic")
    func evaluationIsDeterministic() {
        let value = request(action: "model.infer.local", context: safeLocalContext())
        #expect(evaluator.evaluate(value) == evaluator.evaluate(value))
    }

    // MARK: - Helpers

    private func request(
        component: String = "saturn-control",
        phase: EvaluationPhase = .runtime,
        action: String,
        context: EvaluationContext
    ) -> EvaluationRequest {
        EvaluationRequest(
            requestId: "req-test-001",
            timestamp: "2026-07-25T12:00:00Z",
            component: component,
            phase: phase,
            action: action,
            actor: EvaluationActor(kind: .human, id: "local-user"),
            resource: EvaluationResource(kind: "test-resource", id: "resource-001"),
            context: context
        )
    }

    private func safeLocalContext() -> EvaluationContext {
        EvaluationContext(
            executionTarget: .localDevice,
            dataSensitivity: .internalData,
            networkEgress: false,
            agency: .humanInitiated,
            explicitApproval: .notApplicable,
            auditReady: .confirmed,
            boundedScope: .notApplicable,
            interruptible: .notApplicable,
            reversible: .confirmed,
            providerPortability: .confirmed
        )
    }
}
