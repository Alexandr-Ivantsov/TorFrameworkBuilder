# Alternative Solutions for Header Pollution Issue

If the Tuist community cannot provide a solution to the `dns_sd.h` header pollution issue, here are alternative approaches to integrate the source-based C library into the iOS app.

---

## Option 1: Direct Xcode Static Library Integration

### Concept
Build the C library as a traditional Xcode static library project (`.xcodeproj`) instead of relying on SPM/Tuist integration. This gives full control over compilation settings and prevents modularization issues.

### Implementation Plan

#### Step 1: Create Xcode Static Library Project
```bash
cd ~/admin/TorFrameworkBuilder
# Create new Xcode project
```
1. Open Xcode → New Project → iOS → Static Library
2. Name: `NetworkLibStatic`
3. Add all C source files from `Sources/Tor/tor-ios-fixed/src`
4. Configure Build Settings:
   - `HEADER_SEARCH_PATHS` = all current header paths
   - `GCC_PREPROCESSOR_DEFINITIONS` = all current defines
   - `OTHER_CFLAGS` = `-w -fno-modules -fno-objc-arc`
   - `SKIP_INSTALL` = NO
   - `BUILD_LIBRARY_FOR_DISTRIBUTION` = NO

#### Step 2: Link Vendored Libraries
1. Add `output/openssl/lib/libssl.a` to Link Binary With Libraries
2. Add `output/openssl/lib/libcrypto.a`
3. Add `output/libevent/lib/libevent_core.a`
4. Add `output/xz/lib/liblzma.a`

#### Step 3: Build Universal Static Library
```bash
# Build for device
xcodebuild -project NetworkLibStatic.xcodeproj \
  -scheme NetworkLibStatic \
  -sdk iphoneos \
  -configuration Release \
  ONLY_ACTIVE_ARCH=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  clean build

# Build for simulator
xcodebuild -project NetworkLibStatic.xcodeproj \
  -scheme NetworkLibStatic \
  -sdk iphonesimulator \
  -configuration Release \
  ONLY_ACTIVE_ARCH=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  clean build

# Create XCFramework
xcodebuild -create-xcframework \
  -library build/Release-iphoneos/libNetworkLibStatic.a \
  -library build/Release-iphonesimulator/libNetworkLibStatic.a \
  -output NetworkLib.xcframework
```

#### Step 4: Integrate into TorApp
1. Add `NetworkLib.xcframework` to TorApp project manually
2. Link in TorApp target
3. **No bridging header import needed** - keep headers private

### Pros
- ✅ Full control over compilation
- ✅ No SPM/Tuist modularization interference
- ✅ Headers remain private, no pollution
- ✅ Proven approach for complex C libraries

### Cons
- ❌ Manual Xcode project maintenance
- ❌ Need to rebuild XCFramework for every change
- ❌ Cannot use `tuist edit` workflow

### Effort
**Medium** - 2-3 hours initial setup, 15-30 min per rebuild

---

## Option 2: Git Submodule + Local Build Script

### Concept
Keep source code as git submodule, use custom build script to compile C library into static `.a` files, link them directly into TorApp without SPM/Tuist.

### Implementation Plan

#### Step 1: Setup Git Submodule
```bash
cd ~/admin/TorApp
git submodule add https://github.com/user/TorFrameworkBuilder.git Submodules/NetworkLib
git submodule update --init --recursive
```

