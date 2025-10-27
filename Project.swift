import ProjectDescription

let project = Project(
    name: "TorFrameworkBuilder",
    organizationName: "Tor Project",
    targets: [
        .target(
            name: "TorFrameworkBuilder",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.torproject.TorFrameworkBuilder",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "0.4.8.19",
                    "CFBundleVersion": "1",
                    "CFBundleDevelopmentRegion": "en"
                ]
            ),
            sources: [],
            resources: ["Resources/**"],
            dependencies: [
                // Tor.xcframework как единственная зависимость
                .xcframework(path: "output/Tor.xcframework")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_BITCODE": "NO",
                    "SKIP_INSTALL": "NO",
                    "INSTALL_PATH": "$(LOCAL_LIBRARY_DIR)/Frameworks",
                    "DEFINES_MODULE": "YES",
                    "SWIFT_VERSION": "5.9"
                ],
                configurations: [
                    .debug(name: "Debug", settings: [
                        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
                        "GCC_OPTIMIZATION_LEVEL": "0"
                    ]),
                    .release(name: "Release", settings: [
                        "SWIFT_OPTIMIZATION_LEVEL": "-O",
                        "GCC_OPTIMIZATION_LEVEL": "s"
                    ])
                ]
            )
        ),
        .target(
            name: "TorFrameworkBuilderTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.torproject.TorFrameworkBuilderTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/TorFrameworkBuilderTests/**"],
            resources: [],
            dependencies: [
                .target(name: "TorFrameworkBuilder")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_BITCODE": "NO"
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "TorFrameworkBuilder",
            shared: true,
            buildAction: .buildAction(targets: ["TorFrameworkBuilder"]),
            testAction: .targets(["TorFrameworkBuilderTests"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)

