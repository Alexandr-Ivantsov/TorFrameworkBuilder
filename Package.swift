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
        .target(
            name: "TorFramework",
            dependencies: [],
            path: "Sources/TorFramework",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("SystemConfiguration"),
                .linkedLibrary("z")  // zlib для iOS
            ]
        ),
        .testTarget(
            name: "TorFrameworkTests",
            dependencies: ["TorFramework"],
            path: "Tests/TorFrameworkTests"
        )
    ]
)
