import XCTest
@testable import SaturnAuthority

final class SaturnAuthorityTests: XCTestCase {

    func testFingerprintRoundTrip() throws {
        let fp = sampleFingerprint()
        let data = try CanonicalSerialization.encode(fp)
        let decoded = try CanonicalSerialization.decode(AuthorityFingerprint.self, from: data)
        XCTAssertEqual(fp, decoded)
    }

    func testCanonicalStringIsDeterministic() throws {
        let fp = sampleFingerprint()
        let a = try CanonicalSerialization.canonicalString(fp)
        let b = try CanonicalSerialization.canonicalString(fp)
        XCTAssertEqual(a, b)
    }

    func testMaterialFieldChangeProducesDifferentCanonicalForm() throws {
        let a = sampleFingerprint()
        let b = AuthorityFingerprint(
            actorID: a.actorID,
            actionID: a.actionID,
            resourceID: a.resourceID,
            operationID: a.operationID,
            deploymentID: a.deploymentID,
            workloadID: a.workloadID,
            imageDigest: "sha256:different",
            runnerID: a.runnerID,
            nodeID: a.nodeID,
            modelID: a.modelID,
            toolOrResourceID: a.toolOrResourceID,
            dataClassification: a.dataClassification,
            resourceLimits: a.resourceLimits,
            computeLimits: a.computeLimits,
            approvalReference: a.approvalReference,
            policyVersion: a.policyVersion,
            policyBundleDigest: a.policyBundleDigest,
            issuedAt: a.issuedAt,
            expiry: a.expiry,
            nonce: a.nonce,
            bindingAlgorithm: a.bindingAlgorithm,
            keyID: a.keyID
        )
        let sa = try CanonicalSerialization.canonicalString(a)
        let sb = try CanonicalSerialization.canonicalString(b)
        XCTAssertNotEqual(sa, sb)
    }

    func testReceiptRoundTrip() throws {
        let receipt = AuthorityReceipt(
            receiptID: "rcpt-001",
            fingerprint: sampleFingerprint(),
            decisionOutcome: "allow_with_obligations",
            obligations: ["metadata_audit", "local_execution"],
            sealAlgorithm: "ed25519",
            sealValue: "placeholder-seal",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2026-08-08T01:00:00Z"
        )
        let data = try CanonicalSerialization.encode(receipt)
        let decoded = try CanonicalSerialization.decode(AuthorityReceipt.self, from: data)
        XCTAssertEqual(receipt, decoded)
    }

    func testLeaseRoundTrip() throws {
        let lease = ComputeLease(
            leaseID: "lease-001",
            fingerprint: sampleFingerprint(),
            nodeID: "node-01",
            modelID: "mlx-model-pinned",
            contextLimit: 8192,
            outputLimit: 2048,
            concurrencyLimit: 1,
            sealAlgorithm: "ed25519",
            sealValue: "placeholder-seal",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2026-08-08T00:30:00Z"
        )
        let data = try CanonicalSerialization.encode(lease)
        let decoded = try CanonicalSerialization.decode(ComputeLease.self, from: data)
        XCTAssertEqual(lease, decoded)
    }

    func testStructuralVerifierAcceptsMatchingReceipt() throws {
        let fp = sampleFingerprint()
        let receipt = AuthorityReceipt(
            receiptID: "rcpt-ok",
            fingerprint: fp,
            decisionOutcome: "allow",
            obligations: [],
            sealAlgorithm: "ed25519",
            sealValue: "seal",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2099-01-01T00:00:00Z"
        )
        let verifier = StructuralAuthorityVerifier()
        try verifier.verify(receipt: receipt, expected: fp, at: Date())
    }

    func testStructuralVerifierRejectsDenyReceipt() {
        let fp = sampleFingerprint()
        let receipt = AuthorityReceipt(
            receiptID: "rcpt-deny",
            fingerprint: fp,
            decisionOutcome: "deny",
            obligations: [],
            sealAlgorithm: "ed25519",
            sealValue: "seal",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2099-01-01T00:00:00Z"
        )
        let verifier = StructuralAuthorityVerifier()
        XCTAssertThrowsError(
            try verifier.verify(receipt: receipt, expected: fp, at: Date())
        ) { error in
            XCTAssertEqual(error as? AuthorityError, .scopeMismatch("deny receipt cannot authorize execution"))
        }
    }

    func testStructuralVerifierRejectsFingerprintMismatch() {
        let a = sampleFingerprint()
        let b = AuthorityFingerprint(
            actorID: a.actorID,
            actionID: a.actionID,
            resourceID: a.resourceID,
            operationID: a.operationID,
            deploymentID: a.deploymentID,
            workloadID: a.workloadID,
            imageDigest: "sha256:other",
            runnerID: a.runnerID,
            nodeID: a.nodeID,
            modelID: a.modelID,
            toolOrResourceID: a.toolOrResourceID,
            dataClassification: a.dataClassification,
            resourceLimits: a.resourceLimits,
            computeLimits: a.computeLimits,
            approvalReference: a.approvalReference,
            policyVersion: a.policyVersion,
            policyBundleDigest: a.policyBundleDigest,
            issuedAt: a.issuedAt,
            expiry: a.expiry,
            nonce: a.nonce,
            bindingAlgorithm: a.bindingAlgorithm,
            keyID: a.keyID
        )
        let receipt = AuthorityReceipt(
            receiptID: "rcpt-mismatch",
            fingerprint: a,
            decisionOutcome: "allow",
            obligations: [],
            sealAlgorithm: "ed25519",
            sealValue: "seal",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2099-01-01T00:00:00Z"
        )
        let verifier = StructuralAuthorityVerifier()
        XCTAssertThrowsError(
            try verifier.verify(receipt: receipt, expected: b, at: Date())
        )
    }

    func testIssuerProducesMatchingLease() throws {
        let fp = sampleFingerprint()
        let issuer = DefaultAuthorityIssuer()
        let lease = try issuer.issueLease(
            fingerprint: fp,
            nodeID: fp.nodeID,
            modelID: fp.modelID,
            contextLimit: 8192,
            outputLimit: 2048,
            concurrencyLimit: 1,
            budget: nil,
            sealAlgorithm: "ed25519",
            sealValue: "seal",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2026-08-08T00:30:00Z"
        )
        XCTAssertEqual(lease.fingerprint, fp)
        XCTAssertEqual(lease.nodeID, fp.nodeID)
    }

    // MARK: - Fixture

    private func sampleFingerprint() -> AuthorityFingerprint {
        AuthorityFingerprint(
            actorID: "user-001",
            actionID: "inference.generate.local",
            resourceID: "res-001",
            operationID: "op-001",
            deploymentID: "dep-001",
            workloadID: "wl-001",
            imageDigest: "sha256:abc123",
            runnerID: "runner-01",
            nodeID: "node-01",
            modelID: "mlx-model-pinned",
            toolOrResourceID: nil,
            dataClassification: "internal",
            resourceLimits: ["cpu": "2", "mem": "4Gi"],
            computeLimits: ["tokens": "2048"],
            approvalReference: "appr-001",
            policyVersion: "1.1-proposed",
            policyBundleDigest: "sha256:policybundle",
            issuedAt: "2026-08-08T00:00:00Z",
            expiry: "2026-08-08T01:00:00Z",
            nonce: "nonce-001",
            bindingAlgorithm: "ed25519",
            keyID: "key-01"
        )
    }
}
