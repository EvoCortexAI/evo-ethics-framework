import Foundation

/// Deterministic JSON serialization for authority types.
/// Keys are sorted; dates remain ISO-8601 strings as stored.
public enum CanonicalSerialization {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }

    /// Stable UTF-8 string form used for hashing / comparison in tests and PEPs.
    public static func canonicalString<T: Encodable>(_ value: T) throws -> String {
        let data = try encode(value)
        guard let s = String(data: data, encoding: .utf8) else {
            throw AuthorityError.invalidFingerprint("unable to produce UTF-8 canonical string")
        }
        return s
    }
}
