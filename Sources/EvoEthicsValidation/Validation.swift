import EvoEthics
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

    static func decode(contentsOf url: URL) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: Data(contentsOf: url))
    }

    func object(at path: String) throws -> [String: JSONValue] {
        guard case let .object(value) = self else {
            throw ValidationFailure("\(path): expected object")
        }
        return value
    }

    func array(at path: String) throws -> [JSONValue] {
        guard case let .array(value) = self else {
            throw ValidationFailure("\(path): expected array")
        }
        return value
    }

    func string(at path: String) throws -> String {
        guard case let .string(value) = self else {
            throw ValidationFailure("\(path): expected string")
        }
        return value
    }
}

public struct ValidationFailure: Error, Equatable, Sendable, LocalizedError,
    CustomStringConvertible
{
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
    public var errorDescription: String? { message }
}

public struct JSONSchemaSubsetValidator: Sendable {
    private static let allowedKeywords: Set<String> = [
        "$schema", "$id", "$defs", "$ref", "title", "description", "type",
        "additionalProperties", "required", "properties", "const", "enum",
        "minLength", "maxLength", "pattern", "format", "minItems", "maxItems",
        "uniqueItems", "items", "minimum", "maximum",
    ]
    private static let allowedTypes: Set<String> = [
        "object", "array", "string", "number", "integer", "boolean", "null",
    ]

    private let schema: JSONValue
    private let externalSchemas: [String: JSONValue]

    public init(
        schema: JSONValue,
        externalSchemas: [String: JSONValue] = [:]
    ) throws {
        guard case .object = schema else {
            throw ValidationFailure("schema: expected object")
        }
        self.schema = schema
        self.externalSchemas = externalSchemas
    }

    public func validateSchemaDefinition() throws {
        try validateSchemaNode(schema, path: "schema", documentRoot: schema)
    }

    public func validate(_ instance: JSONValue, label: String = "instance") throws {
        try validateSchemaDefinition()
        try validate(instance, against: schema, documentRoot: schema, path: label)
    }

    private func validateSchemaNode(
        _ node: JSONValue,
        path: String,
        documentRoot: JSONValue
    ) throws {
        let object = try node.object(at: path)
        if let unsupported = object.keys.sorted().first(where: {
            !Self.allowedKeywords.contains($0)
        }) {
            throw ValidationFailure("\(path): unsupported schema keyword '\(unsupported)'")
        }

        if let type = object["type"] {
            let types = try schemaTypes(type, path: "\(path).type")
            if types.isEmpty {
                throw ValidationFailure("\(path).type: type list must not be empty")
            }
            if let unsupported = types.first(where: { !Self.allowedTypes.contains($0) }) {
                throw ValidationFailure("\(path).type: unsupported JSON type '\(unsupported)'")
            }
            if Set(types).count != types.count {
                throw ValidationFailure("\(path).type: types must be unique")
            }
        }

        if let additional = object["additionalProperties"] {
            switch additional {
            case .bool:
                break
            case .object:
                try validateSchemaNode(
                    additional,
                    path: "\(path).additionalProperties",
                    documentRoot: documentRoot
                )
            default:
                throw ValidationFailure(
                    "\(path).additionalProperties: expected boolean or schema"
                )
            }
        }

        if let required = object["required"] {
            let values = try stringArray(required, path: "\(path).required")
            if Set(values).count != values.count {
                throw ValidationFailure("\(path).required: property names must be unique")
            }
        }

        for keyword in ["properties", "$defs"] {
            guard let collection = object[keyword] else { continue }
            let children = try collection.object(at: "\(path).\(keyword)")
            for key in children.keys.sorted() {
                try validateSchemaNode(
                    children[key]!,
                    path: "\(path).\(keyword).\(key)",
                    documentRoot: documentRoot
                )
            }
        }

        if let reference = object["$ref"] {
            let pointer = try reference.string(at: "\(path).$ref")
            _ = try resolve(pointer: pointer, relativeTo: documentRoot)
        }

        if let enumeration = object["enum"] {
            let values = try enumeration.array(at: "\(path).enum")
            if values.isEmpty {
                throw ValidationFailure("\(path).enum: values must not be empty")
            }
            if containsDuplicate(values) {
                throw ValidationFailure("\(path).enum: values must be unique")
            }
        }

        try validateNonnegativeIntegerPair(
            object: object,
            minimumKey: "minLength",
            maximumKey: "maxLength",
            path: path
        )
        let minimum = try numberKeyword(object["minimum"], path: "\(path).minimum")
        let maximum = try numberKeyword(object["maximum"], path: "\(path).maximum")
        if let minimum, let maximum, minimum > maximum {
            throw ValidationFailure("\(path): minimum exceeds maximum")
        }
        try validateNonnegativeIntegerPair(
            object: object,
            minimumKey: "minItems",
            maximumKey: "maxItems",
            path: path
        )

        if let pattern = object["pattern"] {
            let source = try pattern.string(at: "\(path).pattern")
            do {
                _ = try NSRegularExpression(pattern: source)
            } catch {
                throw ValidationFailure("\(path).pattern: invalid regular expression")
            }
        }

        if let format = object["format"] {
            let value = try format.string(at: "\(path).format")
            guard value == "date-time" else {
                throw ValidationFailure("\(path).format: unsupported format '\(value)'")
            }
        }

        if let uniqueItems = object["uniqueItems"], case .bool = uniqueItems {
            // Supported.
        } else if object["uniqueItems"] != nil {
            throw ValidationFailure("\(path).uniqueItems: expected boolean")
        }

        if let items = object["items"] {
            try validateSchemaNode(
                items,
                path: "\(path).items",
                documentRoot: documentRoot
            )
        }
    }

