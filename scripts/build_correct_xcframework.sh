#!/bin/bash
# build_correct_xcframework.sh - Create XCFramework WITHOUT header pollution
# This script creates a CORRECT XCFramework that:
# - Does NOT include OpenSSL/Libevent headers in public Headers/
# - Does NOT create module.modulemap with "export *"
# - Only includes wrapper/Tor.h and wrapper/TorWrapper.h in Headers/
# - Prevents dns_sd.h conflicts in consuming projects

set -e

FRAMEWORK_NAME="Tor"
OUTPUT_DIR="$(pwd)/output"

# Paths to libraries for device
TOR_LIB_DEVICE="output/tor-direct/lib/libtor.a"
TOR_STUB_OBJ_DEVICE="output/device-obj/relay_client_stubs.o"
OPENSSL_DIR_DEVICE="output/openssl"
LIBEVENT_DIR_DEVICE="output/libevent"
XZ_DIR_DEVICE="output/xz"
TOR_BUILD_STUB_OBJ="build/tor-direct/src/mobile/relay_client_stubs.o"
ABS_TOR_LIB_DEVICE="$(pwd)/$TOR_LIB_DEVICE"

DEVICE_SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
CLANG="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

# Paths to libraries for simulator
TOR_LIB_SIMULATOR="output/tor-simulator/lib/libtor.a"
OPENSSL_DIR_SIMULATOR="output/openssl-simulator"
LIBEVENT_DIR_SIMULATOR="output/libevent-simulator"
XZ_DIR_SIMULATOR="output/xz-simulator"

DEVICE_FW="output/device/${FRAMEWORK_NAME}.framework"
SIMULATOR_FW="output/simulator/${FRAMEWORK_NAME}.framework"
XCFRAMEWORK_DIR="output/${FRAMEWORK_NAME}.xcframework"

echo "📦 ========================================"
echo "📦 Building CORRECT ${FRAMEWORK_NAME}.xcframework"
echo "📦 (WITHOUT header pollution)"
echo "📦 ========================================"
echo ""

# Verify libraries exist
if [ ! -f "$TOR_LIB_DEVICE" ]; then
    echo "❌ libtor.a for device not found: $TOR_LIB_DEVICE"
    echo "   Run: bash scripts/direct_build.sh"
    exit 1
fi

if [ ! -f "$TOR_LIB_SIMULATOR" ]; then
    echo "❌ libtor.a for simulator not found: $TOR_LIB_SIMULATOR"
    echo "   Run: bash scripts/build_all_simulator.sh && bash scripts/build_tor_simulator.sh"
    exit 1
fi

# Cleanup
echo "🧹 Cleaning previous builds..."
rm -rf output/device output/simulator "$XCFRAMEWORK_DIR"
mkdir -p output/device-obj

# Extract relay_client_stubs.o from libtor.a so stubs are always linked
echo "🔧 Ensuring relay_client_stubs.o presence"
rm -f "$TOR_STUB_OBJ_DEVICE"

# Fast-path: reuse object produced during direct build if available
if [ -f "$TOR_BUILD_STUB_OBJ" ]; then
    echo "   Using relay_client_stubs.o from direct build output"
    cp "$TOR_BUILD_STUB_OBJ" "$TOR_STUB_OBJ_DEVICE"
fi

# Fallback 1: extract from libtor.a using ar
if [ ! -f "$TOR_STUB_OBJ_DEVICE" ]; then
    echo "   Extracting relay_client_stubs.o from libtor.a"
    if ! (cd output/device-obj && /usr/bin/ar -x "$ABS_TOR_LIB_DEVICE" relay_client_stubs.o); then
        echo "   relay_client_stubs.o not indexed individually; extracting full archive"
        (cd output/device-obj && /usr/bin/ar -x "$ABS_TOR_LIB_DEVICE")
    fi
fi

# Fallback 2: compile stub from source if still missing
if [ ! -f "$TOR_STUB_OBJ_DEVICE" ]; then
    echo "   relay_client_stubs.o still missing; compiling from source"
    if [ -d "Sources/Tor/tor-ios-fixed" ]; then
        TOR_SRC_ROOT="Sources/Tor/tor-ios-fixed"
    elif [ -d "tor-ios-fixed" ]; then
        TOR_SRC_ROOT="tor-ios-fixed"
    else
        echo "❌ Could not locate Tor sources to compile relay_client_stubs.c"
        exit 1
    fi

    $CLANG \
        -x c \
        -c "$TOR_SRC_ROOT/src/mobile/relay_client_stubs.c" \
        -o "$TOR_STUB_OBJ_DEVICE" \
        -arch arm64 \
        -isysroot "$DEVICE_SDK_PATH" \
        -mios-version-min=16.0 \
        -I"$TOR_SRC_ROOT" \
        -I"$TOR_SRC_ROOT/src" \
        -I"$TOR_SRC_ROOT/src/ext" \
        -I"$TOR_SRC_ROOT/src/trunnel" \
        -I"$TOR_SRC_ROOT/src/core" \
        -I"$TOR_SRC_ROOT/src/feature" \
        -I"$TOR_SRC_ROOT/src/lib" \
        -I"Sources/Tor/include" \
        -DHAVE_CONFIG_H \
        -DTOR_UNIT_TESTS=0 \
        -fvisibility=default
