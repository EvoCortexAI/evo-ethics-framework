import Foundation

/// Fail-closed authority errors. PEPs must never coerce or silently downgrade.
public enum AuthorityError: Error, Equatable, Sendable {
    case invalidFingerprint(String)
    case expired
    case replayDetected
    case scopeMismatch(String)
    case sealVerificationFailed
    case unsupportedVersion(String)
    case missingRequiredField(String)
    case policyDowngrade(String)
    case revoked
}
