#!/bin/bash
# Создание финального Tor.xcframework

set -e

cd "$(dirname "$0")"

FRAMEWORK_NAME="Tor"
OUTPUT_DIR="output"
TOR_LIB="output/tor-direct/lib/libtor.a"
OPENSSL_DIR="output/openssl"
LIBEVENT_DIR="output/libevent"
XZ_DIR="output/xz"
FRAMEWORK_DIR="output/${FRAMEWORK_NAME}.framework"
XCFRAMEWORK_DIR="output/${FRAMEWORK_NAME}.xcframework"

echo "📦 Создание ${FRAMEWORK_NAME}.xcframework"
echo "=========================================="

# Проверка библиотек
if [ ! -f "$TOR_LIB" ]; then
    echo "❌ libtor.a не найдена"
    exit 1
fi

# Очистка
rm -rf "$FRAMEWORK_DIR" "$XCFRAMEWORK_DIR"
mkdir -p "${FRAMEWORK_DIR}/Headers"
mkdir -p "${FRAMEWORK_DIR}/Modules"

echo "🔗 Объединение всех библиотек..."

# Объединить все библиотеки
libtool -static -o "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}" \
    "$TOR_LIB" \
    "${OPENSSL_DIR}/lib/libssl.a" \
    "${OPENSSL_DIR}/lib/libcrypto.a" \
    "${LIBEVENT_DIR}/lib/libevent.a" \
    "${LIBEVENT_DIR}/lib/libevent_core.a" \
    "${XZ_DIR}/lib/liblzma.a"

echo "✅ Объединенная библиотека: $(du -h ${FRAMEWORK_DIR}/${FRAMEWORK_NAME} | cut -f1)"

# Копирование заголовков
echo "📋 Копирование headers..."
cp -R "${OPENSSL_DIR}/include/openssl" "${FRAMEWORK_DIR}/Headers/" 2>/dev/null || true
cp "${LIBEVENT_DIR}"/include/*.h "${FRAMEWORK_DIR}/Headers/" 2>/dev/null || true
cp -R "${LIBEVENT_DIR}/include/event2" "${FRAMEWORK_DIR}/Headers/" 2>/dev/null || true
cp wrapper/*.h "${FRAMEWORK_DIR}/Headers/" 2>/dev/null || true

# Info.plist
cat > "${FRAMEWORK_DIR}/Info.plist" << EOF
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
    <key>CFBundleShortVersionString</key>
    <string>0.4.8.19</string>
    <key>MinimumOSVersion</key>
    <string>16.0</string>
</dict>
</plist>
EOF

# module.modulemap
cp wrapper/module.modulemap "${FRAMEWORK_DIR}/Modules/" 2>/dev/null || \
cat > "${FRAMEWORK_DIR}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "Tor.h"
    export *
    module * { export * }
}
EOF

# Создание XCFramework
echo "📦 Создание XCFramework..."
xcodebuild -create-xcframework \
    -framework "${FRAMEWORK_DIR}" \
    -output "$XCFRAMEWORK_DIR"

echo ""
echo "✅ ${FRAMEWORK_NAME}.xcframework создан!"
echo "📁 Путь: $XCFRAMEWORK_DIR"
echo "📊 Размер: $(du -sh $XCFRAMEWORK_DIR | cut -f1)"
echo ""
echo "🎯 Следующий шаг: bash scripts/deploy.sh"

