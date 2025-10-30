#!/bin/bash
set -e

echo "🔨 Building TorFrameworkBuilder XCFramework with patched source..."

# Clean
rm -rf .build output/Tor.xcframework

# Build for device
echo "📱 Building for iOS device..."
swift build -c release --triple arm64-apple-ios16.0

# Build for simulator  
echo "🖥️  Building for iOS simulator..."
swift build -c release --triple arm64-apple-ios16.0-simulator

# Extract static libs
mkdir -p output/tmp/device output/tmp/simulator
cp .build/arm64-apple-ios/release/libTorFrameworkBuilder.a output/tmp/device/ 2>/dev/null || \
cp .build/release/libTorFrameworkBuilder.a output/tmp/device/

cp .build/arm64-apple-ios-simulator/release/libTorFrameworkBuilder.a output/tmp/simulator/ 2>/dev/null || \
cp .build/release/libTorFrameworkBuilder.a output/tmp/simulator/

echo "✅ Static libs built successfully!"
echo "📦 Creating XCFramework..."

# Create XCFramework
xcodebuild -create-xcframework \
  -library output/tmp/device/libTorFrameworkBuilder.a \
  -library output/tmp/simulator/libTorFrameworkBuilder.a \
  -output output/Tor.xcframework

rm -rf output/tmp

echo "🎉 XCFramework created at output/Tor.xcframework"
ls -lh output/Tor.xcframework/
