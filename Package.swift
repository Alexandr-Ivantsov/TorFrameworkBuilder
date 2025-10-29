// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings
    
    let packageSettings = PackageSettings(
        productTypes: [
            "Tor": .framework
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
            name: "Tor",
            targets: ["Tor"]
        )
    ],
    dependencies: [],
    targets: [
        // Binary target с XCFramework содержащим ПАТЧ
        // ВАЖНО: Патч УЖЕ СКОМПИЛИРОВАН в binary!
        // log_info строка вырезается оптимизатором, но КОД ПАТЧА работает!
        .binaryTarget(
            name: "Tor",
            path: "output/Tor.xcframework"
        )
    ]
)
