// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "EvoEthics",
    platforms: [
        .macOS(.v26)
    ],
    products: [
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
            dependencies: ["SaturnAuthority"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "evo-ethicsctl",
            dependencies: ["EvoEthics"]
        ),
        .testTarget(
            name: "EvoEthicsTests",
            dependencies: ["EvoEthics", "SaturnAuthority"]
        ),
        .testTarget(
            name: "SaturnAuthorityTests",
            dependencies: ["SaturnAuthority"]
        )
    ]
)
