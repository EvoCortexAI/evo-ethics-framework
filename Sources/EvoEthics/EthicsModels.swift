import Foundation

public enum EthicsPrincipleID: String, Codable, CaseIterable, Sendable {
    case e1 = "E1"
    case e2 = "E2"
    case e3 = "E3"
    case e4 = "E4"
    case e5 = "E5"
    case e6 = "E6"
    case e7 = "E7"
    case e8 = "E8"
    case e9 = "E9"
    case e10 = "E10"
}

public enum EvaluationPhase: String, Codable, CaseIterable, Sendable {
    case runtime
    case design
}

public enum ActorKind: String, Codable, CaseIterable, Sendable {
    case human
    case service
    case boundedAgent = "bounded_agent"
}

public enum ExecutionTarget: String, Codable, CaseIterable, Sendable {
    case localDevice = "local_device"
    case privateNode = "private_node"
    case externalService = "external_service"
}

public enum DataSensitivity: String, Codable, CaseIterable, Sendable {
    case publicData = "public"
    case internalData = "internal"
    case confidential
    case restricted
}

public enum AgencyMode: String, Codable, CaseIterable, Sendable {
    case humanInitiated = "human_initiated"
    case assisted
    case boundedAgentic = "bounded_agentic"
}

public enum AssuranceState: String, Codable, CaseIterable, Sendable {
    case confirmed
    case absent
    case unknown
    case notApplicable = "not_applicable"
}

public enum RiskLevel: String, Codable, CaseIterable, Sendable, Comparable {
    case low
    case moderate
    case high
    case critical

    private var rank: Int {
        switch self {
        case .low: 0
        case .moderate: 1
        case .high: 2
        case .critical: 3
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

public enum DecisionOutcome: String, Codable, CaseIterable, Sendable {
    case allow
    case allowWithObligations = "allow_with_obligations"
    case requireApproval = "require_approval"
    case requireReview = "require_review"
    case deny

    var precedence: Int {
        switch self {
        case .allow: 0
        case .allowWithObligations: 1
        case .requireApproval: 2
        case .requireReview: 3
        case .deny: 4
        }
    }
}

public enum ObligationKind: String, Codable, CaseIterable, Sendable {
    case recordAudit = "record_audit"
    case minimizeData = "minimize_data"
    case discloseExternalProvider = "disclose_external_provider"
    case obtainExplicitApproval = "obtain_explicit_approval"
    case verifyApprovalBinding = "verify_approval_binding"
    case acknowledgeIrreversibility = "acknowledge_irreversibility"
    case humanDesignReview = "human_design_review"
}

public struct EvaluationActor: Codable, Equatable, Sendable {
    public let kind: ActorKind
    public let id: String

    public init(kind: ActorKind, id: String) {
        self.kind = kind
        self.id = id
    }
}

public struct EvaluationResource: Codable, Equatable, Sendable {
    public let kind: String
    public let id: String

    public init(kind: String, id: String) {
        self.kind = kind
        self.id = id
    }
}

public struct EvaluationContext: Codable, Equatable, Sendable {
    public let executionTarget: ExecutionTarget
    public let dataSensitivity: DataSensitivity
    public let externalProvider: String?
    public let networkEgress: Bool
    public let agency: AgencyMode
    public let explicitApproval: AssuranceState
    public let auditReady: AssuranceState
    public let boundedScope: AssuranceState
    public let interruptible: AssuranceState
    public let reversible: AssuranceState
    public let providerPortability: AssuranceState

    public init(
        executionTarget: ExecutionTarget,
        dataSensitivity: DataSensitivity,
        externalProvider: String? = nil,
        networkEgress: Bool,
        agency: AgencyMode,
        explicitApproval: AssuranceState,
        auditReady: AssuranceState,
        boundedScope: AssuranceState,
        interruptible: AssuranceState,
        reversible: AssuranceState,
        providerPortability: AssuranceState
    ) {
        self.executionTarget = executionTarget
        self.dataSensitivity = dataSensitivity
        self.externalProvider = externalProvider
        self.networkEgress = networkEgress
        self.agency = agency
        self.explicitApproval = explicitApproval
        self.auditReady = auditReady
        self.boundedScope = boundedScope
        self.interruptible = interruptible
        self.reversible = reversible
        self.providerPortability = providerPortability
    }
}

public struct EvaluationRequest: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let requestId: String
    public let timestamp: String
    public let component: String
    public let phase: EvaluationPhase
    public let action: String
    public let actor: EvaluationActor
    public let resource: EvaluationResource
    public let context: EvaluationContext

    public init(
        schemaVersion: String = "1.0.0",
        requestId: String,
        timestamp: String,
        component: String,
        phase: EvaluationPhase,
        action: String,
        actor: EvaluationActor,
        resource: EvaluationResource,
        context: EvaluationContext
    ) {
        self.schemaVersion = schemaVersion
        self.requestId = requestId
        self.timestamp = timestamp
        self.component = component
        self.phase = phase
        self.action = action
        self.actor = actor
        self.resource = resource
        self.context = context
    }
}

public struct DecisionObligation: Codable, Equatable, Sendable {
    public let kind: ObligationKind
    public let detail: String

    public init(kind: ObligationKind, detail: String) {
        self.kind = kind
        self.detail = detail
    }
}

public struct EvaluationDecision: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let requestId: String
    public let decision: DecisionOutcome
    public let principles: [EthicsPrincipleID]
    public let controls: [String]
    public let obligations: [DecisionObligation]
    public let policyVersion: String
    public let policyDigest: String
    public let auditId: String
    public let explanation: String

    public init(
        schemaVersion: String = "1.0.0",
        requestId: String,
        decision: DecisionOutcome,
        principles: [EthicsPrincipleID],
        controls: [String],
        obligations: [DecisionObligation],
        policyVersion: String,
        policyDigest: String,
        auditId: String,
        explanation: String
    ) {
        self.schemaVersion = schemaVersion
        self.requestId = requestId
        self.decision = decision
        self.principles = principles
        self.controls = controls
        self.obligations = obligations
        self.policyVersion = policyVersion
        self.policyDigest = policyDigest
        self.auditId = auditId
        self.explanation = explanation
    }
}