    private func validate(
        _ instance: JSONValue,
        against schemaNode: JSONValue,
        documentRoot: JSONValue,
        path: String
    ) throws {
        let object = try schemaNode.object(at: path)

        if let reference = object["$ref"] {
            let pointer = try reference.string(at: "\(path).$ref")
            let resolved = try resolve(pointer: pointer, relativeTo: documentRoot)
            try validate(
                instance,
                against: resolved.node,
                documentRoot: resolved.documentRoot,
                path: path
            )
        }

        if let type = object["type"] {
            let types = try schemaTypes(type, path: "\(path).type")
            guard types.contains(where: { matches(instance, type: $0) }) else {
                throw ValidationFailure("\(path): expected type \(types.joined(separator: " or "))")
            }
        }

        if let constant = object["const"], instance != constant {
            throw ValidationFailure("\(path): value does not equal schema constant")
        }

        if let enumeration = object["enum"] {
            let values = try enumeration.array(at: "\(path).enum")
            guard values.contains(instance) else {
                throw ValidationFailure("\(path): value is not in the allowed enumeration")
            }
        }

        if case let .string(value) = instance {
            if let minimum = try integerKeyword(object["minLength"], path: "\(path).minLength"),
               value.count < minimum
            {
                throw ValidationFailure("\(path): string is shorter than \(minimum) characters")
            }
            if let maximum = try integerKeyword(object["maxLength"], path: "\(path).maxLength"),
               value.count > maximum
            {
                throw ValidationFailure("\(path): string is longer than \(maximum) characters")
            }
            if let patternValue = object["pattern"] {
                let pattern = try patternValue.string(at: "\(path).pattern")
                let expression = try NSRegularExpression(pattern: pattern)
                let range = NSRange(value.startIndex..<value.endIndex, in: value)
                if expression.firstMatch(in: value, range: range) == nil {
                    throw ValidationFailure("\(path): string does not match pattern '\(pattern)'")
                }
            }
            if let formatValue = object["format"] {
                let format = try formatValue.string(at: "\(path).format")
                if format == "date-time", !isRFC3339DateTime(value) {
                    throw ValidationFailure("\(path): string is not an RFC 3339 date-time")
                }
            }
        }

        if case let .array(values) = instance {
            if let minimum = try integerKeyword(object["minItems"], path: "\(path).minItems"),
               values.count < minimum
            {
                throw ValidationFailure("\(path): array has fewer than \(minimum) items")
            }
            if let maximum = try integerKeyword(object["maxItems"], path: "\(path).maxItems"),
               values.count > maximum
            {
                throw ValidationFailure("\(path): array has more than \(maximum) items")
            }
            if object["uniqueItems"] == .bool(true), containsDuplicate(values) {
                throw ValidationFailure("\(path): array items must be unique")
            }
            if let items = object["items"] {
                for (index, value) in values.enumerated() {
                    try validate(
                        value,
                        against: items,
                        documentRoot: documentRoot,
                        path: "\(path)[\(index)]"
                    )
                }
            }
        }

        if case let .number(value) = instance {
            if let minimum = try numberKeyword(object["minimum"], path: "\(path).minimum"),
               value < minimum
            {
                throw ValidationFailure("\(path): number is less than \(minimum)")
            }
            if let maximum = try numberKeyword(object["maximum"], path: "\(path).maximum"),
               value > maximum
            {
                throw ValidationFailure("\(path): number is greater than \(maximum)")
            }
        }

        if case let .object(values) = instance {
            if let requiredValue = object["required"] {
                for property in try stringArray(requiredValue, path: "\(path).required")
                where values[property] == nil {
                    throw ValidationFailure("\(path): missing required property '\(property)'")
                }
            }

            let properties = try object["properties"]?.object(at: "\(path).properties") ?? [:]
            if object["additionalProperties"] == .bool(false),
               let extra = values.keys.sorted().first(where: { properties[$0] == nil })
            {
                throw ValidationFailure("\(path): additional property '\(extra)' is not allowed")
            }

            if let additionalSchema = object["additionalProperties"],
               case .object = additionalSchema
            {
                for property in values.keys.sorted() where properties[property] == nil {
                    try validate(
                        values[property]!,
                        against: additionalSchema,
                        documentRoot: documentRoot,
                        path: "\(path).\(property)"
                    )
                }
            }

            for property in properties.keys.sorted() {
                if let value = values[property] {
                    try validate(
                        value,
                        against: properties[property]!,
                        documentRoot: documentRoot,
                        path: "\(path).\(property)"
                    )
                }
            }
        }
    }

