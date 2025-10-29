// swift-tools-version: 5.9
// SIMPLIFIED VERSION для тестирования компиляции Tor с патчем
import PackageDescription

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
    targets: [
        .target(
            name: "Tor",
            path: "Sources/Tor",
            exclude: [
                "tor-ios-fixed/src/test",
                "tor-ios-fixed/contrib",
                "tor-ios-fixed/doc"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("tor-ios-fixed"),
                .headerSearchPath("tor-ios-fixed/src"),
                .define("HAVE_CONFIG_H")
            ],
            plugins: ["TorPatchPlugin"]
        ),
        .plugin(
            name: "TorPatchPlugin",
            capability: .buildTool(),
            path: "Plugins/TorPatchPlugin"
        )
    ]
)

