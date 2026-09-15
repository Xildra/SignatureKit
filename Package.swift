// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SignatureKit",
    platforms: [.iOS("18.6")],
    products: [
        .library(name: "SignatureKit", targets: ["SignatureKit"])
    ],
    targets: [
        .target(name: "SignatureKit"),
        .testTarget(name: "SignatureKitTests", dependencies: ["SignatureKit"])
    ]
)
