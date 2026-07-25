import XCTest
@testable import EvoEthics

final class EvoEthicsTests: XCTestCase {
    private var policy: PolicyBundle!
    private var evaluator: ReferenceEthicsEvaluator!

    override func setUpWithError() throws {
        policy = try PolicyBundleLoader.bundledDevelopmentPolicy()
        evaluator = ReferenceEthicsEvaluator(policy: policy)
    }

    func testLocalInferenceAllowsWithAuditObligation() {
        let decision = evaluator.evaluate(request(
            action: "model.infer.local",
            context: safeLocalContext()
        ))

        XCTAssertEqual(decision.decision, .allowWithObligations)
        XCTAssertTrue(decision.controls.contains("EC-E3-002"))
        XCTAssertTrue(decision.obligations.contains { $0.kind == .recordAudit })
    }

    func testRestrictedExternalInferenceIsDenied() {
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

        XCTAssertEqual(decision.decision, .deny)
        XCTAssertTrue(decision.controls.contains("EC-E2-001"))
        XCTAssertTrue(decision.principles.contains(.e2))
        XCTAssertEqual(decision.obligations.map(\.kind), [.recordAudit])
    }

    func testContainerDeleteRequiresApprovalAndIrreversibilityAcknowledgement() {
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

        XCTAssertEqual(decision.decision, .requireApproval)
        XCTAssertTrue(decision.controls.contains("EC-E4-001"))
        XCTAssertTrue(decision.controls.contains("EC-E7-002"))
        XCTAssertTrue(decision.obligations.contains { $0.kind == .acknowledgeIrreversibility })
    }

    func testUnboundedAgenticActionIsDenied() {
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

        XCTAssertEqual(decision.decision, .deny)
        XCTAssertTrue(decision.controls.contains("EC-E4-002"))
    }

    func testUnknownActionFailsClosed() {
        let decision = evaluator.evaluate(request(
            action: "unknown.action",
            context: safeLocalContext()
        ))

        XCTAssertEqual(decision.decision, .deny)
        XCTAssertEqual(decision.controls, ["EC-CORE-002"])
    }

    func testDesignDependencyWithoutPortabilityRequiresReview() {
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

        XCTAssertEqual(decision.decision, .requireReview)
        XCTAssertTrue(decision.controls.contains("EC-E10-001"))
    }

    func testEvaluationIsDeterministic() {
        let value = request(action: "model.infer.local", context: safeLocalContext())
        XCTAssertEqual(evaluator.evaluate(value), evaluator.evaluate(value))
    }

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
