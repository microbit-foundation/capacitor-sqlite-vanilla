// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicrobitCapacitorSqliteVanilla",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MicrobitCapacitorSqliteVanilla",
            targets: ["SQLiteVanillaPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "SQLiteVanillaPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/SQLiteVanillaPlugin",
            linkerSettings: [.linkedLibrary("sqlite3")]),
        .testTarget(
            name: "SQLiteVanillaPluginTests",
            dependencies: ["SQLiteVanillaPlugin"],
            path: "ios/Tests/SQLiteVanillaPluginTests")
    ]
)
