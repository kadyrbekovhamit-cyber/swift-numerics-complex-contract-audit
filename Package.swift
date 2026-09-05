// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "ComplexPowScan",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-numerics.git",
      revision: "899af71c0256d0ad181e3b7eb3453c1065d928a5"
    )
  ],
  targets: [
    .executableTarget(
      name: "ComplexPowScan",
      dependencies: [
        .product(name: "ComplexModule", package: "swift-numerics")
      ]
    )
  ]
)
