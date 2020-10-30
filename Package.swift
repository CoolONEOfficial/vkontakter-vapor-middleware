// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "telegrammer-vapor-middleware",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "TelegrammerMiddleware", targets: ["TelegrammerMiddleware"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/givip/Telegrammer.git", from: "1.0.0-alpha.4.0.1"),
    ],
    targets: [
        .target(
            name: "TelegrammerMiddleware",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Telegrammer", package: "Telegrammer"),
            ]
        ),
        .target(name: "DemoTelegrammerMiddleware", dependencies: [.target(name: "TelegrammerMiddleware")]),
        .testTarget(name: "TelegrammerMiddlewareTests", dependencies: [
            .target(name: "TelegrammerMiddleware"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
