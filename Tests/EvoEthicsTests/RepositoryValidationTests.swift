import CoreFoundation
import Foundation
import XCTest
@testable import EvoEthics

final class RepositoryValidationTests: XCTestCase {
    func testRepositoryArtifactsValidate() throws {
        let root = try repositoryRoot()
        let spec = root.appendingPathComponent("spec/v1", isDirectory: true)
        let schemaURLs = try directoryFiles(spec) { $0.lastPathComponent.hasSuffix(".schema.json") }
        XCTAssertFalse(schemaURLs.isEmpty)

        var schemas = [String: [String: Any]]()
        for url in schemaURLs {
            schemas[url.lastPathComponent] = try loadJSONObject(url)
        }

        let validator = RestrictedJSONSchemaValidator(schemas: schemas)
        for url in schemaURLs {
            guard let value = schemas[url.lastPathComponent] else {
                throw ValidationFailure("Missing loaded schema: \(url.lastPathComponent)")
            }
            try validator.checkSchema(value, label: relative(url, root: root))
        }

        let requestSchema = try schema("evaluation-request.schema.json", in: schemas)
        let decisionSchema = try schema("evaluation-decision.schema.json", in: schemas)
        let policySchema = try schema("policy-bundle.schema.json", in: schemas)
        let vectorSchema = try schema("conformance-vector.schema.json", in: schemas)
        let catalogSchema = try schema("control-catalog.schema.json", in: schemas)

        let policyURL = root.appendingPathComponent("policy/development-policy.json")
        let policy = try loadJSONObject(policyURL)
        try validator.validate(policy, against: policySchema, label: relative(policyURL, root: root))
        let actions = try objects(policy["actions"], label: "policy actions")
        try assertUnique(
            try actions.map { try string($0["id"], label: "action id") },
            label: "action IDs"
        )

        let bundledPolicyURL = root.appendingPathComponent(
            "Sources/EvoEthics/Resources/development-policy.json"
        )
        XCTAssertEqual(
            try canonicalJSON(policy),
            try canonicalJSON(loadJSONObject(bundledPolicyURL)),
            "The SDK development policy and policy/development-policy.json differ"
        )

        let catalogURL = root.appendingPathComponent("policy/control-catalog.yaml")
        let catalog = try RestrictedCatalogYAML.parse(
            String(contentsOf: catalogURL, encoding: .utf8)
        )
        try validator.validate(catalog, against: catalogSchema, label: relative(catalogURL, root: root))
        let controls = try objects(catalog["controls"], label: "catalog controls")
        let controlIDs = try controls.map { try string($0["id"], label: "control id") }
        try assertUnique(controlIDs, label: "control IDs")

        let controlIDPattern = try NSRegularExpression(pattern: "^EC-[A-Z0-9]+-[0-9]{3}$")
        let allowedPrinciples = try catalogPrinciples(from: catalogSchema)
        for control in controls {
            let id = try string(control["id"], label: "control id")
            guard regexMatches(controlIDPattern, id) else {
                throw ValidationFailure("Invalid control ID: \(id)")
            }
            let unknown = Set(try strings(control["principles"], label: "\(id) principles"))
                .subtracting(allowedPrinciples)
            guard unknown.isEmpty else {
                throw ValidationFailure("\(id) references unknown principles: \(unknown.sorted())")
            }
        }

        let examples = root.appendingPathComponent("examples", isDirectory: true)
        let requestExamples = try directoryFiles(examples) {
            $0.lastPathComponent.hasSuffix(".request.json")
        }
        let decisionExamples = try directoryFiles(examples) {
            $0.lastPathComponent.hasSuffix(".decision.json")
        }
        XCTAssertFalse(requestExamples.isEmpty)
        XCTAssertFalse(decisionExamples.isEmpty)
        for url in requestExamples {
            try validator.validate(
                try loadJSON(url),
                against: requestSchema,
                label: relative(url, root: root)
            )
        }
        for url in decisionExamples {
            try validator.validate(
                try loadJSON(url),
                against: decisionSchema,
                label: relative(url, root: root)
            )
        }

        let vectors = try vectorURLs(root: root)
        XCTAssertFalse(vectors.isEmpty)
        for url in vectors {
            let value = try loadJSONObject(url)
            let label = relative(url, root: root)
            try validator.validate(value, against: vectorSchema, label: label)
            guard let request = value["request"] else {
                throw ValidationFailure("\(label): missing request")
            }
            try validator.validate(request, against: requestSchema, label: "\(label) request")

            let expected = try object(value["expected"], label: "\(label) expected")
            var referenced = try strings(
                expected["required_controls"],
                label: "\(label) required_controls"
            )
            if let forbidden = expected["forbidden_controls"] {
                referenced += try strings(forbidden, label: "\(label) forbidden_controls")
            }
            let unknown = Set(referenced).subtracting(controlIDs)
            guard unknown.isEmpty else {
                throw ValidationFailure("\(label) references unknown controls: \(unknown.sorted())")
            }
        }

        let openAPIURL = spec.appendingPathComponent("openapi.yaml")
        let openAPI = try OpenAPIInspection.parse(
            String(contentsOf: openAPIURL, encoding: .utf8)
        )
        XCTAssertEqual(openAPI.version, "3.1.0")
        XCTAssertEqual(openAPI.paths, ["/v1/evaluations", "/v1/policy/manifest", "/v1/health"])
        let mutationMethods: Set<String> = ["put", "patch", "delete"]
        XCTAssertTrue(Set(openAPI.methods.values.flatMap { $0 }).isDisjoint(with: mutationMethods))

        let ethicsURL = root.appendingPathComponent("docs/ETHICS-RULES.md")
        let ethics = try String(contentsOf: ethicsURL, encoding: .utf8)
        XCTAssertEqual(
            try ethicsHeadingPrinciples(in: ethics),
            try declaredEthicsPrinciples(in: ethics),
            "ETHICS-RULES.md headings differ from its declared stable principle range"
        )
    }

