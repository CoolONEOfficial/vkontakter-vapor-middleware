// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vkontakter-vapor-middleware",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "VkontakterMiddleware", targets: ["VkontakterMiddleware"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/CoolONEOfficial/Vkontakter.git", from: "1.0.0-alpha.4.0.1"),
    ],
    targets: [
        .target(
            name: "VkontakterMiddleware",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Vkontakter", package: "Vkontakter"),
            ]
        ),
        .target(name: "DemoVkontakterMiddleware", dependencies: [.target(name: "VkontakterMiddleware")]),
        .testTarget(name: "VkontakterMiddlewareTests", dependencies: [
            .target(name: "VkontakterMiddleware"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
