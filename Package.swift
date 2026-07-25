// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EvoEthics",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "EvoEthics", targets: ["EvoEthics"]),
        .executable(name: "evo-ethicsctl", targets: ["evo-ethicsctl"])
    ],
    targets: [
        .target(
            name: "EvoEthics",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "evo-ethicsctl",
            dependencies: ["EvoEthics"]
        ),
        .testTarget(
            name: "EvoEthicsTests",
            dependencies: ["EvoEthics"]
        )
    ]
)