    func testConformanceVectorsAgainstReferenceEvaluator() throws {
        let root = try repositoryRoot()
        let policy = try PolicyBundleLoader.decode(
            url: root.appendingPathComponent("policy/development-policy.json")
        )
        let evaluator = ReferenceEthicsEvaluator(policy: policy)
        let decisionSchema = try loadJSONObject(
            root.appendingPathComponent("spec/v1/evaluation-decision.schema.json")
        )
        let validator = RestrictedJSONSchemaValidator(
            schemas: ["evaluation-decision.schema.json": decisionSchema]
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        let vectors = try vectorURLs(root: root)
        XCTAssertFalse(vectors.isEmpty)
        for url in vectors {
            let vector = try decoder.decode(ConformanceVector.self, from: Data(contentsOf: url))
            let decision = evaluator.evaluate(vector.request)
            XCTAssertEqual(decision.decision, vector.expected.decision, url.lastPathComponent)

            let actual = Set(decision.controls)
            XCTAssertTrue(
                Set(vector.expected.requiredControls).isSubset(of: actual),
                url.lastPathComponent
            )
            XCTAssertTrue(
                Set(vector.expected.forbiddenControls ?? []).isDisjoint(with: actual),
                url.lastPathComponent
            )

            let encoded = try encoder.encode(decision)
            let output = try JSONSerialization.jsonObject(with: encoded, options: [.fragmentsAllowed])
            try validator.validate(
                output,
                against: decisionSchema,
                label: "\(url.lastPathComponent) evaluator decision"
            )
        }
    }

    func testRestrictedValidatorSupportsNumericTypesAndBounds() throws {
        let schema: [String: Any] = [
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "type": "object",
            "additionalProperties": false,
            "required": ["count", "ratio"],
            "properties": [
                "count": ["type": "integer", "minimum": 1],
                "ratio": ["type": "number", "minimum": 0, "maximum": 1],
            ],
        ]
        let validator = RestrictedJSONSchemaValidator(schemas: [:])
        try validator.checkSchema(schema, label: "numeric-test")
        try validator.validate(
            ["count": 2, "ratio": 0.5],
            against: schema,
            label: "numeric-test valid"
        )

        XCTAssertThrowsError(
            try validator.validate(
                ["count": 0, "ratio": 0.5],
                against: schema,
                label: "numeric-test minimum"
            )
        )
        XCTAssertThrowsError(
            try validator.validate(
                ["count": 1.5, "ratio": 0.5],
                against: schema,
                label: "numeric-test integer"
            )
        )
        XCTAssertThrowsError(
            try validator.validate(
                ["count": 2, "ratio": true],
                against: schema,
                label: "numeric-test boolean"
            )
        )
    }

    private func repositoryRoot() throws -> URL {
        var candidate = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while candidate.path != "/" {
            let package = candidate.appendingPathComponent("Package.swift")
            let spec = candidate.appendingPathComponent("spec/v1", isDirectory: true)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: package.path),
               FileManager.default.fileExists(atPath: spec.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }
        throw ValidationFailure("Unable to locate repository root from #filePath")
    }

    private func vectorURLs(root: URL) throws -> [URL] {
        try directoryFiles(root.appendingPathComponent("conformance/vectors", isDirectory: true)) {
            $0.pathExtension == "json"
        }
    }

    private func directoryFiles(
        _ directory: URL,
        where predicate: (URL) -> Bool
    ) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter(predicate)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func relative(_ url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else { return path }
        return String(path.dropFirst(rootPath.count + 1))
    }
}

private struct ConformanceVector: Decodable {
    struct Expected: Decodable {
        let decision: DecisionOutcome
        let requiredControls: [String]
        let forbiddenControls: [String]?
    }

