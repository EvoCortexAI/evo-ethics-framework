// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "EvoEthics",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        // Independent products. Consumers depend on each explicitly.
        // EvoEthics does not import SaturnAuthority (and must not).
        .library(name: "EvoEthics", targets: ["EvoEthics"]),
        .library(name: "SaturnAuthority", targets: ["SaturnAuthority"]),
        .executable(name: "evo-ethicsctl", targets: ["evo-ethicsctl"])
    ],
    targets: [
        .target(
            name: "SaturnAuthority"
        ),
        .target(
            name: "EvoEthics",
            // No SaturnAuthority dependency: evaluation contract is independent of
            // authority fingerprint/receipt/lease (SUA §9 ownership split).
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "evo-ethicsctl",
            dependencies: ["EvoEthics"]
        ),
        // Repository-only validation tooling. No shipping library product depends on it.
        .target(
            name: "EvoEthicsValidation",
            dependencies: ["EvoEthics"]
        ),
        .testTarget(
            name: "EvoEthicsTests",
            dependencies: ["EvoEthics"]
        ),
        .testTarget(
            name: "SaturnAuthorityTests",
            dependencies: ["SaturnAuthority"]
        ),
        .testTarget(
            name: "EvoEthicsValidationTests",
            dependencies: ["EvoEthicsValidation"]
        )
    ]
)