    private func resolve(
        pointer: String,
        relativeTo documentRoot: JSONValue
    ) throws -> (node: JSONValue, documentRoot: JSONValue) {
        if !pointer.hasPrefix("#/") {
            guard !pointer.contains("/"), !pointer.contains("#"),
                  let external = externalSchemas[pointer]
            else {
                throw ValidationFailure("schema.$ref: unresolved schema '\(pointer)'")
            }
            return (external, external)
        }
        var current = documentRoot
        for rawComponent in pointer.dropFirst(2).split(separator: "/", omittingEmptySubsequences: false) {
            let component = rawComponent
                .replacingOccurrences(of: "~1", with: "/")
                .replacingOccurrences(of: "~0", with: "~")
            let object = try current.object(at: "schema.$ref")
            guard let next = object[component] else {
                throw ValidationFailure("schema.$ref: unresolved pointer '\(pointer)'")
            }
            current = next
        }
        return (current, documentRoot)
    }

    private func schemaTypes(_ value: JSONValue, path: String) throws -> [String] {
        switch value {
        case let .string(type):
            return [type]
        case let .array(values):
            return try values.enumerated().map { index, value in
                try value.string(at: "\(path)[\(index)]")
            }
        default:
            throw ValidationFailure("\(path): expected string or array")
        }
    }

    private func stringArray(_ value: JSONValue, path: String) throws -> [String] {
        try value.array(at: path).enumerated().map { index, value in
            try value.string(at: "\(path)[\(index)]")
        }
    }

    private func validateNonnegativeIntegerPair(
        object: [String: JSONValue],
        minimumKey: String,
        maximumKey: String,
        path: String
    ) throws {
        let minimum = try integerKeyword(object[minimumKey], path: "\(path).\(minimumKey)")
        let maximum = try integerKeyword(object[maximumKey], path: "\(path).\(maximumKey)")
        if let minimum, minimum < 0 {
            throw ValidationFailure("\(path).\(minimumKey): expected nonnegative integer")
        }
        if let maximum, maximum < 0 {
            throw ValidationFailure("\(path).\(maximumKey): expected nonnegative integer")
        }
        if let minimum, let maximum, minimum > maximum {
            throw ValidationFailure("\(path): \(minimumKey) exceeds \(maximumKey)")
        }
    }

