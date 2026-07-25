import EvoEthics
import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

private func fail(_ message: String, code: Int32 = 2) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

private func usage() -> Never {
    fail("Usage: evo-ethicsctl evaluate <request.json> [policy.json]")
}

let arguments = CommandLine.arguments

guard arguments.count == 3 || arguments.count == 4 else {
    usage()
}

guard arguments[1] == "evaluate" else {
    usage()
}

do {
    let requestURL = URL(fileURLWithPath: arguments[2])
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let request = try decoder.decode(
        EvaluationRequest.self,
        from: Data(contentsOf: requestURL)
    )

    let policy: PolicyBundle
    if arguments.count == 4 {
        policy = try PolicyBundleLoader.decode(
            url: URL(fileURLWithPath: arguments[3])
        )
    } else {
        policy = try PolicyBundleLoader.bundledDevelopmentPolicy()
    }

    let evaluator = ReferenceEthicsEvaluator(policy: policy)
    let decision = evaluator.evaluate(request)

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let output = try encoder.encode(decision)
    FileHandle.standardOutput.write(output)
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    fail("Evaluation failed: \(error.localizedDescription)", code: 1)
}
