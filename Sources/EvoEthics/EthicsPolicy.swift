import Foundation

public struct ActionDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let risk: RiskLevel
    public let requiresAudit: Bool
    public let requiresApproval: Bool
    public let destructive: Bool
    public let allowedPhases: [EvaluationPhase]

    public init(
        id: String,
        risk: RiskLevel,
        requiresAudit: Bool,
        requiresApproval: Bool,
        destructive: Bool,
        allowedPhases: [EvaluationPhase]
    ) {
        self.id = id
        self.risk = risk
        self.requiresAudit = requiresAudit
        self.requiresApproval = requiresApproval
        self.destructive = destructive
        self.allowedPhases = allowedPhases
    }
}

public struct PolicyBundle: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let policyVersion: String
    public let ethicsSourceVersion: String
    public let digest: String
    public let actions: [ActionDefinition]

    public init(
        schemaVersion: String,
        policyVersion: String,
        ethicsSourceVersion: String,
        digest: String,
        actions: [ActionDefinition]
    ) {
        self.schemaVersion = schemaVersion
        self.policyVersion = policyVersion
        self.ethicsSourceVersion = ethicsSourceVersion
        self.digest = digest
        self.actions = actions
    }

    public func actionDefinition(for actionID: String) -> ActionDefinition? {
        actions.first { $0.id == actionID }
    }
}

public enum PolicyBundleLoaderError: Error, LocalizedError {
    case missingBundledPolicy
    case duplicateActionID(String)

    public var errorDescription: String? {
        switch self {
        case .missingBundledPolicy:
            "The bundled development policy could not be found."
        case let .duplicateActionID(actionID):
            "The policy contains a duplicate action ID: \(actionID)"
        }
    }
}

public enum PolicyBundleLoader {
    public static func decode(data: Data) throws -> PolicyBundle {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let policy = try decoder.decode(PolicyBundle.self, from: data)
        try validate(policy)
        return policy
    }

    public static func decode(url: URL) throws -> PolicyBundle {
        try decode(data: Data(contentsOf: url))
    }

    public static func bundledDevelopmentPolicy() throws -> PolicyBundle {
        guard let url = Bundle.module.url(
            forResource: "development-policy",
            withExtension: "json"
        ) else {
            throw PolicyBundleLoaderError.missingBundledPolicy
        }
        return try decode(url: url)
    }

    private static func validate(_ policy: PolicyBundle) throws {
        var seen = Set<String>()
        for action in policy.actions {
            if !seen.insert(action.id).inserted {
                throw PolicyBundleLoaderError.duplicateActionID(action.id)
            }
        }
    }
}