    private func integerKeyword(_ value: JSONValue?, path: String) throws -> Int? {
        guard let value else { return nil }
        guard case let .number(number) = value,
              number.isFinite,
              number.rounded(.towardZero) == number,
              number >= Double(Int.min),
              number <= Double(Int.max)
        else {
            throw ValidationFailure("\(path): expected integer")
        }
        return Int(number)
    }

    private func numberKeyword(_ value: JSONValue?, path: String) throws -> Double? {
        guard let value else { return nil }
        guard case let .number(number) = value, number.isFinite else {
            throw ValidationFailure("\(path): expected finite number")
        }
        return number
    }

    private func matches(_ value: JSONValue, type: String) -> Bool {
        switch (value, type) {
        case (.object, "object"), (.array, "array"), (.string, "string"),
             (.number, "number"), (.bool, "boolean"), (.null, "null"):
            true
        case let (.number(number), "integer"):
            number.rounded(.towardZero) == number
        default:
            false
        }
    }

    private func containsDuplicate(_ values: [JSONValue]) -> Bool {
        for index in values.indices {
            if values[values.index(after: index)...].contains(values[index]) {
                return true
            }
        }
        return false
    }

    private func isRFC3339DateTime(_ value: String) -> Bool {
        let pattern = #"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?(?:Z|[+-][0-9]{2}:[0-9]{2})$"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              expression.firstMatch(
                  in: value,
                  range: NSRange(value.startIndex..<value.endIndex, in: value)
              ) != nil
        else {
            return false
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if formatter.date(from: value) != nil {
            return true
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value) != nil
    }
}

public struct RepositoryValidationReport: Equatable, Sendable {
    public let schemaCount: Int
    public let actionCount: Int
    public let controlCount: Int
    public let requestExampleCount: Int
    public let decisionExampleCount: Int
    public let vectorCount: Int

    public var summary: String {
        "Validation passed: \(schemaCount) schemas, \(actionCount) actions, "
            + "\(controlCount) controls, \(requestExampleCount) request examples, "
            + "\(decisionExampleCount) decision examples, \(vectorCount) conformance vectors."
    }
}

public struct RepositoryValidator: Sendable {
    private let root: URL

    public init(root: URL) {
        self.root = root.standardizedFileURL
    }

