import Foundation

// MARK: - Authority Verifying (PEP contract)

/// Final-side-effect PEPs (Container Runner, Saturn-Node, Agent tool adapters)
/// verify exact authority immediately before execution.
///
/// Production PEPs must reject forged, expired, replayed, context-mismatched,
/// revoked, or policy-downgraded receipts/leases. See SUA §11.
public protocol AuthorityVerifying: Sendable {
    /// Verify a receipt against expected operation material facts.
    /// Fails closed on any mismatch, expiry, or unsupported version.
    func verify(
        receipt: AuthorityReceipt,
        expected: AuthorityFingerprint,
        at now: Date
    ) throws

    /// Verify a compute lease against expected Node/model/limit facts.
    func verify(
        lease: ComputeLease,
        expected: AuthorityFingerprint,
        at now: Date
    ) throws
}

// MARK: - Authority Issuing (Control / PAP-adjacent contract)

/// Saturn-Control is the system issuer of bound authority receipts and leases.
/// Agents and frontends must never mint infrastructure authority.
public protocol AuthorityIssuing: Sendable {
    /// Issue a decision receipt bound to an exact fingerprint and governance outcome.
    func issueReceipt(
        fingerprint: AuthorityFingerprint,
        decisionOutcome: String,
        obligations: [String],
        sealAlgorithm: String,
        sealValue: String,
        issuedAt: String,
        expiry: String
    ) throws -> AuthorityReceipt

    /// Issue a short-lived workload-scoped compute lease for one Node/model/limit set.
    func issueLease(
        fingerprint: AuthorityFingerprint,
        nodeID: String,
        modelID: String,
        contextLimit: Int,
        outputLimit: Int,
        concurrencyLimit: Int,
        budget: String?,
        sealAlgorithm: String,
        sealValue: String,
        issuedAt: String,
        expiry: String
    ) throws -> ComputeLease
}

// MARK: - Structural verifier (no crypto; production PEPs add seal verification)

/// Deterministic structural checks shared by all PEPs.
/// Cryptographic seal verification is deployment-specific and injected by Control/Runner/Node.
public struct StructuralAuthorityVerifier: AuthorityVerifying, Sendable {
    public init() {}

    public func verify(
        receipt: AuthorityReceipt,
        expected: AuthorityFingerprint,
        at now: Date
    ) throws {
        try verifyFingerprintMatch(receipt.fingerprint, expected: expected)
        try verifyNotExpired(receipt.expiry, at: now)
        try verifyDecisionOutcome(receipt.decisionOutcome)
    }

    public func verify(
        lease: ComputeLease,
        expected: AuthorityFingerprint,
        at now: Date
    ) throws {
        try verifyFingerprintMatch(lease.fingerprint, expected: expected)
        try verifyNotExpired(lease.expiry, at: now)
        if lease.nodeID != expected.nodeID {
            throw AuthorityError.scopeMismatch("lease nodeID does not match expected nodeID")
        }
        if lease.modelID != expected.modelID {
            throw AuthorityError.scopeMismatch("lease modelID does not match expected modelID")
        }
    }

    private func verifyFingerprintMatch(
        _ actual: AuthorityFingerprint,
        expected: AuthorityFingerprint
    ) throws {
        // Material identity: any field change invalidates authority (SUA §9.2).
        guard actual == expected else {
            throw AuthorityError.scopeMismatch("authority fingerprint material mismatch")
        }
    }

    private func verifyNotExpired(_ expiryISO: String, at now: Date) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var expiry = formatter.date(from: expiryISO)
        if expiry == nil {
            formatter.formatOptions = [.withInternetDateTime]
            expiry = formatter.date(from: expiryISO)
        }
        guard let expiryDate = expiry else {
            throw AuthorityError.invalidFingerprint("unparseable expiry: \(expiryISO)")
        }
        if now >= expiryDate {
            throw AuthorityError.expired
        }
    }

    private func verifyDecisionOutcome(_ outcome: String) throws {
        let allowed = ["allow", "allow_with_obligations", "require_approval", "require_review", "deny"]
        guard allowed.contains(outcome) else {
            throw AuthorityError.invalidFingerprint("unsupported decisionOutcome: \(outcome)")
        }
        // A deny receipt must never authorize a side effect.
        if outcome == "deny" {
            throw AuthorityError.scopeMismatch("deny receipt cannot authorize execution")
        }
    }
}

// MARK: - Default issuer (identity + structural; seal is caller-supplied)

public struct DefaultAuthorityIssuer: AuthorityIssuing, Sendable {
    public init() {}

    public func issueReceipt(
        fingerprint: AuthorityFingerprint,
        decisionOutcome: String,
        obligations: [String],
        sealAlgorithm: String,
        sealValue: String,
        issuedAt: String,
        expiry: String
    ) throws -> AuthorityReceipt {
        let allowed = ["allow", "allow_with_obligations", "require_approval", "require_review", "deny"]
        guard allowed.contains(decisionOutcome) else {
            throw AuthorityError.invalidFingerprint("unsupported decisionOutcome: \(decisionOutcome)")
        }
        return AuthorityReceipt(
            receiptID: UUID().uuidString,
            fingerprint: fingerprint,
            decisionOutcome: decisionOutcome,
            obligations: obligations,
            sealAlgorithm: sealAlgorithm,
            sealValue: sealValue,
            issuedAt: issuedAt,
            expiry: expiry
        )
    }

    public func issueLease(
        fingerprint: AuthorityFingerprint,
        nodeID: String,
        modelID: String,
        contextLimit: Int,
        outputLimit: Int,
        concurrencyLimit: Int,
        budget: String?,
        sealAlgorithm: String,
        sealValue: String,
        issuedAt: String,
        expiry: String
    ) throws -> ComputeLease {
        guard nodeID == fingerprint.nodeID else {
            throw AuthorityError.scopeMismatch("lease nodeID must match fingerprint.nodeID")
        }
        guard modelID == fingerprint.modelID else {
            throw AuthorityError.scopeMismatch("lease modelID must match fingerprint.modelID")
        }
        return ComputeLease(
            leaseID: UUID().uuidString,
            fingerprint: fingerprint,
            nodeID: nodeID,
            modelID: modelID,
            contextLimit: contextLimit,
            outputLimit: outputLimit,
            concurrencyLimit: concurrencyLimit,
            budget: budget,
            sealAlgorithm: sealAlgorithm,
            sealValue: sealValue,
            issuedAt: issuedAt,
            expiry: expiry
        )
    }
}
