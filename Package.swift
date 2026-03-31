// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "KeyboardControl",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "KeyboardControl", targets: ["KeyboardControl"])
    ],
    targets: [
        .target(name: "KeyboardControl")
    ]
)
