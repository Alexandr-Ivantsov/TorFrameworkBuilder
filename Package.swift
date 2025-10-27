// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings
    
    let packageSettings = PackageSettings(
        productTypes: [
            "TorFrameworkBuilder": .framework
        ]
    )
#endif

let package = Package(
    name: "TorFrameworkBuilder",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TorFrameworkBuilder",
            targets: ["TorFrameworkBuilder"]
        )
    ],
    dependencies: [
        // Нет внешних зависимостей - всё включено в XCFramework
    ],
    targets: [
        // Binary target с готовым XCFramework
        .binaryTarget(
            name: "TorFrameworkBuilder",
            path: "output/Tor.xcframework"
        )
    ]
)
