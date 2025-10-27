import ProjectDescription

let project = Project(
    name: "TorFramework",
    organizationName: "Tor Project",
    targets: [
        .target(
            name: "TorFramework",
            destinations: .iOS,
            product: .framework,
            bundleId: "org.torproject.TorFramework",
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
            name: "TorFrameworkTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "org.torproject.TorFrameworkTests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/TorFrameworkTests/**"],
            resources: [],
            dependencies: [
                .target(name: "TorFramework")
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
            name: "TorFramework",
            shared: true,
            buildAction: .buildAction(targets: ["TorFramework"]),
            testAction: .targets(["TorFrameworkTests"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)

