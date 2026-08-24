import EvoEthicsValidation
import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("Validation failed: " + message + "\n").utf8))
    exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count == 1 || arguments.count == 3 && arguments[1] == "--root" else {
    FileHandle.standardError.write(
        Data("Usage: evo-ethics-validate [--root <repository-path>]\n".utf8)
    )
    exit(2)
}

let rootPath = arguments.count == 3
    ? arguments[2]
    : FileManager.default.currentDirectoryPath
let root = URL(fileURLWithPath: rootPath, isDirectory: true)

do {
    let validation = try RepositoryValidator(root: root).validate()
    let conformance = try ConformanceRunner(root: root).run()
    print(validation.summary)
    print(conformance.summary)
} catch {
    fail(error.localizedDescription)
}
