// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SignatureKit",
    defaultLocalization: "en",
    platforms: [.iOS("18.6")],
    products: [
        .library(name: "SignatureKit", targets: ["SignatureKit"])
    ],
    targets: [
        .target(name: "SignatureKit", resources: [.process("Resources")]),
        .testTarget(name: "SignatureKitTests", dependencies: ["SignatureKit"])
    ]
)
