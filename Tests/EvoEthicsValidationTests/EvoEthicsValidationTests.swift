import Foundation
import Testing
@testable import EvoEthicsValidation

@Suite("Constrained JSON Schema validation")
struct JSONSchemaSubsetValidatorTests {
    private let schema = #"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "additionalProperties": false,
      "required": ["id", "timestamp", "states", "assurance"],
      "properties": {
        "id": { "type": "string", "pattern": "^EC-[A-Z0-9]+-[0-9]{3}$" },
        "timestamp": { "type": "string", "format": "date-time" },
        "states": {
          "type": "array",
          "minItems": 1,
          "uniqueItems": true,
          "items": { "enum": ["allow", "deny"] }
        },
        "assurance": { "$ref": "#/$defs/assurance" }
      },
      "$defs": {
        "assurance": { "type": ["string", "null"], "maxLength": 16 }
      }
    }
    """#

    @Test("Supported schema vocabulary validates a conforming value")
    func acceptsConformingValue() throws {
        let validator = try JSONSchemaSubsetValidator(schema: JSONValue.decode(schema))
        try validator.validateSchemaDefinition()
        try validator.validate(
            JSONValue.decode(
                #"{"id":"EC-E4-003","timestamp":"2026-08-24T10:00:00Z","states":["deny"],"assurance":null}"#
            )
        )
    }

    @Test(
        "Invalid instances fail closed with a stable path",
        arguments: [
            (
                #"{"timestamp":"2026-08-24T10:00:00Z","states":["deny"],"assurance":null}"#,
                "instance: missing required property 'id'"
            ),
            (
                #"{"id":"bad","timestamp":"2026-08-24T10:00:00Z","states":["deny"],"assurance":null}"#,
                "instance.id: string does not match pattern '^EC-[A-Z0-9]+-[0-9]{3}$'"
            ),
            (
                #"{"id":"EC-E4-003","timestamp":"not-a-date","states":["deny"],"assurance":null}"#,
                "instance.timestamp: string is not an RFC 3339 date-time"
            ),
            (
                #"{"id":"EC-E4-003","timestamp":"2026-08-24T10:00:00Z","states":["deny","deny"],"assurance":null}"#,
                "instance.states: array items must be unique"
            ),
            (
                #"{"id":"EC-E4-003","timestamp":"2026-08-24T10:00:00Z","states":["deny"],"assurance":null,"extra":true}"#,
                "instance: additional property 'extra' is not allowed"
            ),
        ]
    )
    func rejectsInvalidValue(source: String, expected: String) throws {
        let validator = try JSONSchemaSubsetValidator(schema: JSONValue.decode(schema))

        #expect(throws: ValidationFailure(expected)) {
            try validator.validate(JSONValue.decode(source))
        }
    }

    @Test("Unknown validation keywords are rejected instead of ignored")
    func rejectsUnsupportedKeyword() throws {
        let validator = try JSONSchemaSubsetValidator(
            schema: JSONValue.decode(#"{"type":"string","oneOf":[{"const":"x"}]}"#)
        )

        #expect(throws: ValidationFailure("schema: unsupported schema keyword 'oneOf'")) {
            try validator.validateSchemaDefinition()
        }
    }
}

@Suite("Repository validation")
struct RepositoryValidationTests {
    @Test("Every tracked contract artifact passes the Swift validator")
    func validatesRepository() throws {
        let report = try RepositoryValidator(root: repositoryRoot()).validate()

        #expect(report.schemaCount == 6)
        #expect(report.actionCount == 10)
        #expect(report.controlCount == 18)
        #expect(report.requestExampleCount == 4)
        #expect(report.decisionExampleCount == 4)
        #expect(report.vectorCount == 5)
    }

    @Test("All conformance vectors pass through the in-process evaluator")
    func validatesConformance() throws {
        let report = try ConformanceRunner(root: repositoryRoot()).run()
        #expect(report.vectorCount == 5)
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
