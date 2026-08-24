import Foundation

public enum JSONValue: Equatable, Sendable, Decodable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public static func decode(_ source: String) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: Data(source.utf8))
    }
}

public struct ValidationFailure: Error, Equatable, Sendable, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}

public struct JSONSchemaSubsetValidator: Sendable {
    public init(schema: JSONValue) throws {}

    public func validateSchemaDefinition() throws {
        throw ValidationFailure("not implemented")
    }

    public func validate(_ instance: JSONValue, label: String = "instance") throws {
        throw ValidationFailure("not implemented")
    }
}

public struct RepositoryValidationReport: Equatable, Sendable {
    public let schemaCount: Int
    public let actionCount: Int
    public let controlCount: Int
    public let requestExampleCount: Int
    public let decisionExampleCount: Int
    public let vectorCount: Int
}

public struct RepositoryValidator: Sendable {
    public init(root: URL) {}

    public func validate() throws -> RepositoryValidationReport {
        throw ValidationFailure("not implemented")
    }
}

public struct ConformanceReport: Equatable, Sendable {
    public let vectorCount: Int
}

public struct ConformanceRunner: Sendable {
    public init(root: URL) {}

    public func run() throws -> ConformanceReport {
        throw ValidationFailure("not implemented")
    }
}
