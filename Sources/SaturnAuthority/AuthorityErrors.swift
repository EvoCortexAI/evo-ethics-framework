import Foundation

public enum AuthorityError: Error, Equatable, Sendable {
    case invalidFingerprint(String)
    case expired
    case replayDetected
    case scopeMismatch(String)
    case sealVerificationFailed
    case unsupportedVersion(String)
    case missingRequiredField(String)
}