    let name: String
    let request: EvaluationRequest
    let expected: Expected
}

private struct ValidationFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

private struct ResolvedSchema {
    let schema: [String: Any]
    let root: [String: Any]
}

/// Deliberately implements only the JSON Schema 2020-12 vocabulary used by spec/v1.
/// Unknown keywords fail schema validation so the supported subset cannot silently weaken.
private struct RestrictedJSONSchemaValidator {
    private let schemas: [String: [String: Any]]
    private let keywords: Set<String> = [
        "$schema", "$id", "$ref", "$defs", "title", "description", "type",
        "additionalProperties", "required", "properties", "const", "enum",
        "minLength", "maxLength", "pattern", "format", "items", "minItems",
        "maxItems", "uniqueItems", "minimum", "maximum",
    ]

    init(schemas: [String: [String: Any]]) {
        self.schemas = schemas
    }

    func checkSchema(_ schema: [String: Any], label: String) throws {
        guard schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema" else {
            throw ValidationFailure("\(label): expected JSON Schema Draft 2020-12")
        }
        try checkNode(schema, path: label)
    }

    func validate(_ value: Any, against schema: [String: Any], label: String) throws {
        try validateNode(value, schema: schema, root: schema, path: label)
    }

    private func checkNode(_ schema: [String: Any], path: String) throws {
        let unknown = Set(schema.keys).subtracting(keywords)
        guard unknown.isEmpty else {
            throw ValidationFailure("\(path): unsupported schema keywords \(unknown.sorted())")
        }

        if let rawRef = schema["$ref"] {
            let ref = try string(rawRef, label: "\(path).$ref")
            try checkReference(ref, path: path)
        }

        if let rawType = schema["type"] {
            let types = try schemaTypes(rawType, label: "\(path).type")
            let supported: Set<String> = [
                "object", "array", "string", "boolean", "null", "number", "integer",
            ]
            let unsupported = Set(types).subtracting(supported)
            guard unsupported.isEmpty else {
                throw ValidationFailure("\(path): unsupported schema types \(unsupported.sorted())")
            }
        }

        if let value = schema["additionalProperties"] {
            if value is Bool {
                // Supported boolean form.
            } else {
                try checkNode(
                    try object(value, label: "\(path).additionalProperties"),
                    path: "\(path).additionalProperties"
                )
            }
        }

        if let value = schema["required"] {
            _ = try strings(value, label: "\(path).required")
        }
        if let value = schema["properties"] {
            for (name, child) in try object(value, label: "\(path).properties") {
                try checkNode(
                    try object(child, label: "\(path).properties.\(name)"),
                    path: "\(path).properties.\(name)"
                )
            }
        }
        if let value = schema["$defs"] {
            for (name, child) in try object(value, label: "\(path).$defs") {
                try checkNode(
                    try object(child, label: "\(path).$defs.\(name)"),
                    path: "\(path).$defs.\(name)"
                )
            }
        }
        if let value = schema["items"] {
            try checkNode(try object(value, label: "\(path).items"), path: "\(path).items")
        }
        if let value = schema["pattern"] {
            _ = try NSRegularExpression(pattern: string(value, label: "\(path).pattern"))
        }
        if let value = schema["format"], try string(value, label: "\(path).format") != "date-time" {
            throw ValidationFailure("\(path): only date-time format is supported")
        }
        for key in ["minLength", "maxLength", "minItems", "maxItems"] where schema[key] != nil {
            guard integer(schema[key]) != nil else {
                throw ValidationFailure("\(path).\(key) must be integer")
            }
        }
        for key in ["minimum", "maximum"] where schema[key] != nil {
            guard jsonNumber(schema[key]) != nil else {
                throw ValidationFailure("\(path).\(key) must be numeric")
            }
        }
        if let value = schema["uniqueItems"], !(value is Bool) {
            throw ValidationFailure("\(path).uniqueItems must be boolean")
        }
    }

