import Foundation
import XCTest
@testable import EvoEthics

final class RepositoryValidationTests: XCTestCase {
    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testRepositoryArtifactsValidate() throws {
        let root = repositoryRoot
        let specDirectory = root.appendingPathComponent("spec/v1", isDirectory: true)
        let schemaURLs = try FileManager.default
            .contentsOfDirectory(at: specDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasSuffix(".schema.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        XCTAssertFalse(schemaURLs.isEmpty, "No JSON Schema documents found in spec/v1")

        let validator = RestrictedJSONSchemaValidator()
        var schemas = [String: [String: Any]]()
        for url in schemaURLs {
            let schema = try loadJSONObject(url)
            try validator.checkSchema(schema, label: relativePath(url, root: root))
            schemas[url.lastPathComponent] = schema
        }

        let requestSchema = try requiredSchema("evaluation-request.schema.json", from: schemas)
        let decisionSchema = try requiredSchema("evaluation-decision.schema.json", from: schemas)
        let policySchema = try requiredSchema("policy-bundle.schema.json", from: schemas)
        let vectorSchema = try requiredSchema("conformance-vector.schema.json", from: schemas)
        let catalogSchema = try requiredSchema("control-catalog.schema.json", from: schemas)

        let policyURL = root.appendingPathComponent("policy/development-policy.json")
        let policy = try loadJSONObject(policyURL)
        try validator.validate(
            policy,
            against: policySchema,
            label: relativePath(policyURL, root: root)
        )

        let actions = try objectArray(policy["actions"], label: "policy actions")
        let actionIDs = try actions.map { action in
            try requiredString(action["id"], label: "policy action id")
        }
        try assertUnique(actionIDs, label: "action IDs")

        let bundledPolicyURL = root.appendingPathComponent(
            "Sources/EvoEthics/Resources/development-policy.json"
        )
        let bundledPolicy = try loadJSONObject(bundledPolicyURL)
        XCTAssertEqual(
            try canonicalJSON(policy),
            try canonicalJSON(bundledPolicy),
            "The SDK development policy and policy/development-policy.json differ"
        )

        let catalogURL = root.appendingPathComponent("policy/control-catalog.yaml")
        let catalog = try RestrictedCatalogYAML.parse(
            String(contentsOf: catalogURL, encoding: .utf8)
        )
        try validator.validate(
            catalog,
            against: catalogSchema,
            label: relativePath(catalogURL, root: root)
        )

        let controls = try objectArray(catalog["controls"], label: "control catalog controls")
        let controlIDs = try controls.map { control in
            try requiredString(control["id"], label: "control id")
        }
        try assertUnique(controlIDs, label: "control IDs")

        let controlPattern = try NSRegularExpression(pattern: "^EC-[A-Z0-9]+-[0-9]{3}$")
        let allowedPrinciples = try catalogPrincipleIDs(from: catalogSchema)
        for control in controls {
            let id = try requiredString(control["id"], label: "control id")
            guard matches(controlPattern, value: id) else {
                throw RepositoryValidationError("Invalid control ID: \(id)")
            }

            let principles = try stringArray(control["principles"], label: "\(id) principles")
            let unknown = Set(principles).subtracting(allowedPrinciples)
            guard unknown.isEmpty else {
                throw RepositoryValidationError(
                    "\(id) references unknown principles: \(unknown.sorted())"
                )
            }
        }

        let exampleDirectory = root.appendingPathComponent("examples", isDirectory: true)
        let exampleURLs = try FileManager.default.contentsOfDirectory(
            at: exampleDirectory,
            includingPropertiesForKeys: nil
        )
        let requestExamples = exampleURLs
            .filter { $0.lastPathComponent.hasSuffix(".request.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let decisionExamples = exampleURLs
            .filter { $0.lastPathComponent.hasSuffix(".decision.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        for url in requestExamples {
            try validator.validate(
                try loadJSON(url),
                against: requestSchema,
                label: relativePath(url, root: root)
            )
        }
        for url in decisionExamples {
            try validator.validate(
                try loadJSON(url),
                against: decisionSchema,
                label: relativePath(url, root: root)
            )
        }

        let vectorURLs = try conformanceVectorURLs(root: root)
        for url in vectorURLs {
            let vector = try loadJSONObject(url)
            let label = relativePath(url, root: root)
            try validator.validate(vector, against: vectorSchema, label: label)

            guard let request = vector["request"] else {
                throw RepositoryValidationError("\(label) is missing request")
            }
            try validator.validate(
                request,
                against: requestSchema,
                label: "\(label) request"
            )

            let expected = try requiredObject(vector["expected"], label: "\(label) expected")
            var referencedControls = try stringArray(
                expected["required_controls"],
                label: "\(label) required_controls"
            )
            if let forbidden = expected["forbidden_controls"] {
                referencedControls.append(
                    contentsOf: try stringArray(
                        forbidden,
                        label: "\(label) forbidden_controls"
                    )
                )
            }
            let unknownControls = Set(referencedControls).subtracting(controlIDs)
            guard unknownControls.isEmpty else {
                throw RepositoryValidationError(
                    "\(label) references unknown controls: \(unknownControls.sorted())"
                )
            }
        }

        let openAPIURL = specDirectory.appendingPathComponent("openapi.yaml")
        let openAPI = try OpenAPIInspection.parse(
            String(contentsOf: openAPIURL, encoding: .utf8)
        )
        XCTAssertEqual(openAPI.version, "3.1.0", "OpenAPI document must declare 3.1.0")

        let allowedPaths: Set<String> = [
            "/v1/evaluations",
            "/v1/policy/manifest",
            "/v1/health",
        ]
        XCTAssertEqual(openAPI.paths, allowedPaths, "Unexpected OpenAPI path set")

        let mutationMethods: Set<String> = ["put", "patch", "delete"]
        let exposedMutationMethods = Set(openAPI.methods.values.flatMap { $0 })
            .intersection(mutationMethods)
        XCTAssertTrue(
            exposedMutationMethods.isEmpty,
            "The v1 evaluation API must not expose policy mutation: \(exposedMutationMethods.sorted())"
        )

        let ethicsURL = root.appendingPathComponent("docs/ETHICS-RULES.md")
        let ethicsText = try String(contentsOf: ethicsURL, encoding: .utf8)
        let declaredPrinciples = try declaredEthicsPrincipleIDs(in: ethicsText)
        let headingPrinciples = try ethicsHeadingPrincipleIDs(in: ethicsText)
        XCTAssertEqual(
            headingPrinciples,
            declaredPrinciples,
            "ETHICS-RULES.md principle headings differ from its declared stable principle range"
        )

        XCTAssertFalse(requestExamples.isEmpty)
        XCTAssertFalse(decisionExamples.isEmpty)
        XCTAssertFalse(vectorURLs.isEmpty)
    }

    func testConformanceVectorsAgainstReferenceEvaluator() throws {
        let root = repositoryRoot
        let policy = try PolicyBundleLoader.decode(
            url: root.appendingPathComponent("policy/development-policy.json")
        )
        let evaluator = ReferenceEthicsEvaluator(policy: policy)
        let decisionSchema = try loadJSONObject(
            root.appendingPathComponent("spec/v1/evaluation-decision.schema.json")
        )
        let validator = RestrictedJSONSchemaValidator()
        let vectors = try conformanceVectorURLs(root: root)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        for url in vectors {
            let vector = try decoder.decode(
                ConformanceVector.self,
                from: Data(contentsOf: url)
            )
            let decision = evaluator.evaluate(vector.request)

            XCTAssertEqual(
                decision.decision,
                vector.expected.decision,
                "\(url.lastPathComponent): decision mismatch"
            )

            let actualControls = Set(decision.controls)
            let missing = Set(vector.expected.requiredControls).subtracting(actualControls)
            let forbidden = Set(vector.expected.forbiddenControls ?? []).intersection(actualControls)
            XCTAssertTrue(
                missing.isEmpty,
                "\(url.lastPathComponent): missing controls \(missing.sorted())"
            )
            XCTAssertTrue(
                forbidden.isEmpty,
                "\(url.lastPathComponent): forbidden controls present \(forbidden.sorted())"
            )

            let encodedDecision = try encoder.encode(decision)
            let decisionJSON = try JSONSerialization.jsonObject(
                with: encodedDecision,
                options: [.fragmentsAllowed]
            )
            try validator.validate(
                decisionJSON,
                against: decisionSchema,
                label: "\(url.lastPathComponent) evaluator decision"
            )
        }

        XCTAssertFalse(vectors.isEmpty)
    }

    private func conformanceVectorURLs(root: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: root.appendingPathComponent("conformance/vectors", isDirectory: true),
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
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

private struct RepositoryValidationError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

private struct RestrictedJSONSchemaValidator {
    private let supportedKeywords: Set<String> = [
        "$schema",
        "$id",
        "$ref",
        "$defs",
        "title",
        "description",
        "type",
        "additionalProperties",
        "required",
        "properties",
        "const",
        "enum",
        "minLength",
        "maxLength",
        "pattern",
        "format",
        "items",
        "minItems",
        "maxItems",
        "uniqueItems",
    ]

    func checkSchema(_ schema: [String: Any], label: String) throws {
        guard schema["$schema"] as? String == "https://json-schema.org/draft/2020-12/schema" else {
            throw RepositoryValidationError(
                "\(label): schema must declare JSON Schema Draft 2020-12"
            )
        }
        try checkSchemaNode(schema, path: label)
    }

    func validate(_ instance: Any, against schema: [String: Any], label: String) throws {
        try validateNode(
            instance,
            schema: schema,
            rootSchema: schema,
            path: label
        )
    }

    private func checkSchemaNode(_ schema: [String: Any], path: String) throws {
        let unknownKeywords = Set(schema.keys).subtracting(supportedKeywords)
        guard unknownKeywords.isEmpty else {
            throw RepositoryValidationError(
                "\(path): unsupported JSON Schema keywords \(unknownKeywords.sorted())"
            )
        }

        if let ref = schema["$ref"] {
            let value = try requiredString(ref, label: "\(path).$ref")
            guard value.hasPrefix("#/$defs/") else {
                throw RepositoryValidationError(
                    "\(path): only local #/$defs references are supported, got \(value)"
                )
            }
        }

        if let type = schema["type"] {
            let values: [String]
            if let single = type as? String {
                values = [single]
            } else {
                values = try stringArray(type, label: "\(path).type")
            }
            let supportedTypes: Set<String> = ["object", "array", "string", "boolean", "null"]
            let unsupported = Set(values).subtracting(supportedTypes)
            guard unsupported.isEmpty else {
                throw RepositoryValidationError(
                    "\(path): unsupported JSON Schema types \(unsupported.sorted())"
                )
            }
        }

        if let additionalProperties = schema["additionalProperties"],
           !(additionalProperties is Bool) {
            throw RepositoryValidationError(
                "\(path).additionalProperties must be boolean in the supported subset"
            )
        }

        if let required = schema["required"] {
            _ = try stringArray(required, label: "\(path).required")
        }

        if let properties = schema["properties"] {
            let object = try requiredObject(properties, label: "\(path).properties")
            for (name, value) in object {
                let child = try requiredObject(value, label: "\(path).properties.\(name)")
                try checkSchemaNode(child, path: "\(path).properties.\(name)")
            }
        }

        if let definitions = schema["$defs"] {
            let object = try requiredObject(definitions, label: "\(path).$defs")
            for (name, value) in object {
                let child = try requiredObject(value, label: "\(path).$defs.\(name)")
                try checkSchemaNode(child, path: "\(path).$defs.\(name)")
            }
        }

        if let items = schema["items"] {
            let child = try requiredObject(items, label: "\(path).items")
            try checkSchemaNode(child, path: "\(path).items")
        }

        if let pattern = schema["pattern"] {
            _ = try NSRegularExpression(
                pattern: requiredString(pattern, label: "\(path).pattern")
            )
        }

        if let format = schema["format"] {
            let value = try requiredString(format, label: "\(path).format")
            guard value == "date-time" else {
                throw RepositoryValidationError(
                    "\(path): unsupported format in constrained validator: \(value)"
                )
            }
        }

        for keyword in ["minLength", "maxLength", "minItems", "maxItems"] {
            if let value = schema[keyword], integer(value) == nil {
                throw RepositoryValidationError("\(path).\(keyword) must be an integer")
            }
        }

        if let uniqueItems = schema["uniqueItems"], !(uniqueItems is Bool) {
            throw RepositoryValidationError("\(path).uniqueItems must be boolean")
        }
    }

    private func validateNode(
        _ instance: Any,
        schema: [String: Any],
        rootSchema: [String: Any],
        path: String
    ) throws {
        if let ref = schema["$ref"] as? String {
            let target = try resolve(ref: ref, in: rootSchema, path: path)
            try validateNode(instance, schema: target, rootSchema: rootSchema, path: path)
            return
        }

        if let type = schema["type"] {
            let allowedTypes: [String]
            if let single = type as? String {
                allowedTypes = [single]
            } else {
                allowedTypes = try stringArray(type, label: "\(path) schema type")
            }
            guard allowedTypes.contains(where: { matchesJSONType(instance, type: $0) }) else {
                throw RepositoryValidationError(
                    "\(path): expected type \(allowedTypes), got \(jsonTypeName(instance))"
                )
            }
        }

        if let constant = schema["const"], !jsonEqual(instance, constant) {
            throw RepositoryValidationError("\(path): value does not match const")
        }

        if let enumeration = schema["enum"] as? [Any],
           !enumeration.contains(where: { jsonEqual(instance, $0) }) {
            throw RepositoryValidationError("\(path): value is not in enum")
        }

        if let string = instance as? String {
            if let minimum = integer(schema["minLength"]), string.count < minimum {
                throw RepositoryValidationError("\(path): string shorter than minLength \(minimum)")
            }
            if let maximum = integer(schema["maxLength"]), string.count > maximum {
                throw RepositoryValidationError("\(path): string longer than maxLength \(maximum)")
            }
            if let pattern = schema["pattern"] as? String {
                let expression = try NSRegularExpression(pattern: pattern)
                guard matches(expression, value: string) else {
                    throw RepositoryValidationError(
                        "\(path): string does not match pattern \(pattern)"
                    )
                }
            }
            if schema["format"] as? String == "date-time" {
                let formatter = ISO8601DateFormatter()
                guard formatter.date(from: string) != nil else {
                    throw RepositoryValidationError("\(path): invalid date-time")
                }
            }
        }

        if let object = instance as? [String: Any] {
            let properties = (schema["properties"] as? [String: Any]) ?? [:]
            if let required = schema["required"] {
                for key in try stringArray(required, label: "\(path) required keys") {
                    guard object[key] != nil else {
                        throw RepositoryValidationError("\(path): missing required property \(key)")
                    }
                }
            }

            if schema["additionalProperties"] as? Bool == false {
                let unknownKeys = Set(object.keys).subtracting(properties.keys)
                guard unknownKeys.isEmpty else {
                    throw RepositoryValidationError(
                        "\(path): unexpected properties \(unknownKeys.sorted())"
                    )
                }
            }

            for (key, childValue) in object {
                guard let rawChildSchema = properties[key] else { continue }
                let childSchema = try requiredObject(
                    rawChildSchema,
                    label: "\(path).\(key) schema"
                )
                try validateNode(
                    childValue,
                    schema: childSchema,
                    rootSchema: rootSchema,
                    path: "\(path).\(key)"
                )
            }
        }

        if let array = instance as? [Any] {
            if let minimum = integer(schema["minItems"]), array.count < minimum {
                throw RepositoryValidationError("\(path): array shorter than minItems \(minimum)")
            }
            if let maximum = integer(schema["maxItems"]), array.count > maximum {
                throw RepositoryValidationError("\(path): array longer than maxItems \(maximum)")
            }
            if schema["uniqueItems"] as? Bool == true {
                let canonicalItems = try array.map(canonicalJSON)
                guard Set(canonicalItems).count == canonicalItems.count else {
                    throw RepositoryValidationError("\(path): array items must be unique")
                }
            }
            if let rawItemSchema = schema["items"] {
                let itemSchema = try requiredObject(rawItemSchema, label: "\(path) item schema")
                for (index, item) in array.enumerated() {
                    try validateNode(
                        item,
                        schema: itemSchema,
                        rootSchema: rootSchema,
                        path: "\(path)[\(index)]"
                    )
                }
            }
        }
    }

    private func resolve(
        ref: String,
        in rootSchema: [String: Any],
        path: String
    ) throws -> [String: Any] {
        guard ref.hasPrefix("#/") else {
            throw RepositoryValidationError("\(path): unsupported $ref \(ref)")
        }
        var current: Any = rootSchema
        for component in ref.dropFirst(2).split(separator: "/") {
            guard let object = current as? [String: Any],
                  let next = object[String(component)] else {
                throw RepositoryValidationError("\(path): unresolved $ref \(ref)")
            }
            current = next
        }
        return try requiredObject(current, label: "\(path) resolved $ref")
    }
}

private enum RestrictedCatalogYAML {
    static func parse(_ text: String) throws -> [String: Any] {
        var result = [String: Any]()
        var controls = [[String: Any]]()
        var currentControl: [String: Any]?
        var inControls = false

        func flushCurrentControl() {
            if let currentControl {
                controls.append(currentControl)
            }
            currentControl = nil
        }

        for (lineNumber, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if line == "controls:" {
                flushCurrentControl()
                inControls = true
                continue
            }

            if inControls, line.hasPrefix("  - ") {
                flushCurrentControl()
                let pair = try parseKeyValue(
                    String(line.dropFirst(4)),
                    lineNumber: lineNumber + 1
                )
                currentControl = [pair.key: pair.value]
                continue
            }

            if inControls, line.hasPrefix("    ") {
                guard currentControl != nil else {
                    throw RepositoryValidationError(
                        "control-catalog.yaml:\(lineNumber + 1): field without a control item"
                    )
                }
                let pair = try parseKeyValue(
                    String(line.dropFirst(4)),
                    lineNumber: lineNumber + 1
                )
                currentControl?[pair.key] = pair.value
                continue
            }

            if !inControls, !line.hasPrefix(" ") {
                let pair = try parseKeyValue(line, lineNumber: lineNumber + 1)
                result[pair.key] = pair.value
                continue
            }

            throw RepositoryValidationError(
                "control-catalog.yaml:\(lineNumber + 1): unsupported YAML structure"
            )
        }

        flushCurrentControl()
        result["controls"] = controls
        return result
    }

    private static func parseKeyValue(
        _ text: String,
        lineNumber: Int
    ) throws -> (key: String, value: Any) {
        guard let colon = text.firstIndex(of: ":") else {
            throw RepositoryValidationError(
                "control-catalog.yaml:\(lineNumber): expected key: value"
            )
        }
        let key = text[..<colon].trimmingCharacters(in: .whitespaces)
        let rawValue = text[text.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !rawValue.isEmpty else {
            throw RepositoryValidationError(
                "control-catalog.yaml:\(lineNumber): empty key or value"
            )
        }
        return (key, parseScalar(rawValue))
    }

    private static func parseScalar(_ rawValue: String) -> Any {
        if rawValue.hasPrefix("["), rawValue.hasSuffix("]") {
            let body = rawValue.dropFirst().dropLast()
            if body.trimmingCharacters(in: .whitespaces).isEmpty {
                return [String]()
            }
            return body.split(separator: ",").map {
                stripQuotes(String($0).trimmingCharacters(in: .whitespaces))
            }
        }
        switch rawValue {
        case "true": return true
        case "false": return false
        case "null": return NSNull()
        default: return stripQuotes(rawValue)
        }
    }

    private static func stripQuotes(_ value: String) -> String {
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

    var paths: Set<String> {
        Set(methods.keys)
    }

    static func parse(_ text: String) throws -> OpenAPIInspection {
        var version: String?
        var methods = [String: Set<String>]()
        var inPaths = false
        var currentPath: String?

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            let indentation = line.prefix { $0 == " " }.count

            if indentation == 0, trimmed.hasPrefix("openapi:") {
                version = trimmed.dropFirst("openapi:".count)
                    .trimmingCharacters(in: .whitespaces)
                continue
            }

            if indentation == 0, trimmed == "paths:" {
                inPaths = true
                currentPath = nil
                continue
            }

            if inPaths, indentation == 0 {
                inPaths = false
                currentPath = nil
            }

            guard inPaths else { continue }

            if indentation == 2, trimmed.hasPrefix("/"), trimmed.hasSuffix(":") {
                let path = String(trimmed.dropLast())
                currentPath = path
                methods[path, default: []] = []
                continue
            }

            if indentation == 4,
               let path = currentPath,
               trimmed.hasSuffix(":") {
                let method = String(trimmed.dropLast()).lowercased()
                if ["get", "post", "put", "patch", "delete", "head", "options", "trace"].contains(method) {
                    methods[path, default: []].insert(method)
                }
            }
        }

        guard let version else {
            throw RepositoryValidationError("openapi.yaml: missing openapi version")
        }
        return OpenAPIInspection(version: version, methods: methods)
    }
}

private func loadJSON(_ url: URL) throws -> Any {
    try JSONSerialization.jsonObject(
        with: Data(contentsOf: url),
        options: [.fragmentsAllowed]
    )
}

private func loadJSONObject(_ url: URL) throws -> [String: Any] {
    try requiredObject(loadJSON(url), label: url.path)
}

private func requiredSchema(
    _ name: String,
    from schemas: [String: [String: Any]]
) throws -> [String: Any] {
    guard let schema = schemas[name] else {
        throw RepositoryValidationError("Missing required schema: \(name)")
    }
    return schema
}

private func requiredObject(_ value: Any?, label: String) throws -> [String: Any] {
    guard let value, let object = value as? [String: Any] else {
        throw RepositoryValidationError("\(label): expected object")
    }
    return object
}

private func objectArray(_ value: Any?, label: String) throws -> [[String: Any]] {
    guard let value, let array = value as? [Any] else {
        throw RepositoryValidationError("\(label): expected array")
    }
    return try array.enumerated().map { index, element in
        try requiredObject(element, label: "\(label)[\(index)]")
    }
}

private func requiredString(_ value: Any?, label: String) throws -> String {
    guard let value = value as? String else {
        throw RepositoryValidationError("\(label): expected string")
    }
    return value
}

private func stringArray(_ value: Any?, label: String) throws -> [String] {
    guard let value, let array = value as? [Any] else {
        throw RepositoryValidationError("\(label): expected string array")
    }
    return try array.enumerated().map { index, element in
        try requiredString(element, label: "\(label)[\(index)]")
    }
}

private func assertUnique(_ values: [String], label: String) throws {
    var seen = Set<String>()
    var duplicates = Set<String>()
    for value in values where !seen.insert(value).inserted {
        duplicates.insert(value)
    }
    guard duplicates.isEmpty else {
        throw RepositoryValidationError("Duplicate \(label): \(duplicates.sorted())")
    }
}

private func catalogPrincipleIDs(from schema: [String: Any]) throws -> Set<String> {
    let rootProperties = try requiredObject(schema["properties"], label: "catalog schema properties")
    let controls = try requiredObject(rootProperties["controls"], label: "catalog controls schema")
    let controlItem = try requiredObject(controls["items"], label: "catalog control item schema")
    let controlProperties = try requiredObject(
        controlItem["properties"],
        label: "catalog control properties"
    )
    let principles = try requiredObject(
        controlProperties["principles"],
        label: "catalog principles schema"
    )
    let principleItem = try requiredObject(
        principles["items"],
        label: "catalog principle item schema"
    )
    return Set(try stringArray(principleItem["enum"], label: "catalog principle enum"))
}

private func declaredEthicsPrincipleIDs(in text: String) throws -> Set<String> {
    let pattern = #"stable identifiers `E1` through `E([0-9]+)`"#
    let expression = try NSRegularExpression(pattern: pattern)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = expression.firstMatch(in: text, range: range),
          let upperRange = Range(match.range(at: 1), in: text),
          let upperBound = Int(text[upperRange]),
          upperBound >= 1 else {
        throw RepositoryValidationError(
            "ETHICS-RULES.md does not declare a stable E1-through-EN principle range"
        )
    }
    return Set((1...upperBound).map { "E\($0)" })
}

private func ethicsHeadingPrincipleIDs(in text: String) throws -> Set<String> {
    let expression = try NSRegularExpression(pattern: #"(?m)^### (E[0-9]+)\."#)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return Set(expression.matches(in: text, range: range).compactMap { match in
        guard let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[swiftRange])
    })
}

private func relativePath(_ url: URL, root: URL) -> String {
    let rootPath = root.standardizedFileURL.path
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(rootPath + "/") else { return path }
    return String(path.dropFirst(rootPath.count + 1))
}

private func matches(_ expression: NSRegularExpression, value: String) -> Bool {
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    return expression.firstMatch(in: value, range: range) != nil
}

private func integer(_ value: Any?) -> Int? {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    return nil
}

private func matchesJSONType(_ value: Any, type: String) -> Bool {
    switch type {
    case "object": return value is [String: Any]
    case "array": return value is [Any]
    case "string": return value is String
    case "boolean": return value is Bool
    case "null": return value is NSNull
    default: return false
    }
}

private func jsonTypeName(_ value: Any) -> String {
    if value is [String: Any] { return "object" }
    if value is [Any] { return "array" }
    if value is String { return "string" }
    if value is Bool { return "boolean" }
    if value is NSNull { return "null" }
    if value is NSNumber { return "number" }
    return String(describing: type(of: value))
}

private func jsonEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    (lhs as AnyObject).isEqual(rhs)
}

private func canonicalJSON(_ value: Any) throws -> String {
    let data = try JSONSerialization.data(
        withJSONObject: value,
        options: [.sortedKeys, .fragmentsAllowed]
    )
    guard let string = String(data: data, encoding: .utf8) else {
        throw RepositoryValidationError("Unable to encode canonical JSON")
    }
    return string
}