#### Step 2: Create Build Script
Create `Scripts/build_networklib.sh`:
```bash
#!/bin/bash
set -e

SUBMODULE_DIR="$PROJECT_DIR/Submodules/NetworkLib"
OUTPUT_DIR="$PROJECT_DIR/Build/NetworkLib"

echo "🔨 Building NetworkLib..."

# Build for device
xcodebuild -project "$SUBMODULE_DIR/NetworkLibStatic.xcodeproj" \
  -scheme NetworkLibStatic \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath "$OUTPUT_DIR/DerivedData" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

# Build for simulator
xcodebuild -project "$SUBMODULE_DIR/NetworkLibStatic.xcodeproj" \
  -scheme NetworkLibStatic \
  -sdk iphonesimulator \
  -configuration Release \
  -derivedDataPath "$OUTPUT_DIR/DerivedData" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

# Create fat library
lipo -create \
  "$OUTPUT_DIR/DerivedData/Build/Products/Release-iphoneos/libNetworkLibStatic.a" \
  "$OUTPUT_DIR/DerivedData/Build/Products/Release-iphonesimulator/libNetworkLibStatic.a" \
  -output "$OUTPUT_DIR/libNetworkLib.a"

echo "✅ NetworkLib built: $OUTPUT_DIR/libNetworkLib.a"
```

#### Step 3: Integrate into TorApp Build
1. Add Run Script Phase in TorApp target (before Compile Sources):
   ```bash
   bash "$PROJECT_DIR/Scripts/build_networklib.sh"
   ```
2. Add `Build/NetworkLib/libNetworkLib.a` to Link Binary With Libraries
3. Add header search path: `$(PROJECT_DIR)/Submodules/NetworkLib/Sources/Tor/tor-ios-fixed`
4. Link system libraries: `z`, `resolv`

#### Step 4: Update on Changes
```bash
cd ~/admin/TorApp
git submodule update --remote Submodules/NetworkLib
# Rebuild happens automatically on next TorApp build
```

### Pros
- ✅ Source-based, tracks upstream changes
- ✅ Automated rebuild on TorApp build
- ✅ No SPM/Tuist involvement
- ✅ Git submodule keeps history

### Cons
- ❌ Slower TorApp builds (rebuilds C library every time)
- ❌ Cannot use Tuist for this dependency
- ❌ Manual script maintenance

### Effort
**Medium** - 3-4 hours initial setup, automatic after

---

## Option 3: Pre-built XCFramework with CI/CD

### Concept
Build the C library as XCFramework in CI/CD (GitHub Actions), attach to releases, use Tuist's `.binaryTarget` to download pre-built framework.

### Implementation Plan

#### Step 1: Create GitHub Actions Workflow
Create `.github/workflows/build-xcframework.yml`:
```yaml
name: Build XCFramework

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build for Device
        run: |
          xcodebuild -project NetworkLibStatic.xcodeproj \
            -scheme NetworkLibStatic \
            -sdk iphoneos \
            -configuration Release \
            -derivedDataPath build \
            ONLY_ACTIVE_ARCH=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            clean build
      
      - name: Build for Simulator
        run: |
          xcodebuild -project NetworkLibStatic.xcodeproj \
            -scheme NetworkLibStatic \
            -sdk iphonesimulator \
            -configuration Release \
            -derivedDataPath build \
            ONLY_ACTIVE_ARCH=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            clean build
      
      - name: Create XCFramework
        run: |
          xcodebuild -create-xcframework \
            -library build/Build/Products/Release-iphoneos/libNetworkLibStatic.a \
            -library build/Build/Products/Release-iphonesimulator/libNetworkLibStatic.a \
            -output NetworkLib.xcframework
      
      - name: Zip XCFramework
        run: zip -r NetworkLib.xcframework.zip NetworkLib.xcframework
      
      - name: Upload to Release
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ./NetworkLib.xcframework.zip
          asset_name: NetworkLib.xcframework.zip
          asset_content_type: application/zip
```

#### Step 2: Update Package.swift
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TorFrameworkBuilder",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TorFrameworkBuilder", targets: ["NetworkLib"])
    ],
    targets: [
        .binaryTarget(
            name: "NetworkLib",
            url: "https://github.com/user/TorFrameworkBuilder/releases/download/v1.0.99/NetworkLib.xcframework.zip",
            checksum: "abcdef123456..." // Compute with: swift package compute-checksum
        )
    ]
)
```

#### Step 3: Release Workflow
```bash
# 1. Make changes to C source
# 2. Commit and push
# 3. Create tag with patch applied
git tag -a v1.0.99 -m "XCFramework with applied patch"
git push origin v1.0.99