    private func validateNode(
        _ value: Any,
        schema: [String: Any],
        root: [String: Any],
        path: String
    ) throws {
        if let ref = schema["$ref"] as? String {
            let resolved = try resolve(ref, root: root, path: path)
            try validateNode(
                value,
                schema: resolved.schema,
                root: resolved.root,
                path: path
            )
            return
        }

        if let rawType = schema["type"] {
            let types = try schemaTypes(rawType, label: "\(path) schema type")
            guard types.contains(where: { matchesType(value, $0) }) else {
                throw ValidationFailure("\(path): expected \(types), got \(typeName(value))")
            }
        }
        if let constant = schema["const"], !jsonEqual(value, constant) {
            throw ValidationFailure("\(path): const mismatch")
        }
        if let allowed = schema["enum"] as? [Any],
           !allowed.contains(where: { jsonEqual(value, $0) }) {
            throw ValidationFailure("\(path): value not in enum")
        }

        if let text = value as? String {
            if let min = integer(schema["minLength"]), text.count < min {
                throw ValidationFailure("\(path): shorter than minLength")
            }
            if let max = integer(schema["maxLength"]), text.count > max {
                throw ValidationFailure("\(path): longer than maxLength")
            }
            if let pattern = schema["pattern"] as? String,
               !regexMatches(try NSRegularExpression(pattern: pattern), text) {
                throw ValidationFailure("\(path): pattern mismatch")
            }
            if schema["format"] as? String == "date-time",
               ISO8601DateFormatter().date(from: text) == nil {
                throw ValidationFailure("\(path): invalid date-time")
            }
        }

        if let number = jsonNumber(value) {
            if let minimum = jsonNumber(schema["minimum"]),
               number.doubleValue < minimum.doubleValue {
                throw ValidationFailure("\(path): number below minimum")
            }
            if let maximum = jsonNumber(schema["maximum"]),
               number.doubleValue > maximum.doubleValue {
                throw ValidationFailure("\(path): number above maximum")
            }
        }

        if let dictionary = value as? [String: Any] {
            let properties = (schema["properties"] as? [String: Any]) ?? [:]
            if let required = schema["required"] {
                for key in try strings(required, label: "\(path) required") where dictionary[key] == nil {
                    throw ValidationFailure("\(path): missing required property \(key)")
                }
            }

            let additional = schema["additionalProperties"]
            if additional as? Bool == false {
                let unknown = Set(dictionary.keys).subtracting(properties.keys)
                guard unknown.isEmpty else {
                    throw ValidationFailure("\(path): unexpected properties \(unknown.sorted())")
                }
            }

            for (key, child) in dictionary {
                if let childSchema = properties[key] {
                    try validateNode(
                        child,
                        schema: try object(childSchema, label: "\(path).\(key) schema"),
                        root: root,
                        path: "\(path).\(key)"
                    )
                } else if let additional, !(additional is Bool) {
                    try validateNode(
                        child,
                        schema: try object(additional, label: "\(path).additionalProperties schema"),
                        root: root,
                        path: "\(path).\(key)"
                    )
                }
            }
        }

        if let array = value as? [Any] {
            if let min = integer(schema["minItems"]), array.count < min {
                throw ValidationFailure("\(path): fewer than minItems")
            }
            if let max = integer(schema["maxItems"]), array.count > max {
                throw ValidationFailure("\(path): more than maxItems")
            }
            if schema["uniqueItems"] as? Bool == true {
                let encoded = try array.map(canonicalJSON)
                guard Set(encoded).count == encoded.count else {
                    throw ValidationFailure("\(path): duplicate array items")
                }
            }
            if let itemSchema = schema["items"] {
                let schemaObject = try object(itemSchema, label: "\(path) item schema")
                for (index, item) in array.enumerated() {
                    try validateNode(
                        item,
                        schema: schemaObject,
                        root: root,
                        path: "\(path)[\(index)]"
                    )
                }
            }
        }
    }

