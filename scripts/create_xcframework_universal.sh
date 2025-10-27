#!/bin/bash
set -e

# Создание универсального XCFramework (device + simulator)

FRAMEWORK_NAME="Tor"
OUTPUT_DIR="$(pwd)/output"

# Пути к библиотекам для устройства
TOR_LIB_DEVICE="output/tor-direct/lib/libtor.a"
OPENSSL_DIR_DEVICE="output/openssl"
LIBEVENT_DIR_DEVICE="output/libevent"
XZ_DIR_DEVICE="output/xz"

# Пути к библиотекам для симулятора
TOR_LIB_SIMULATOR="output/tor-simulator/lib/libtor.a"
OPENSSL_DIR_SIMULATOR="output/openssl-simulator"
LIBEVENT_DIR_SIMULATOR="output/libevent-simulator"
XZ_DIR_SIMULATOR="output/xz-simulator"

DEVICE_FW="output/device/${FRAMEWORK_NAME}.framework"
SIMULATOR_FW="output/simulator/${FRAMEWORK_NAME}.framework"
XCFRAMEWORK_DIR="output/${FRAMEWORK_NAME}.xcframework"

echo "📦 Создание универсального ${FRAMEWORK_NAME}.xcframework"
echo "=========================================================="

# Проверка библиотек для устройства
if [ ! -f "$TOR_LIB_DEVICE" ]; then
    echo "❌ libtor.a для устройства не найдена"
    echo "Выполните: bash scripts/direct_build.sh"
    exit 1
fi

# Проверка библиотек для симулятора
if [ ! -f "$TOR_LIB_SIMULATOR" ]; then
    echo "❌ libtor.a для симулятора не найдена"
    echo "Выполните: bash scripts/build_all_simulator.sh && bash scripts/build_tor_simulator.sh"
    exit 1
fi

# Очистка
rm -rf output/device output/simulator "$XCFRAMEWORK_DIR"

# ===== DEVICE FRAMEWORK =====
echo "🔨 Создание framework для устройства..."
mkdir -p "${DEVICE_FW}/Headers"
mkdir -p "${DEVICE_FW}/Modules"

# Объединение библиотек для устройства
libtool -static -o "${DEVICE_FW}/${FRAMEWORK_NAME}" \
    "$TOR_LIB_DEVICE" \
    "${OPENSSL_DIR_DEVICE}/lib/libssl.a" \
    "${OPENSSL_DIR_DEVICE}/lib/libcrypto.a" \
    "${LIBEVENT_DIR_DEVICE}/lib/libevent.a" \
    "${LIBEVENT_DIR_DEVICE}/lib/libevent_core.a" \
    "${XZ_DIR_DEVICE}/lib/liblzma.a"

echo "✅ Device framework: $(du -h ${DEVICE_FW}/${FRAMEWORK_NAME} | cut -f1)"

# ===== SIMULATOR FRAMEWORK =====
echo "🔨 Создание framework для симулятора..."
mkdir -p "${SIMULATOR_FW}/Headers"
mkdir -p "${SIMULATOR_FW}/Modules"

# Объединение библиотек для симулятора
libtool -static -o "${SIMULATOR_FW}/${FRAMEWORK_NAME}" \
    "$TOR_LIB_SIMULATOR" \
    "${OPENSSL_DIR_SIMULATOR}/lib/libssl.a" \
    "${OPENSSL_DIR_SIMULATOR}/lib/libcrypto.a" \
    "${LIBEVENT_DIR_SIMULATOR}/lib/libevent.a" \
    "${LIBEVENT_DIR_SIMULATOR}/lib/libevent_core.a" \
    "${XZ_DIR_SIMULATOR}/lib/liblzma.a"

echo "✅ Simulator framework: $(du -h ${SIMULATOR_FW}/${FRAMEWORK_NAME} | cut -f1)"

# Копирование заголовков
echo "📋 Копирование headers..."

# Device framework - используем device headers
cp -R "${OPENSSL_DIR_DEVICE}/include/openssl" "${DEVICE_FW}/Headers/" 2>/dev/null || true
cp "${LIBEVENT_DIR_DEVICE}"/include/*.h "${DEVICE_FW}/Headers/" 2>/dev/null || true
cp -R "${LIBEVENT_DIR_DEVICE}/include/event2" "${DEVICE_FW}/Headers/" 2>/dev/null || true
cp wrapper/*.h "${DEVICE_FW}/Headers/" 2>/dev/null || true

# Simulator framework - используем simulator headers
cp -R "${OPENSSL_DIR_SIMULATOR}/include/openssl" "${SIMULATOR_FW}/Headers/" 2>/dev/null || true
cp "${LIBEVENT_DIR_SIMULATOR}"/include/*.h "${SIMULATOR_FW}/Headers/" 2>/dev/null || true
cp -R "${LIBEVENT_DIR_SIMULATOR}/include/event2" "${SIMULATOR_FW}/Headers/" 2>/dev/null || true
cp wrapper/*.h "${SIMULATOR_FW}/Headers/" 2>/dev/null || true

# Info.plist и module.modulemap для обоих
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

    # module.modulemap
    cp wrapper/module.modulemap "${framework_path}/Modules/" 2>/dev/null || \
    cat > "${framework_path}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "Tor.h"
    export *
    module * { export * }
}
EOF
done

# Создание XCFramework с обеими платформами
echo ""
echo "📦 Создание XCFramework (device + simulator)..."

xcodebuild -create-xcframework \
    -framework "${DEVICE_FW}" \
    -framework "${SIMULATOR_FW}" \
    -output "$XCFRAMEWORK_DIR"

echo ""
echo "✅ Универсальный ${FRAMEWORK_NAME}.xcframework создан!"
echo "📁 Путь: $XCFRAMEWORK_DIR"
echo "📊 Размер: $(du -sh $XCFRAMEWORK_DIR | cut -f1)"
echo ""
echo "🔍 Структура:"
ls -la "$XCFRAMEWORK_DIR"
echo ""
echo "🎯 Проверка архитектур:"
echo "Device:"
lipo -info "$XCFRAMEWORK_DIR/ios-arm64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
echo "Simulator:"
lipo -info "$XCFRAMEWORK_DIR/ios-arm64-simulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
echo ""
echo "✅ Готово к использованию в Simulator и на устройствах!"
