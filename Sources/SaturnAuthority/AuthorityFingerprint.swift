import Foundation

/// Canonical authority fingerprint required by SATURN-UNIFIED-ARCHITECTURE §9.2.
/// Material changes invalidate prior authority and require re-evaluation.
public struct AuthorityFingerprint: Equatable, Sendable, Codable, Hashable {
    public let actorID: String
    public let actionID: String
    public let resourceID: String
    public let operationID: String
    public let deploymentID: String
    public let workloadID: String
    public let imageDigest: String
    public let runnerID: String
    public let nodeID: String
    public let modelID: String
    public let toolOrResourceID: String?
    public let dataClassification: String?
    public let resourceLimits: [String: String]
    public let computeLimits: [String: String]
    public let approvalReference: String?
    public let policyVersion: String
    public let policyBundleDigest: String
    public let issuedAt: String          // ISO-8601
    public let expiry: String            // ISO-8601
    public let nonce: String
    public let bindingAlgorithm: String
    public let keyID: String

    public init(
        actorID: String,
        actionID: String,
        resourceID: String,
        operationID: String,
        deploymentID: String,
        workloadID: String,
        imageDigest: String,
        runnerID: String,
        nodeID: String,
        modelID: String,
        toolOrResourceID: String? = nil,
        dataClassification: String? = nil,
        resourceLimits: [String: String] = [:],
        computeLimits: [String: String] = [:],
        approvalReference: String? = nil,
        policyVersion: String,
        policyBundleDigest: String,
        issuedAt: String,
        expiry: String,
        nonce: String,
        bindingAlgorithm: String,
        keyID: String
    ) {
        self.actorID = actorID
        self.actionID = actionID
        self.resourceID = resourceID
        self.operationID = operationID
        self.deploymentID = deploymentID
        self.workloadID = workloadID
        self.imageDigest = imageDigest
        self.runnerID = runnerID
        self.nodeID = nodeID
        self.modelID = modelID
        self.toolOrResourceID = toolOrResourceID
        self.dataClassification = dataClassification
        self.resourceLimits = resourceLimits
        self.computeLimits = computeLimits
        self.approvalReference = approvalReference
        self.policyVersion = policyVersion
        self.policyBundleDigest = policyBundleDigest
        self.issuedAt = issuedAt
        self.expiry = expiry
        self.nonce = nonce
        self.bindingAlgorithm = bindingAlgorithm
        self.keyID = keyID
    }
}
