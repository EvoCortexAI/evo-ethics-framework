import Foundation

/// Bound authorization evidence for an exact protected operation.
/// Distinct from an EvoEthics Decision and from a ComputeLease.
public struct AuthorityReceipt: Equatable, Sendable, Codable, Hashable {
    public let receiptID: String
    public let fingerprint: AuthorityFingerprint
    public let decisionOutcome: String           // allow | allow_with_obligations | require_approval | require_review | deny
    public let obligations: [String]
    public let sealAlgorithm: String
    public let sealValue: String                 // opaque; production PEPs verify, do not re-compute here
    public let issuedAt: String
    public let expiry: String

    public init(
        receiptID: String,
        fingerprint: AuthorityFingerprint,
        decisionOutcome: String,
        obligations: [String] = [],
        sealAlgorithm: String,
        sealValue: String,
        issuedAt: String,
        expiry: String
    ) {
        self.receiptID = receiptID
        self.fingerprint = fingerprint
        self.decisionOutcome = decisionOutcome
        self.obligations = obligations
        self.sealAlgorithm = sealAlgorithm
        self.sealValue = sealValue
        self.issuedAt = issuedAt
        self.expiry = expiry
    }
}
