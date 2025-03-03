// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Rounds",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Rounds",
            targets: ["Rounds"]
        ),
        .executable(
            name: "GolfCourseAPITest",
            targets: ["GolfCourseAPITest"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "10.29.0"),
    ],
    targets: [
        .target(
            name: "Rounds",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            resources: [
                .process("Resources/GoogleService-Info.plist")
            ],
            swiftSettings: [
                .define("SWIFT_PLATFORM_IOS")
            ]
        ),
        .executableTarget(
            name: "GolfCourseAPITest",
            dependencies: []
        ),
        .testTarget(
            name: "RoundsTests",
            dependencies: ["Rounds"]
        )
    ]
) 