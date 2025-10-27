// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings
    
    let packageSettings = PackageSettings(
        productTypes: [
            "TorFramework": .framework
        ]
    )
#endif

let package = Package(
    name: "TorFramework",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TorFramework",
            targets: ["TorFramework"]
        )
    ],
    dependencies: [
        // Нет внешних зависимостей - всё включено в XCFramework
    ],
    targets: [
        // Binary target с готовым XCFramework
        .binaryTarget(
            name: "TorFramework",
            path: "output/Tor.xcframework"
        )
    ]
)
