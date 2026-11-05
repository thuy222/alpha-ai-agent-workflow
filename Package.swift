// swift-tools-version:5.9
// CodingMover (tools/automationflow): run with `swift run` from this folder.
import PackageDescription

let package = Package(
    name: "CodingMover",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "CodingMover", path: "tools/automationflow/Sources/CodingMover")
    ]
)
