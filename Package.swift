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
                // Exclude timeouts bench/lua files (Lua not available on iOS)
                "tor-ios-fixed/src/ext/timeouts/bench.c",
                "tor-ios-fixed/src/ext/timeouts/bench.plt.d",
                "tor-ios-fixed/src/ext/timeouts/timeout.lua",
                "tor-ios-fixed/src/ext/timeouts/lua",  // Exclude entire lua directory
                // Exclude ed25519 test sources (not for production build)
                "tor-ios-fixed/src/ext/ed25519/donna/test-internals.c",
                // Exclude README/Makefile patterns
                "tor-ios-fixed/Makefile",
                "tor-ios-fixed/configure",
                "tor-ios-fixed/configure.ac",

                // Exclude dirauth (not needed for iOS client)
                "tor-ios-fixed/src/feature/dirauth",
                // Exclude server pluggable transport config (relay-only)
                "tor-ios-fixed/src/feature/relay/transport_config.c",
                "tor-ios-fixed/src/feature/relay/transport_config.h",
                // Exclude relay server features (not needed for iOS client)
                "tor-ios-fixed/src/feature/relay/routermode.c",
                "tor-ios-fixed/src/feature/relay/selftest.c",
                "tor-ios-fixed/src/feature/relay/routerkeys.c",
                "tor-ios-fixed/src/feature/relay/router.c",
                "tor-ios-fixed/src/feature/relay/relay_periodic.c",
                "tor-ios-fixed/src/feature/relay/relay_handshake.c",
                "tor-ios-fixed/src/feature/relay/relay_config.c",
                "tor-ios-fixed/src/feature/relay/onion_queue.c",
                "tor-ios-fixed/src/feature/relay/circuitbuild_relay.c",
                "tor-ios-fixed/src/feature/relay/relay_sys.c",
                "tor-ios-fixed/src/feature/relay/ext_orport.c",
                "tor-ios-fixed/src/feature/relay/dns.c",
                // Exclude mulodi emulation (not needed on iOS/clang)
                "tor-ios-fixed/src/ext/mulodi/mulodi4.c",
                "tor-ios-fixed/src/ext/mulodi",
                // Exclude mmap (not supported/needed on iOS build path)
                "tor-ios-fixed/src/lib/fs/mmap.c",
                // Exclude terminal password input (not applicable on iOS)
                "tor-ios-fixed/src/lib/term",
            ],
            publicHeadersPath: "include",
            cSettings: [
                // Feature defines
                .define("HAVE_CONFIG_H", to: "1"),
                .define("RSHIFT_DOES_SIGN_EXTEND", to: "1"),
                .define("FLEXIBLE_ARRAY_MEMBER"),
                .define("SIZE_T_CEILING", to: "SIZE_MAX"),
                .define("TOR_UNIT_TESTS", to: "0"),
                // Platform constants
                .define("CHAR_BIT", to: "8"),
                // Force local includes to take precedence (shim for openssl/asn1_mac.h)
                .unsafeFlags(["-I", "Sources/Tor/include"]),
                // OpenSSL 1.1+/3.x APIs are available in our vendored OpenSSL
                .define("HAVE_SSL_GET_CLIENT_RANDOM", to: "1"),
                .define("HAVE_SSL_GET_SERVER_RANDOM", to: "1"),
                .define("HAVE_SSL_SESSION_GET_MASTER_KEY", to: "1"),
                .define("HAVE_SSL_GET_CLIENT_CIPHERS", to: "1"),
                // Ensure VERSION is visible to version.c at compile time
                .define("PACKAGE_VERSION", to: "\"0.4.8.19\""),
                .define("VERSION", to: "\"0.4.8.19\""),
                
                // Platform
                .define("__APPLE_USE_RFC_3542", to: "1"),
                
                // Header search paths - Tor internal (ensure local include overrides vendored)
                .headerSearchPath("include"),
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
                .headerSearchPath("tor-ios-fixed/src/ext/equix/hashx/src"),  // For hashx_endian.h
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