    private func checkReference(_ ref: String, path: String) throws {
        if ref.hasPrefix("#/") {
            return
        }
        let targetName = externalReferenceName(ref)
        guard !targetName.isEmpty, schemas[targetName] != nil else {
            throw ValidationFailure("\(path): unsupported or unresolved $ref \(ref)")
        }
    }

    private func resolve(
        _ ref: String,
        root: [String: Any],
        path: String
    ) throws -> ResolvedSchema {
        if ref.hasPrefix("#/") {
            return ResolvedSchema(
                schema: try resolvePointer(String(ref.dropFirst(1)), in: root, path: path, ref: ref),
                root: root
            )
        }

        let targetName = externalReferenceName(ref)
        guard let targetRoot = schemas[targetName] else {
            throw ValidationFailure("\(path): unresolved $ref \(ref)")
        }
        guard let hashIndex = ref.firstIndex(of: "#") else {
            return ResolvedSchema(schema: targetRoot, root: targetRoot)
        }
        let fragment = String(ref[ref.index(after: hashIndex)...])
        if fragment.isEmpty {
            return ResolvedSchema(schema: targetRoot, root: targetRoot)
        }
        guard fragment.hasPrefix("/") else {
            throw ValidationFailure("\(path): unsupported $ref fragment \(ref)")
        }
        return ResolvedSchema(
            schema: try resolvePointer(fragment, in: targetRoot, path: path, ref: ref),
            root: targetRoot
        )
    }

    private func resolvePointer(
        _ pointer: String,
        in root: [String: Any],
        path: String,
        ref: String
    ) throws -> [String: Any] {
        guard pointer.hasPrefix("/") else {
            throw ValidationFailure("\(path): unsupported $ref \(ref)")
        }
        var current: Any = root
        for rawComponent in pointer.dropFirst().split(separator: "/", omittingEmptySubsequences: false) {
            let component = String(rawComponent)
                .replacingOccurrences(of: "~1", with: "/")
                .replacingOccurrences(of: "~0", with: "~")
            let dictionary = try object(current, label: "\(path) $ref")
            guard let next = dictionary[component] else {
                throw ValidationFailure("\(path): unresolved $ref \(ref)")
            }
            current = next
        }
        return try object(current, label: "\(path) resolved $ref")
    }

    private func externalReferenceName(_ ref: String) -> String {
        let filePart = ref.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? ""
        if filePart.hasPrefix("./") {
            return String(filePart.dropFirst(2))
        }
        return filePart
    }

    private func schemaTypes(_ value: Any, label: String) throws -> [String] {
        if let single = value as? String {
            return [single]
        }
        return try strings(value, label: label)
    }
}

private enum RestrictedCatalogYAML {
    static func parse(_ text: String) throws -> [String: Any] {
        var result = [String: Any]()
        var controls = [[String: Any]]()
        var current: [String: Any]?
        var inControls = false

        func flush() {
            if let current { controls.append(current) }
            current = nil
        }

        for (index, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = String(raw)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            if line == "controls:" { flush(); inControls = true; continue }
            if inControls && line.hasPrefix("  - ") {
                flush()
                let pair = try pair(String(line.dropFirst(4)), line: index + 1)
                current = [pair.0: pair.1]
                continue
            }
            if inControls && line.hasPrefix("    ") {
                guard current != nil else {
                    throw ValidationFailure("control-catalog.yaml:\(index + 1): field without item")
                }
                let entry = try pair(String(line.dropFirst(4)), line: index + 1)
                current?[entry.0] = entry.1
                continue
            }
            if !inControls && !line.hasPrefix(" ") {
                let entry = try pair(line, line: index + 1)
                result[entry.0] = entry.1
                continue
            }
            throw ValidationFailure("control-catalog.yaml:\(index + 1): unsupported YAML structure")
        }
        flush()
        result["controls"] = controls
        return result
    }