# 4. GitHub Actions builds and attaches XCFramework
# 5. Compute checksum
curl -L -o NetworkLib.xcframework.zip \
  https://github.com/user/TorFrameworkBuilder/releases/download/v1.0.99/NetworkLib.xcframework.zip
swift package compute-checksum NetworkLib.xcframework.zip

# 6. Update Package.swift with new checksum
# 7. Push updated Package.swift
```

#### Step 4: Use in TorApp
```swift
// Tuist/Dependencies.swift
.remote(
    url: "https://github.com/user/TorFrameworkBuilder.git",
    requirement: .exact("1.0.99")
)
```

### Pros
- ✅ Pre-built binary, fast TorApp builds
- ✅ Works with Tuist `.binaryTarget`
- ✅ Automated build in CI/CD
- ✅ Guaranteed patch applied (verified in CI)

### Cons
- ❌ Need to release for every change
- ❌ CI/CD setup overhead
- ❌ Large binary in git releases

### Effort
**High** - 4-6 hours initial setup, 10 min per release after

---

## Option 4: Tuist Local Plugin for C Compilation

### Concept
Create a Tuist plugin that compiles the C library with custom build settings, bypassing SPM entirely.

### Implementation Plan

#### Step 1: Create Tuist Plugin
```bash
cd ~/admin/TorApp
mkdir -p Tuist/Plugins/NetworkLibPlugin
cd Tuist/Plugins/NetworkLibPlugin
```

Create `Plugin.swift`:
```swift
import ProjectDescription

let plugin = Plugin(name: "NetworkLibPlugin")
```

Create `ProjectDescriptionHelpers/NetworkLibTarget.swift`:
```swift
import ProjectDescription

public extension Target {
    static func networkLib() -> Target {
        return Target(
            name: "NetworkLib",
            platform: .iOS,
            product: .staticLibrary,
            bundleId: "com.app.networklib",
            deploymentTarget: .iOS(targetVersion: "16.0", devices: [.iphone]),
            sources: [
                "Submodules/NetworkLib/Sources/Tor/tor-ios-fixed/src/**/*.c"
            ],
            headers: Headers(
                public: [],  // No public headers!
                private: ["Submodules/NetworkLib/Sources/Tor/tor-ios-fixed/**/*.h"],
                project: []
            ),
            settings: Settings(
                base: [
                    "HEADER_SEARCH_PATHS": [
                        "$(SRCROOT)/Submodules/NetworkLib/Sources/Tor/tor-ios-fixed",
                        // ... all other paths
                    ],
                    "GCC_PREPROCESSOR_DEFINITIONS": [
                        "HAVE_CONFIG_H=1",
                        "ENABLE_OPENSSL=1",
                        // ... all other defines
                    ],
                    "OTHER_CFLAGS": "-w -fno-modules -fno-objc-arc",
                    "SKIP_INSTALL": "YES"
                ]
            )
        )
    }
}
```

#### Step 2: Use Plugin in Project.swift
```swift
import ProjectDescription
import NetworkLibPlugin