    public func validate() throws -> RepositoryValidationReport {
        let spec = root.appendingPathComponent("spec/v1", isDirectory: true)
        let schemaFiles = try files(in: spec, suffix: ".schema.json")
        let schemaDocuments = try Dictionary(
            uniqueKeysWithValues: schemaFiles.map { file in
                (file.lastPathComponent, try JSONValue.decode(contentsOf: file))
            }
        )
        var validators: [String: JSONSchemaSubsetValidator] = [:]
        for file in schemaFiles {
            let validator = try JSONSchemaSubsetValidator(
                schema: schemaDocuments[file.lastPathComponent]!,
                externalSchemas: schemaDocuments
            )
            try validator.validateSchemaDefinition()
            validators[file.lastPathComponent] = validator
        }

        let policyURL = root.appendingPathComponent("policy/development-policy.json")
        let policy = try JSONValue.decode(contentsOf: policyURL)
        try validator(named: "policy-bundle.schema.json", in: validators)
            .validate(policy, label: "policy/development-policy.json")
        let actionIDs = try identifiers(
            in: policy,
            collection: "actions",
            label: "policy/development-policy.json"
        )
        try requireUnique(actionIDs, label: "action IDs")

        let bundledPolicy = try JSONValue.decode(
            contentsOf: root.appendingPathComponent(
                "Sources/EvoEthics/Resources/development-policy.json"
            )
        )
        guard bundledPolicy == policy else {
            throw ValidationFailure(
                "The SDK development policy and policy/development-policy.json differ"
            )
        }

        let catalogURL = root.appendingPathComponent("policy/control-catalog.json")
        let catalog = try JSONValue.decode(contentsOf: catalogURL)
        try validator(named: "control-catalog.schema.json", in: validators)
            .validate(catalog, label: "policy/control-catalog.json")
        let controlIDs = try identifiers(
            in: catalog,
            collection: "controls",
            label: "policy/control-catalog.json"
        )
        try requireUnique(controlIDs, label: "control IDs")
        try validateControls(catalog)

        let examples = root.appendingPathComponent("examples", isDirectory: true)
        let requestExamples = try files(in: examples, suffix: ".request.json")
        let decisionExamples = try files(in: examples, suffix: ".decision.json")
        let requestValidator = try validator(
            named: "evaluation-request.schema.json",
            in: validators
        )
        let decisionValidator = try validator(
            named: "evaluation-decision.schema.json",
            in: validators
        )
        for file in requestExamples {
            try requestValidator.validate(
                JSONValue.decode(contentsOf: file),
                label: relativePath(file)
            )
        }
        for file in decisionExamples {
            try decisionValidator.validate(
                JSONValue.decode(contentsOf: file),
                label: relativePath(file)
            )
        }

        let vectorFiles = try files(
            in: root.appendingPathComponent("conformance/vectors", isDirectory: true),
            suffix: ".json"
        )
        let vectorValidator = try validator(
            named: "conformance-vector.schema.json",
            in: validators
        )
        let knownControls = Set(controlIDs)
        for file in vectorFiles {
            let vector = try JSONValue.decode(contentsOf: file)
            let label = relativePath(file)
            try vectorValidator.validate(vector, label: label)
            let vectorObject = try vector.object(at: label)
            guard let request = vectorObject["request"] else {
                throw ValidationFailure("\(label): missing request")
            }
            try requestValidator.validate(request, label: "\(label).request")
            let referencedControls = try expectedControls(in: vector, label: label)
            let unknown = Set(referencedControls).subtracting(knownControls).sorted()
            if !unknown.isEmpty {
                throw ValidationFailure(
                    "\(label) references unknown controls: \(unknown.joined(separator: ", "))"
                )
            }
        }

        try validateOpenAPI(root.appendingPathComponent("spec/v1/openapi.yaml"))
        try validateEthicsHeadings(root.appendingPathComponent("docs/ETHICS-RULES.md"))

        return RepositoryValidationReport(
            schemaCount: schemaFiles.count,
            actionCount: actionIDs.count,
            controlCount: controlIDs.count,
            requestExampleCount: requestExamples.count,
            decisionExampleCount: decisionExamples.count,
            vectorCount: vectorFiles.count
        )
    }

    private func validator(
        named name: String,
        in validators: [String: JSONSchemaSubsetValidator]
    ) throws -> JSONSchemaSubsetValidator {
        guard let validator = validators[name] else {
            throw ValidationFailure("Missing schema: \(name)")
        }
        return validator
    }

    private func files(in directory: URL, suffix: String) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.lastPathComponent.hasSuffix(suffix) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func relativePath(_ url: URL) -> String {
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        return url.path.hasPrefix(rootPath)
            ? String(url.path.dropFirst(rootPath.count))
            : url.path
    }

    private func identifiers(
        in document: JSONValue,
        collection: String,
        label: String
    ) throws -> [String] {
        let object = try document.object(at: label)
        guard let collectionValue = object[collection] else {
            throw ValidationFailure("\(label): missing \(collection)")
        }
        return try collectionValue.array(at: "\(label).\(collection)").enumerated().map {
            index, item in
            let itemObject = try item.object(at: "\(label).\(collection)[\(index)]")
            guard let id = itemObject["id"] else {
                throw ValidationFailure("\(label).\(collection)[\(index)]: missing id")
            }
            return try id.string(at: "\(label).\(collection)[\(index)].id")
        }
    }