    private static func pair(_ text: String, line: Int) throws -> (String, Any) {
        guard let colon = text.firstIndex(of: ":") else {
            throw ValidationFailure("control-catalog.yaml:\(line): expected key: value")
        }
        let key = String(text[..<colon]).trimmingCharacters(in: .whitespaces)
        let raw = String(text[text.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !raw.isEmpty else {
            throw ValidationFailure("control-catalog.yaml:\(line): empty key/value")
        }
        return (key, scalar(raw))
    }

    private static func scalar(_ raw: String) -> Any {
        if raw.hasPrefix("[") && raw.hasSuffix("]") {
            let body = String(raw.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            if body.isEmpty { return [String]() }
            return body.split(separator: ",").map {
                strip(String($0).trimmingCharacters(in: .whitespaces))
            }
        }
        if raw == "true" { return true }
        if raw == "false" { return false }
        if raw == "null" { return NSNull() }
        return strip(raw)
    }

    private static func strip(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.hasPrefix("\"") && value.hasSuffix("\""))
            || (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}

private struct OpenAPIInspection {
    let version: String
    let methods: [String: Set<String>]
    var paths: Set<String> { Set(methods.keys) }

    static func parse(_ text: String) throws -> Self {
        var version: String?
        var methods = [String: Set<String>]()
        var inPaths = false
        var currentPath: String?
        let httpMethods: Set<String> = [
            "get", "post", "put", "patch", "delete", "head", "options", "trace",
        ]

        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let indent = line.prefix { $0 == " " }.count

            if indent == 0 && trimmed.hasPrefix("openapi:") {
                version = String(trimmed.dropFirst("openapi:".count))
                    .trimmingCharacters(in: .whitespaces)
                continue
            }
            if indent == 0 && trimmed == "paths:" {
                inPaths = true
                currentPath = nil
                continue
            }
            if inPaths && indent == 0 {
                inPaths = false
                currentPath = nil
            }
            guard inPaths else { continue }

            if indent == 2 && trimmed.hasPrefix("/") && trimmed.hasSuffix(":") {
                let path = String(trimmed.dropLast())
                currentPath = path
                methods[path, default: []] = []
            } else if indent == 4, let path = currentPath, trimmed.hasSuffix(":") {
                let method = String(trimmed.dropLast()).lowercased()
                if httpMethods.contains(method) {
                    methods[path, default: []].insert(method)
                }
            }
        }
        guard let version else { throw ValidationFailure("openapi.yaml: missing version") }
        return Self(version: version, methods: methods)
    }
}

private func loadJSON(_ url: URL) throws -> Any {
    try JSONSerialization.jsonObject(with: Data(contentsOf: url), options: [.fragmentsAllowed])
}

private func loadJSONObject(_ url: URL) throws -> [String: Any] {
    try object(loadJSON(url), label: url.path)
}

private func schema(
    _ name: String,
    in schemas: [String: [String: Any]]
) throws -> [String: Any] {
    guard let value = schemas[name] else {
        throw ValidationFailure("Missing schema: \(name)")
    }
    return value
}

private func object(_ value: Any?, label: String) throws -> [String: Any] {
    guard let value, let result = value as? [String: Any] else {
        throw ValidationFailure("\(label): expected object")
    }
    return result
}

private func objects(_ value: Any?, label: String) throws -> [[String: Any]] {
    guard let value, let array = value as? [Any] else {
        throw ValidationFailure("\(label): expected array")
    }
    return try array.enumerated().map {
        try object($0.element, label: "\(label)[\($0.offset)]")
    }
}

private func string(_ value: Any?, label: String) throws -> String {
    guard let result = value as? String else {
        throw ValidationFailure("\(label): expected string")
    }
    return result
}

private func strings(_ value: Any?, label: String) throws -> [String] {
    guard let value, let array = value as? [Any] else {
        throw ValidationFailure("\(label): expected string array")
    }
    return try array.enumerated().map {
        try string($0.element, label: "\(label)[\($0.offset)]")
    }
}

private func assertUnique(_ values: [String], label: String) throws {
    var seen = Set<String>()
    var duplicates = Set<String>()
    for value in values where !seen.insert(value).inserted {
        duplicates.insert(value)
    }
    guard duplicates.isEmpty else {
        throw ValidationFailure("Duplicate \(label): \(duplicates.sorted())")
    }
}

private func catalogPrinciples(from schema: [String: Any]) throws -> Set<String> {
    let root = try object(schema["properties"], label: "catalog properties")
    let controls = try object(root["controls"], label: "controls schema")
    let item = try object(controls["items"], label: "control item")
    let properties = try object(item["properties"], label: "control properties")
    let principles = try object(properties["principles"], label: "principles schema")
    let principle = try object(principles["items"], label: "principle item")
    return Set(try strings(principle["enum"], label: "principle enum"))
}

private func declaredEthicsPrinciples(in text: String) throws -> Set<String> {
    let regex = try NSRegularExpression(
        pattern: #"stable identifiers `E1` through `E([0-9]+)`"#
    )
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          let capture = Range(match.range(at: 1), in: text),
          let upper = Int(text[capture]),
          upper > 0 else {
        throw ValidationFailure("ETHICS-RULES.md: missing stable E1-through-EN declaration")
    }
    return Set((1...upper).map { "E\($0)" })
}

private func ethicsHeadingPrinciples(in text: String) throws -> Set<String> {
    let regex = try NSRegularExpression(pattern: #"(?m)^### (E[0-9]+)\."#)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return Set(regex.matches(in: text, range: range).compactMap {
        guard let capture = Range($0.range(at: 1), in: text) else { return nil }
        return String(text[capture])
    })
}

private func regexMatches(_ regex: NSRegularExpression, _ value: String) -> Bool {
    regex.firstMatch(
        in: value,
        range: NSRange(value.startIndex..<value.endIndex, in: value)
    ) != nil
}

private func integer(_ value: Any?) -> Int? {
    guard let number = jsonNumber(value) else { return nil }
    let doubleValue = number.doubleValue
    guard doubleValue.isFinite,
          doubleValue.rounded(.towardZero) == doubleValue,
          doubleValue >= Double(Int.min),
          doubleValue <= Double(Int.max) else {
        return nil
    }
    return Int(doubleValue)
}

private func jsonNumber(_ value: Any?) -> NSNumber? {
    guard let value, let number = value as? NSNumber, !isJSONBoolean(number) else {
        return nil
    }
    return number
}

private func isJSONBoolean(_ value: Any) -> Bool {
    guard let number = value as? NSNumber else { return false }
    return CFGetTypeID(number) == CFBooleanGetTypeID()
}

private func matchesType(_ value: Any, _ type: String) -> Bool {
    switch type {
    case "object": return value is [String: Any]
    case "array": return value is [Any]
    case "string": return value is String
    case "boolean": return isJSONBoolean(value)
    case "null": return value is NSNull
    case "number": return jsonNumber(value) != nil
    case "integer": return integer(value) != nil
    default: return false
    }
}

private func typeName(_ value: Any) -> String {
    if value is [String: Any] { return "object" }
    if value is [Any] { return "array" }
    if value is String { return "string" }
    if isJSONBoolean(value) { return "boolean" }
    if value is NSNull { return "null" }
    if integer(value) != nil { return "integer" }
    if jsonNumber(value) != nil { return "number" }
    return "other"
}

private func jsonEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if lhs is NSNull || rhs is NSNull {
        return lhs is NSNull && rhs is NSNull
    }
    if isJSONBoolean(lhs) || isJSONBoolean(rhs) {
        guard isJSONBoolean(lhs), isJSONBoolean(rhs),
              let left = lhs as? NSNumber,
              let right = rhs as? NSNumber else {
            return false
        }
        return left.boolValue == right.boolValue
    }
    if let left = lhs as? String, let right = rhs as? String {
        return left == right
    }
    if let left = jsonNumber(lhs), let right = jsonNumber(rhs) {
        return left.compare(right) == .orderedSame
    }
    return (try? canonicalJSON(lhs)) == (try? canonicalJSON(rhs))
}

private func canonicalJSON(_ value: Any) throws -> String {
    let data = try JSONSerialization.data(
        withJSONObject: value,
        options: [.sortedKeys, .fragmentsAllowed]
    )
    guard let result = String(data: data, encoding: .utf8) else {
        throw ValidationFailure("Unable to encode canonical JSON")
    }
    return result
}
