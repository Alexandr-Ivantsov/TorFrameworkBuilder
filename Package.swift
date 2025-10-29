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
            name: "TorFrameworkBuilder",
            targets: ["Tor"]
        )
    ],
    dependencies: [],
    targets: [
        // ========================================
        // Vendored Dependencies (pre-built static libs)
        // ========================================
        
        .target(
            name: "COpenSSL",
            path: "output/openssl",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Loutput/openssl/lib",
                    "-lssl",
                    "-lcrypto"
                ])
            ]
        ),
        
        .target(
            name: "CLibevent",
            path: "output/libevent",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Loutput/libevent/lib",
                    "-levent",
                    "-levent_core"
                ])
            ]
        ),
        
        .target(
            name: "CXZ",
            path: "output/xz",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Loutput/xz/lib",
                    "-llzma"
                ])
            ]
        ),
        
        // ========================================
        // Tor Target (source-based compilation)
        // ========================================
        
        .target(
            name: "Tor",
            dependencies: ["COpenSSL", "CLibevent", "CXZ"],
            path: "Sources/Tor",
            exclude: [
                // Exclude non-C files
                "tor-ios-fixed/Makefile.am",
                "tor-ios-fixed/Makefile.in",
                "tor-ios-fixed/README.md",
                "tor-ios-fixed/src/ext/README",
                "tor-ios-fixed/src/test",
                "tor-ios-fixed/src/tools",
                // Exclude .inc files (they are included, not compiled)
                "tor-ios-fixed/src/core/or/channelpadding_negotiation.inc",
                "tor-ios-fixed/src/core/or/dos_st.inc",
                "tor-ios-fixed/src/core/or/protover_rust.inc",
                "tor-ios-fixed/src/core/mainloop/cpuworker_sys.inc",
                "tor-ios-fixed/src/core/mainloop/mainloop_state.inc",
                "tor-ios-fixed/src/core/mainloop/mainloop_sys.inc",
                "tor-ios-fixed/src/core/mainloop/netstatus_sys.inc",
                "tor-ios-fixed/src/lib/tls/tortls_st.inc",
                "tor-ios-fixed/src/lib/tls/x509.inc",
                "tor-ios-fixed/src/lib/tls/x509_nss.inc",
                
                // Exclude NSS files (NSS not available on iOS - use OpenSSL instead)
                "tor-ios-fixed/src/lib/tls/x509_nss.c",
                "tor-ios-fixed/src/lib/tls/tortls_nss.c",
                "tor-ios-fixed/src/lib/tls/nss_countbytes.c",
                "tor-ios-fixed/src/lib/tls/nss_countbytes.h",
                "tor-ios-fixed/src/lib/crypt_ops/crypto_digest_nss.c",
                
                // Exclude main.c (has main() function)
                "tor-ios-fixed/src/app/main/main.c",
                // Exclude timeouts bench/lua files
                "tor-ios-fixed/src/ext/timeouts/bench.c",
                "tor-ios-fixed/src/ext/timeouts/bench.plt.d",
                "tor-ios-fixed/src/ext/timeouts/timeout.lua",
                // Exclude README/Makefile patterns
                "tor-ios-fixed/Makefile",
                "tor-ios-fixed/configure",
                "tor-ios-fixed/configure.ac",
            ],
            publicHeadersPath: "include",
            cSettings: [
                // Feature defines
                .define("HAVE_CONFIG_H", to: "1"),
                .define("RSHIFT_DOES_SIGN_EXTEND", to: "1"),
                .define("FLEXIBLE_ARRAY_MEMBER"),
                .define("SIZE_T_CEILING", to: "SIZE_MAX"),
                .define("TOR_UNIT_TESTS", to: "0"),
                
                // Platform
                .define("__APPLE_USE_RFC_3542", to: "1"),
                
                // Header search paths - Tor internal
                .headerSearchPath("tor-ios-fixed"),
                .headerSearchPath("tor-ios-fixed/src"),
                .headerSearchPath("tor-ios-fixed/src/core"),
                .headerSearchPath("tor-ios-fixed/src/feature"),
                .headerSearchPath("tor-ios-fixed/src/app"),
                .headerSearchPath("tor-ios-fixed/src/lib"),
                .headerSearchPath("tor-ios-fixed/src/ext"),
                .headerSearchPath("tor-ios-fixed/src/ext/trunnel"),
                .headerSearchPath("tor-ios-fixed/src/ext/ed25519/ref10"),
                .headerSearchPath("tor-ios-fixed/src/ext/ed25519/donna"),
                .headerSearchPath("tor-ios-fixed/src/ext/keccak-tiny"),
                .headerSearchPath("tor-ios-fixed/src/ext/equix/include"),
                .headerSearchPath("tor-ios-fixed/src/ext/equix/hashx/include"),
                .headerSearchPath("tor-ios-fixed/src/trunnel"),
                
                // Vendored dependencies
                .headerSearchPath("../../output/openssl/include"),
                .headerSearchPath("../../output/libevent/include"),
                .headerSearchPath("../../output/xz/include"),
                
                // Compiler flags
                .unsafeFlags(["-w"]),  // Suppress warnings
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("resolv"),
            ],
            plugins: [.plugin(name: "TorPatchPlugin")]
        ),
        
        // ========================================
        // TorPatchPlugin - Apply iOS patches before compilation
        // ========================================
        
        .plugin(
            name: "TorPatchPlugin",
            capability: .buildTool(),
            path: "Plugins/TorPatchPlugin"
        ),
    ]
)