    private func requireUnique(_ values: [String], label: String) throws {
        var seen = Set<String>()
        let duplicates = Set(values.filter { !seen.insert($0).inserted }).sorted()
        if !duplicates.isEmpty {
            throw ValidationFailure("Duplicate \(label): \(duplicates.joined(separator: ", "))")
        }
    }

    private func validateControls(_ catalog: JSONValue) throws {
        let object = try catalog.object(at: "policy/control-catalog.json")
        let controls = try object["controls"]?.array(
            at: "policy/control-catalog.json.controls"
        ) ?? []
        let validPrinciples = Set(EthicsPrincipleID.allCases.map(\.rawValue))
        let pattern = try NSRegularExpression(pattern: #"^EC-[A-Z0-9]+-[0-9]{3}$"#)

        for (index, value) in controls.enumerated() {
            let path = "policy/control-catalog.json.controls[\(index)]"
            let control = try value.object(at: path)
            let id = try control["id"]?.string(at: "\(path).id") ?? ""
            let idRange = NSRange(id.startIndex..<id.endIndex, in: id)
            if pattern.firstMatch(in: id, range: idRange) == nil {
                throw ValidationFailure("Invalid control ID: \(id)")
            }
            let principles = try control["principles"]?.array(at: "\(path).principles") ?? []
            let principleIDs = try principles.enumerated().map { principleIndex, principle in
                try principle.string(at: "\(path).principles[\(principleIndex)]")
            }
            let unknown = Set(principleIDs).subtracting(validPrinciples).sorted()
            if !unknown.isEmpty {
                throw ValidationFailure(
                    "\(id) references unknown principles: \(unknown.joined(separator: ", "))"
                )
            }
        }
    }

    private func expectedControls(in vector: JSONValue, label: String) throws -> [String] {
        let vectorObject = try vector.object(at: label)
        guard let expectedValue = vectorObject["expected"] else {
            throw ValidationFailure("\(label): missing expected")
        }
        let expected = try expectedValue.object(at: "\(label).expected")
        var controls: [String] = []
        for key in ["required_controls", "forbidden_controls"] {
            guard let value = expected[key] else { continue }
            controls += try value.array(at: "\(label).expected.\(key)").enumerated().map {
                index, item in
                try item.string(at: "\(label).expected.\(key)[\(index)]")
            }
        }
        return controls
    }

    private func validateOpenAPI(_ url: URL) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        var version: String?
        var inPaths = false
        var currentPath: String?
        var paths = Set<String>()
        var methods: [String: Set<String>] = [:]
        let httpMethods: Set<String> = [
            "get", "post", "put", "patch", "delete", "options", "head", "trace",
        ]

        for (lineNumber, rawLine) in source.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).enumerated() {
            let line = String(rawLine)
            if line.contains("\t") {
                throw ValidationFailure("spec/v1/openapi.yaml:\(lineNumber + 1): tabs are not allowed")
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            let indentation = line.prefix(while: { $0 == " " }).count

            if indentation == 0 {
                if trimmed.hasPrefix("openapi:") {
                    version = trimmed.dropFirst("openapi:".count)
                        .trimmingCharacters(in: .whitespaces)
                }
                if trimmed == "paths:" {
                    inPaths = true
                    currentPath = nil
                } else if inPaths {
                    inPaths = false
                    currentPath = nil
                }
                continue
            }

            guard inPaths else { continue }
            if indentation == 2, trimmed.hasPrefix("/"), trimmed.hasSuffix(":") {
                let path = String(trimmed.dropLast())
                if !paths.insert(path).inserted {
                    throw ValidationFailure("spec/v1/openapi.yaml: duplicate path '\(path)'")
                }
                currentPath = path
                methods[path] = []
            } else if indentation == 4,
                      let currentPath,
                      trimmed.hasSuffix(":")
            {
                let key = String(trimmed.dropLast()).lowercased()
                if httpMethods.contains(key) {
                    methods[currentPath, default: []].insert(key)
                }
            }
        }

        guard version == "3.1.0" else {
            throw ValidationFailure("OpenAPI document must declare 3.1.0")
        }
        let allowedPaths: Set<String> = [
            "/v1/evaluations", "/v1/policy/manifest", "/v1/health",
        ]
        guard paths == allowedPaths else {
            let difference = paths.symmetricDifference(allowedPaths).sorted()
            throw ValidationFailure("Unexpected OpenAPI paths: \(difference.joined(separator: ", "))")
        }
        let mutationMethods: Set<String> = ["put", "patch", "delete"]
        if methods.values.contains(where: { !$0.isDisjoint(with: mutationMethods) }) {
            throw ValidationFailure("The v1 evaluation API must not expose policy mutation")
        }
    }