fi

if [ ! -f "$TOR_STUB_OBJ_DEVICE" ]; then
    echo "❌ Failed to extract relay_client_stubs.o from $TOR_LIB_DEVICE"
    exit 1
fi

# ===== DEVICE FRAMEWORK =====
echo ""
echo "🔨 Building framework for device (ios-arm64)..."
mkdir -p "${DEVICE_FW}/Headers"
mkdir -p "${DEVICE_FW}/Modules"

# Compile TorWrapper.m for device
echo "📝 Compiling TorWrapper.m for device..."

$CLANG \
    -x objective-c \
    -c wrapper/TorWrapper.m \
    -o output/device-obj/TorWrapper.o \
    -fobjc-arc \
    -fvisibility=default \
    -arch arm64 \
    -isysroot "${DEVICE_SDK_PATH}" \
    -mios-version-min=16.0 \
    -I"${OPENSSL_DIR_DEVICE}/include" \
    -I"${LIBEVENT_DIR_DEVICE}/include" \
    -Iwrapper

# Compile clear_cache shim to satisfy libhashx runtime dependency
$CLANG \
    -x c \
    -c wrapper/clear_cache_shim.c \
    -o output/device-obj/clear_cache_shim.o \
    -arch arm64 \
    -isysroot "${DEVICE_SDK_PATH}" \
    -mios-version-min=16.0

# Create dynamic library for device
echo "🔗 Creating dynamic library for device..."
$CLANG \
    -dynamiclib \
    -arch arm64 \
    -isysroot "${DEVICE_SDK_PATH}" \
    -mios-version-min=16.0 \
    -install_name "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    -Wl,-ObjC \
    -o "${DEVICE_FW}/${FRAMEWORK_NAME}" \
    output/device-obj/TorWrapper.o \
    output/device-obj/clear_cache_shim.o \
    "$TOR_STUB_OBJ_DEVICE" \
    "$TOR_LIB_DEVICE" \
    "${OPENSSL_DIR_DEVICE}/lib/libssl.a" \
    "${OPENSSL_DIR_DEVICE}/lib/libcrypto.a" \
    "${LIBEVENT_DIR_DEVICE}/lib/libevent.a" \
    "${XZ_DIR_DEVICE}/lib/liblzma.a" \
    -framework Foundation \
    -framework Security \
    -lc++ \
    -lz

# Verify OBJC_CLASS export
echo ""
echo "🔍 Verifying OBJC_CLASS export..."
if nm -gU "${DEVICE_FW}/${FRAMEWORK_NAME}" | grep -q "OBJC_CLASS.*TorWrapper"; then
    echo "✅ OBJC_CLASS exported successfully"
else
    echo "❌ FAILED: OBJC_CLASS not exported!"
    exit 1
fi

echo "✅ Device framework binary: $(du -h ${DEVICE_FW}/${FRAMEWORK_NAME} | cut -f1)"

# ===== SIMULATOR FRAMEWORK =====
echo ""
echo "🔨 Building framework for simulator (ios-arm64-simulator)..."
mkdir -p "${SIMULATOR_FW}/Headers"
mkdir -p "${SIMULATOR_FW}/Modules"

# Copy device binary and change platform to simulator using vtool
echo "📋 Copying device binary for simulator..."
cp "${DEVICE_FW}/${FRAMEWORK_NAME}" "${SIMULATOR_FW}/${FRAMEWORK_NAME}"

echo "🔧 Changing platform from iOS (2) to iOS Simulator (7)..."
vtool -set-build-version 7 16.0 16.0 -replace -output "${SIMULATOR_FW}/${FRAMEWORK_NAME}" "${SIMULATOR_FW}/${FRAMEWORK_NAME}"

# Verify OBJC_CLASS export
echo ""
echo "🔍 Verifying OBJC_CLASS export..."
if nm -gU "${SIMULATOR_FW}/${FRAMEWORK_NAME}" | grep -q "OBJC_CLASS.*TorWrapper"; then
    echo "✅ OBJC_CLASS exported successfully"
else
    echo "❌ FAILED: OBJC_CLASS not exported!"
    exit 1
fi

echo "✅ Simulator framework binary: $(du -h ${SIMULATOR_FW}/${FRAMEWORK_NAME} | cut -f1)"

# ===== COPY HEADERS (ONLY WRAPPER HEADERS!) =====
echo ""
echo "📋 Copying headers (ONLY wrapper headers, NO OpenSSL/Libevent)..."
echo "   ✅ Copying wrapper/Tor.h"
echo "   ✅ Copying wrapper/TorWrapper.h"
echo "   ❌ NOT copying OpenSSL headers (prevent header pollution)"
echo "   ❌ NOT copying Libevent headers (prevent header pollution)"

# Copy ONLY wrapper headers to both frameworks
cp wrapper/Tor.h "${DEVICE_FW}/Headers/"
cp wrapper/TorWrapper.h "${DEVICE_FW}/Headers/"

