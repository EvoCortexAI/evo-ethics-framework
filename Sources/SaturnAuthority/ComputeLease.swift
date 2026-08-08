import Foundation

/// Short-lived workload-scoped compute authority for one Node/model/limit set.
/// Distinct from an AuthorityReceipt.
public struct ComputeLease: Equatable, Sendable, Codable, Hashable {
    public let leaseID: String
    public let fingerprint: AuthorityFingerprint
    public let nodeID: String
    public let modelID: String
    public let contextLimit: Int
    public let outputLimit: Int
    public let concurrencyLimit: Int
    public let budget: String?
    public let sealAlgorithm: String
    public let sealValue: String
    public let issuedAt: String
    public let expiry: String

    public init(
        leaseID: String,
        fingerprint: AuthorityFingerprint,
        nodeID: String,
        modelID: String,
        contextLimit: Int,
        outputLimit: Int,
        concurrencyLimit: Int = 1,
        budget: String? = nil,
        sealAlgorithm: String,
        sealValue: String,
        issuedAt: String,
        expiry: String
    ) {
        self.leaseID = leaseID
        self.fingerprint = fingerprint
        self.nodeID = nodeID
        self.modelID = modelID
        self.contextLimit = contextLimit
        self.outputLimit = outputLimit
        self.concurrencyLimit = concurrencyLimit
        self.budget = budget
        self.sealAlgorithm = sealAlgorithm
        self.sealValue = sealValue
        self.issuedAt = issuedAt
        self.expiry = expiry
    }
}
