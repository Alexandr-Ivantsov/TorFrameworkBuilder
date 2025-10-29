// swift-tools-version: 5.9
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
        // ============================================
        // MAIN TARGET: Tor (компилируется из исходников)
        // ============================================
        .target(
            name: "Tor",
            dependencies: [],
            path: "Sources/Tor",
            exclude: [
                // Исключить ненужное
                "tor-ios-fixed/src/test",
                "tor-ios-fixed/contrib",
                "tor-ios-fixed/doc",
                "tor-ios-fixed/scripts",
                "tor-ios-fixed/m4",
                "tor-ios-fixed/ReleaseNotes",
                "tor-ios-fixed/ChangeLog",
                "tor-ios-fixed/INSTALL"
            ],
            sources: [
                "tor-ios-fixed/src/lib",
                "tor-ios-fixed/src/core",
                "tor-ios-fixed/src/feature",
                "tor-ios-fixed/src/app"
            ],
            publicHeadersPath: "include",
            cSettings: [
                // Include paths
                .headerSearchPath("tor-ios-fixed"),
                .headerSearchPath("tor-ios-fixed/src"),
                .headerSearchPath("tor-ios-fixed/src/core"),
                .headerSearchPath("tor-ios-fixed/src/core/or"),
                .headerSearchPath("tor-ios-fixed/src/feature"),
                .headerSearchPath("tor-ios-fixed/src/lib"),
                .headerSearchPath("tor-ios-fixed/src/app"),
                .headerSearchPath("tor-ios-fixed/src/ext"),
                .headerSearchPath("tor-ios-fixed/src/trunnel"),
                .headerSearchPath("include"),
                
                // OpenSSL paths
                .headerSearchPath("../../output/openssl/include"),
                
                // Libevent paths
                .headerSearchPath("../../output/libevent/include"),
                
                // XZ paths  
                .headerSearchPath("../../output/xz/include"),
                
                // Defines
                .define("HAVE_CONFIG_H"),
                .define("RSHIFT_DOES_SIGN_EXTEND", to: "1"),
                .define("FLEXIBLE_ARRAY_MEMBER", to: ""),
                .define("SIZE_T_CEILING", to: "SIZE_MAX"),
                .define("HAVE_STRUCT_TIMEVAL", to: "1"),
                .define("HAVE_STRUCT_IN6_ADDR", to: "1"),
                
                // iOS specific
                .define("TARGET_OS_IPHONE", to: "1"),
                .define("__APPLE__", to: "1"),
                
                // Compiler flags
                .unsafeFlags([
                    "-Wno-deprecated-declarations",
                    "-Wno-unused-variable",
                    "-Wno-unused-function",
                    "-Wno-implicit-function-declaration",
                    "-Wno-int-conversion"
                ],
                .when(configuration: .debug))
            ],
            linkerSettings: [
                // Link OpenSSL
                .unsafeFlags([
                    "-L", "output/openssl/lib",
                    "-lssl",
                    "-lcrypto"
                ]),
                
                // Link Libevent
                .unsafeFlags([
                    "-L", "output/libevent/lib",
                    "-levent"
                ]),
                
                // Link XZ
                .unsafeFlags([
                    "-L", "output/xz/lib",
                    "-llzma"
                ]),
                
                // System frameworks
                .linkedLibrary("z"),
                .linkedFramework("Security"),
                .linkedFramework("Foundation")
            ],
            plugins: ["TorPatchPlugin"]
        ),
        
        // ============================================
        // PLUGIN: Применение патча ПЕРЕД компиляцией
        // ============================================
        .plugin(
            name: "TorPatchPlugin",
            capability: .buildTool(),
            path: "Plugins/TorPatchPlugin"
        )
    ]
)