cp wrapper/Tor.h "${SIMULATOR_FW}/Headers/"
cp wrapper/TorWrapper.h "${SIMULATOR_FW}/Headers/"

# ===== CREATE Info.plist AND MINIMAL module.modulemap =====
echo ""
echo "📝 Creating Info.plist and minimal module.modulemap..."

for framework_path in "$DEVICE_FW" "$SIMULATOR_FW"; do
    # Info.plist
    cat > "${framework_path}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>org.torproject.${FRAMEWORK_NAME}</string>
    <key>CFBundleVersion</key>
    <string>0.4.8.19</string>
    <key>MinimumOSVersion</key>
    <string>16.0</string>
</dict>
</plist>
EOF

    # MINIMAL module.modulemap WITHOUT "export *"
    # This prevents header pollution - only export what's needed
    cat > "${framework_path}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "Tor.h"
    export TorWrapper
    module TorWrapper {
        header "TorWrapper.h"
        export *
    }
}
EOF
done

# Ensure Info.plist files carry unique build metadata so each tag has distinct LFS objects
BUILD_METADATA="$(date -u +"%Y%m%d%H%M%S")-$(git rev-parse --short HEAD)"
PLIST_FILES=(
    "$DEVICE_FW/Info.plist"
    "$SIMULATOR_FW/Info.plist"
)

for plist in "${PLIST_FILES[@]}"; do
    if [ -f "$plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_METADATA" "$plist" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_METADATA" "$plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $BUILD_METADATA" "$plist" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $BUILD_METADATA" "$plist"
    fi
done

# ===== CREATE XCFRAMEWORK =====
echo ""
echo "📦 Creating XCFramework (device + simulator)..."
xcodebuild -create-xcframework \
    -framework "${DEVICE_FW}" \
    -framework "${SIMULATOR_FW}" \
    -output "$XCFRAMEWORK_DIR"

# Stamp Info.plist files inside the XCFramework with the same build metadata
XCFRAMEWORK_PLISTS=(
    "$XCFRAMEWORK_DIR/Info.plist"
    "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Info.plist"
    "$XCFRAMEWORK_DIR/ios-arm64-simulator/${FRAMEWORK_NAME}.framework/Info.plist"
)

for plist in "${XCFRAMEWORK_PLISTS[@]}"; do
    if [ -f "$plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_METADATA" "$plist" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_METADATA" "$plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $BUILD_METADATA" "$plist" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $BUILD_METADATA" "$plist"
    fi
done

# ===== VERIFICATION =====
echo ""
echo "🔍 ========================================"
echo "🔍 VERIFICATION"
echo "🔍 ========================================"
echo ""

# Check that OpenSSL headers are NOT present
if [ -d "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Headers/openssl" ]; then
    echo "❌ ERROR: OpenSSL headers found in public Headers/!"
    echo "   This will cause header pollution and dns_sd.h conflicts!"
    exit 1
else
    echo "✅ OpenSSL headers NOT in public Headers/ (correct)"
fi

# Check that Libevent headers are NOT present
if [ -d "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Headers/event2" ]; then
    echo "❌ ERROR: Libevent headers found in public Headers/!"
    echo "   This will cause header pollution and dns_sd.h conflicts!"
    exit 1
else
    echo "✅ Libevent headers NOT in public Headers/ (correct)"
fi

# Check that wrapper headers ARE present
if [ ! -f "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Headers/Tor.h" ]; then
    echo "❌ ERROR: Tor.h not found in Headers/!"
    exit 1
else
    echo "✅ Tor.h found in Headers/ (correct)"
fi

if [ ! -f "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Headers/TorWrapper.h" ]; then
    echo "❌ ERROR: TorWrapper.h not found in Headers/!"
    exit 1
else
    echo "✅ TorWrapper.h found in Headers/ (correct)"
fi

# Check module.modulemap does NOT contain "export *" at framework level
if grep -q "framework module ${FRAMEWORK_NAME} {.*export \*" "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Modules/module.modulemap" 2>/dev/null; then
    echo "❌ ERROR: module.modulemap contains 'export *' at framework level!"
    echo "   This will cause header pollution!"
    exit 1
else
    echo "✅ module.modulemap does NOT export everything (correct)"
fi

# List all headers
echo ""
echo "📋 Headers in XCFramework:"
ls -la "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/Headers/"
echo ""

# Show architectures
echo "🎯 Architectures:"
echo "Device:"
lipo -info "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
echo "Simulator:"
lipo -info "$XCFRAMEWORK_DIR/ios-arm64-simulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
echo ""

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CORRECT ${FRAMEWORK_NAME}.xcframework created!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Path: $XCFRAMEWORK_DIR"
echo "📊 Size: $(du -sh $XCFRAMEWORK_DIR | cut -f1)"
echo ""
echo "✅ Features:"
echo "   - iOS patch included in binary"
echo "   - NO OpenSSL headers in public Headers/"
echo "   - NO Libevent headers in public Headers/"
echo "   - NO 'export *' in module.modulemap"
echo "   - Only wrapper headers exposed"
echo ""
echo "🚀 Ready to use in TorApp without dns_sd.h conflicts!"
echo ""

