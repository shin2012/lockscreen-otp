// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LockscreenOTPCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "OTPCore", targets: ["OTPCore"])],
    dependencies: [.package(url: "https://github.com/apple/swift-crypto.git", exact: "3.9.0")],
    targets: [
        .target(name: "OTPCore", dependencies: [.product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux]))], path: "ios/Shared", sources: ["TOTPEngine.swift", "TimelineSchedule.swift"]),
        .testTarget(name: "OTPCoreTests", dependencies: ["OTPCore"], path: "Tests/OTPCoreTests")
    ]
)