    private func validateEthicsHeadings(_ url: URL) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        let expected = Set(EthicsPrincipleID.allCases.map(\.rawValue))
        let alternatives = expected.sorted { left, right in
            if left.count != right.count { return left.count > right.count }
            return left < right
        }.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        let expression = try NSRegularExpression(
            pattern: "(?m)^### (\(alternatives))\\."
        )
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        let headings = expression.matches(in: source, range: range).compactMap { match -> String? in
            guard let headingRange = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[headingRange])
        }

        guard Set(headings) == expected, headings.count == expected.count else {
            let label = expected.sorted().joined(separator: ", ")
            throw ValidationFailure(
                "ETHICS-RULES.md principle headings differ from \(label): \(headings.sorted())"
            )
        }
    }
}

public struct ConformanceReport: Equatable, Sendable {
    public let vectorCount: Int

    public var summary: String {
        "Conformance passed: \(vectorCount) vectors."
    }
}

public struct ConformanceRunner: Sendable {
    private struct Vector: Decodable, Sendable {
        struct Expected: Decodable, Sendable {
            let decision: DecisionOutcome
            let requiredControls: [String]
            let forbiddenControls: [String]?
        }

        let name: String
        let request: EvaluationRequest
        let expected: Expected
    }

    private let root: URL

    public init(root: URL) {
        self.root = root.standardizedFileURL
    }

    public func run() throws -> ConformanceReport {
        let policy = try PolicyBundleLoader.decode(
            url: root.appendingPathComponent("policy/development-policy.json")
        )
        let evaluator = ReferenceEthicsEvaluator(policy: policy)
        let decisionSchema = try JSONSchemaSubsetValidator(
            schema: JSONValue.decode(
                contentsOf: root.appendingPathComponent(
                    "spec/v1/evaluation-decision.schema.json"
                )
            )
        )
        let vectorDirectory = root.appendingPathComponent(
            "conformance/vectors",
            isDirectory: true
        )
        let vectorFiles = try FileManager.default.contentsOfDirectory(
            at: vectorDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var failures: [String] = []

        for file in vectorFiles {
            do {
                let vector = try decoder.decode(Vector.self, from: Data(contentsOf: file))
                let decision = evaluator.evaluate(vector.request)
                let decisionValue = try JSONDecoder().decode(
                    JSONValue.self,
                    from: encoder.encode(decision)
                )
                try decisionSchema.validate(
                    decisionValue,
                    label: "\(file.lastPathComponent).decision"
                )

                if decision.decision != vector.expected.decision {
                    failures.append(
                        "\(file.lastPathComponent): expected \(vector.expected.decision.rawValue), "
                            + "got \(decision.decision.rawValue)"
                    )
                }
                let actual = Set(decision.controls)
                let missing = Set(vector.expected.requiredControls).subtracting(actual).sorted()
                let forbidden = Set(vector.expected.forbiddenControls ?? [])
                    .intersection(actual).sorted()
                if !missing.isEmpty {
                    failures.append(
                        "\(file.lastPathComponent): missing controls \(missing.joined(separator: ", "))"
                    )
                }
                if !forbidden.isEmpty {
                    failures.append(
                        "\(file.lastPathComponent): forbidden controls present "
                            + forbidden.joined(separator: ", ")
                    )
                }
            } catch {
                failures.append("\(file.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if !failures.isEmpty {
            throw ValidationFailure(
                "Conformance failed:\n" + failures.map { "  - \($0)" }.joined(separator: "\n")
            )
        }
        return ConformanceReport(vectorCount: vectorFiles.count)
    }
}
