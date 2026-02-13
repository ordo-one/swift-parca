// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-parca",
  platforms: [
    .macOS(.v14)
  ],
  dependencies: [
  ],
  targets: [
    .executableTarget(
      name: "addr2line-swift",
      dependencies: [
      ],
      path: "Sources",
    ),
    .testTarget(
      name: "addr2lineTests",
      dependencies: ["addr2line-swift"],
      path: "Tests"
    )
  ]
)