let project = Project(
    name: "TorApp",
    targets: [
        .networkLib(),  // ← Custom compiled C library
        Target(
            name: "TorApp",
            platform: .iOS,
            product: .app,
            bundleId: "com.app.torapp",
            dependencies: [
                .target(name: "NetworkLib")  // ← Link to custom target
            ]
        )
    ]
)
```

#### Step 3: Setup Git Submodule
```bash
git submodule add https://github.com/user/TorFrameworkBuilder.git Submodules/NetworkLib
```

### Pros
- ✅ Full integration with Tuist workflow
- ✅ Custom compilation settings
- ✅ Headers remain private
- ✅ Source-based, no pre-built binaries

### Cons
- ❌ Tuist plugin API may have limitations
- ❌ Complex setup
- ❌ Slower builds (compiles C library every time)

### Effort
**Very High** - 6-8 hours initial research + setup

---

## Option 5: Separate Xcode Aggregate Target

### Concept
Keep SPM package as-is, but create a separate Xcode aggregate target in TorApp that compiles the C library with isolated settings, then link the resulting `.a` file.

### Implementation Plan

#### Step 1: Add Aggregate Target to TorApp
1. Open TorApp in Xcode (after `tuist generate`)
2. Add New Target → Other → Aggregate
3. Name: `BuildNetworkLib`
4. Add Run Script Phase:
   ```bash
   set -e
   
   NETWORKLIB_DIR="${SRCROOT}/../TorFrameworkBuilder"
   OUTPUT_DIR="${BUILT_PRODUCTS_DIR}/NetworkLib"
   
   # Compile C sources manually with clang
   mkdir -p "$OUTPUT_DIR/obj"
   
   # Find all .c files
   find "$NETWORKLIB_DIR/Sources/Tor/tor-ios-fixed/src" -name "*.c" | while read cfile; do
       obj="${OUTPUT_DIR}/obj/$(basename "$cfile" .c).o"
       clang -c "$cfile" -o "$obj" \
         -target arm64-apple-ios16.0-simulator \
         -isysroot "${SDKROOT}" \
         -I"$NETWORKLIB_DIR/Sources/Tor/tor-ios-fixed" \
         -DHAVE_CONFIG_H=1 \
         -DENABLE_OPENSSL=1 \
         -w -fno-modules
   done
   
   # Create static library
   ar rcs "$OUTPUT_DIR/libNetworkLib.a" "$OUTPUT_DIR/obj"/*.o
   ranlib "$OUTPUT_DIR/libNetworkLib.a"
   
   echo "✅ Built: $OUTPUT_DIR/libNetworkLib.a"
   ```

#### Step 2: Configure TorApp Target
1. Add `BuildNetworkLib` to Target Dependencies
2. Add `${BUILT_PRODUCTS_DIR}/NetworkLib/libNetworkLib.a` to Link Binary With Libraries
3. Add header search path: `$(SRCROOT)/../TorFrameworkBuilder/Sources/Tor/tor-ios-fixed`
4. Link system libraries: `z`, `resolv`

### Pros
- ✅ Works within existing Tuist/Xcode workflow
- ✅ Isolated compilation settings
- ✅ Headers remain private
- ✅ Automated on TorApp build

### Cons
- ❌ Tuist may regenerate and lose custom target
- ❌ Need to manually re-add after `tuist generate`
- ❌ Slower builds

### Effort
**Medium** - 3-4 hours initial, 5 min after each `tuist generate`

---

## Recommended Approach

### If Tuist provides a solution:
✅ **Stay with current SPM + Tuist approach** (least effort)

### If no Tuist solution:
1. **Short-term (Quick fix)**: **Option 1 - Direct Xcode Static Library** 
   - Fastest to implement
   - Proven approach
   - Good for immediate unblocking

2. **Long-term (Best solution)**: **Option 3 - Pre-built XCFramework with CI/CD**
   - Automated builds
   - Fast TorApp compilation
   - Clean separation of concerns
   - Industry standard approach

### Not Recommended:
- ❌ Option 4 (Tuist Plugin) - too complex, uncertain outcome
- ❌ Option 5 (Aggregate Target) - fights against Tuist workflow

---

## Next Steps

1. Post question on Tuist forum
2. Wait 3-5 days for response
3. If no solution → Implement **Option 1** immediately (2-3 hours)
4. In parallel, set up **Option 3** CI/CD (can take 1-2 weeks to perfect)
5. Once Option 3 is stable, migrate from Option 1

**Estimated total time to permanent solution**: 2-3 weeks



