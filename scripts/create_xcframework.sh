#!/bin/bash
set -e

# Создание XCFramework с объединением всех библиотек

FRAMEWORK_NAME="Tor"
FRAMEWORK_VERSION="0.4.8.19"
OUTPUT_DIR="$(pwd)/output"
XCFRAMEWORK_DIR="$(pwd)/output/${FRAMEWORK_NAME}.xcframework"
BUILD_DIR="$(pwd)/build/xcframework"

echo "📦 Создание ${FRAMEWORK_NAME}.xcframework..."
echo ""

# Проверка наличия библиотек
OPENSSL_DIR="${OUTPUT_DIR}/openssl"
LIBEVENT_DIR="${OUTPUT_DIR}/libevent"
XZ_DIR="${OUTPUT_DIR}/xz"
TOR_BUILD_DIR="$(pwd)/build/tor/tor-src"

if [ ! -d "$OPENSSL_DIR" ] || [ ! -d "$LIBEVENT_DIR" ] || [ ! -d "$XZ_DIR" ]; then
    echo "❌ Зависимости не найдены. Сначала выполните: bash scripts/build_all.sh"
    exit 1
fi

if [ ! -d "$TOR_BUILD_DIR" ]; then
    echo "❌ Tor build не найден в $TOR_BUILD_DIR"
    exit 1
fi

# Очистка предыдущих сборок
rm -rf "$BUILD_DIR"
rm -rf "$XCFRAMEWORK_DIR"
mkdir -p "$BUILD_DIR"

# Создание директории для объединенной библиотеки
COMBINED_LIB_DIR="${BUILD_DIR}/combined"
mkdir -p "$COMBINED_LIB_DIR"

echo "🔗 Объединение всех статических библиотек..."

# Поиск всех статических библиотек Tor
echo "📋 Поиск библиотек Tor..."
TOR_LIBS=$(find "$TOR_BUILD_DIR/src" -name "*.a" -type f)

if [ -z "$TOR_LIBS" ]; then
    echo "❌ Статические библиотеки Tor не найдены"
    exit 1
fi

echo "Найдены библиотеки Tor:"
echo "$TOR_LIBS" | while read lib; do
    echo "  • $(basename $lib)"
done
echo ""

# Создание объединенной библиотеки используя libtool
echo "🔨 Создание libTor.a..."

# Собираем все библиотеки в один список
ALL_LIBS=""
ALL_LIBS="$ALL_LIBS ${OPENSSL_DIR}/lib/libssl.a"
ALL_LIBS="$ALL_LIBS ${OPENSSL_DIR}/lib/libcrypto.a"
ALL_LIBS="$ALL_LIBS ${LIBEVENT_DIR}/lib/libevent.a"
ALL_LIBS="$ALL_LIBS ${LIBEVENT_DIR}/lib/libevent_core.a"
ALL_LIBS="$ALL_LIBS ${LIBEVENT_DIR}/lib/libevent_extra.a"
ALL_LIBS="$ALL_LIBS ${XZ_DIR}/lib/liblzma.a"

# Добавляем все библиотеки Tor
while IFS= read -r lib; do
    ALL_LIBS="$ALL_LIBS $lib"
done <<< "$TOR_LIBS"

# Используем libtool для создания объединенной библиотеки
libtool -static -o "${COMBINED_LIB_DIR}/libTor.a" $ALL_LIBS

echo "✅ libTor.a создан ($(du -h ${COMBINED_LIB_DIR}/libTor.a | cut -f1))"
echo ""

# Создание структуры Framework
echo "🏗️  Создание структуры Framework..."

FRAMEWORK_BUILD_DIR="${BUILD_DIR}/${FRAMEWORK_NAME}.framework"
mkdir -p "${FRAMEWORK_BUILD_DIR}/Headers"
mkdir -p "${FRAMEWORK_BUILD_DIR}/Modules"

# Копирование библиотеки
cp "${COMBINED_LIB_DIR}/libTor.a" "${FRAMEWORK_BUILD_DIR}/${FRAMEWORK_NAME}"

# Копирование заголовочных файлов
echo "📋 Копирование заголовочных файлов..."

# OpenSSL headers
echo "  • OpenSSL headers..."
cp -R "${OPENSSL_DIR}/include/openssl" "${FRAMEWORK_BUILD_DIR}/Headers/" 2>/dev/null || true

# libevent headers
echo "  • libevent headers..."
cp "${LIBEVENT_DIR}"/include/*.h "${FRAMEWORK_BUILD_DIR}/Headers/" 2>/dev/null || true
cp -R "${LIBEVENT_DIR}/include/event2" "${FRAMEWORK_BUILD_DIR}/Headers/" 2>/dev/null || true

# xz headers
echo "  • xz headers..."
cp "${XZ_DIR}"/include/*.h "${FRAMEWORK_BUILD_DIR}/Headers/" 2>/dev/null || true

# Tor headers (основные публичные заголовки)
echo "  • Tor headers..."
find "$TOR_BUILD_DIR/src" -name "*.h" -type f | while read header; do
    # Копируем только основные публичные заголовки, избегая внутренних
    if [[ $header != *"/or/"* ]] || [[ $header == *"or.h" ]] || [[ $header == *"or_api.h" ]]; then
        cp "$header" "${FRAMEWORK_BUILD_DIR}/Headers/" 2>/dev/null || true
    fi
done

# Копирование wrapper файлов если они существуют
if [ -f "$(pwd)/wrapper/Tor.h" ]; then
    echo "  • Wrapper headers..."
    cp "$(pwd)/wrapper/Tor.h" "${FRAMEWORK_BUILD_DIR}/Headers/"
    cp "$(pwd)/wrapper/TorWrapper.h" "${FRAMEWORK_BUILD_DIR}/Headers/"
fi

# Создание Info.plist
echo "📄 Создание Info.plist..."
cat > "${FRAMEWORK_BUILD_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>org.torproject.${FRAMEWORK_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${FRAMEWORK_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${FRAMEWORK_VERSION}</string>
    <key>MinimumOSVersion</key>
    <string>16.0</string>
</dict>
</plist>
EOF

# Копирование module.modulemap если существует
if [ -f "$(pwd)/wrapper/module.modulemap" ]; then
    cp "$(pwd)/wrapper/module.modulemap" "${FRAMEWORK_BUILD_DIR}/Modules/"
else
    # Создание базового module.modulemap
    cat > "${FRAMEWORK_BUILD_DIR}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "Tor.h"
    export *
    module * { export * }
}
EOF
fi

echo ""
echo "📦 Создание XCFramework..."

# Создание XCFramework
xcodebuild -create-xcframework \
    -framework "${FRAMEWORK_BUILD_DIR}" \
    -output "$XCFRAMEWORK_DIR"

echo ""
echo "✅ ${FRAMEWORK_NAME}.xcframework успешно создан!"
echo "📁 Путь: $XCFRAMEWORK_DIR"
echo "📊 Размер: $(du -sh $XCFRAMEWORK_DIR | cut -f1)"
echo ""
echo "📋 Структура:"
ls -la "$XCFRAMEWORK_DIR"
echo ""
echo "📋 Заголовочные файлы:"
ls -la "${FRAMEWORK_BUILD_DIR}/Headers" | head -20
echo ""
echo "🎯 Следующий шаг: bash scripts/deploy.sh"

