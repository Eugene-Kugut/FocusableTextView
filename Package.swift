// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FocusableTextView",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FocusableTextView",
            targets: ["FocusableTextView"]
        )
    ],
    targets: [
        .target(
            name: "FocusableTextView",
            path: "Sources/FocusableTextView"
        )
    ]
)
