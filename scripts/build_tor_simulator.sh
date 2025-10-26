#!/bin/bash
set -e

# Сборка Tor 0.4.8.19 для iOS Simulator (arm64)
# Симулятор ближе к macOS, поэтому configure должен работать

VERSION="0.4.8.19"
SOURCE_DIR="$(pwd)/tor-${VERSION}"
BUILD_DIR="$(pwd)/build/tor-sim"
OUTPUT_DIR="$(pwd)/output/tor-sim"
OPENSSL_DIR="$(pwd)/output/openssl"
LIBEVENT_DIR="$(pwd)/output/libevent"
XZ_DIR="$(pwd)/output/xz"

echo "🧅 Сборка Tor ${VERSION} для iOS Simulator (arm64)..."

# Проверка наличия исходников Tor
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Исходники Tor не найдены в $SOURCE_DIR"
    exit 1
fi

# Проверка наличия зависимостей
if [ ! -d "$OPENSSL_DIR" ] || [ ! -d "$LIBEVENT_DIR" ] || [ ! -d "$XZ_DIR" ]; then
    echo "❌ Зависимости не найдены. Выполните build_all.sh сначала"
    exit 1
fi

# Очистка
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# Настройки для iOS Simulator
export PLATFORM="iPhoneSimulator"
export MIN_IOS_VERSION="16.0"
export ARCH="arm64"

# Поиск SDK
DEVELOPER=$(xcode-select --print-path)
PLATFORM_PATH="${DEVELOPER}/Platforms/${PLATFORM}.platform"
SDK_PATH="${PLATFORM_PATH}/Developer/SDKs/${PLATFORM}.sdk"

if [ ! -d "$SDK_PATH" ]; then
    echo "❌ SDK не найден: $SDK_PATH"
    exit 1
fi

echo "🛠  SDK: $SDK_PATH"

# Настройка переменных окружения
export CC="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export CXX="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
export CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-simulator-version-min=${MIN_IOS_VERSION} -I${OPENSSL_DIR}/include -I${LIBEVENT_DIR}/include -I${XZ_DIR}/include"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -L${OPENSSL_DIR}/lib -L${LIBEVENT_DIR}/lib -L${XZ_DIR}/lib"
export LIBS="-lssl -lcrypto -levent -llzma"

# PKG_CONFIG настройки
export PKG_CONFIG_PATH="${OPENSSL_DIR}/lib/pkgconfig:${LIBEVENT_DIR}/lib/pkgconfig:${XZ_DIR}/lib/pkgconfig"

# Копирование исходников
echo "📋 Копирование исходников..."
cp -R "$SOURCE_DIR" "$BUILD_DIR/tor-src"
cd "$BUILD_DIR/tor-src"

# Конфигурация для iOS Simulator (без кросс-компиляции!)
echo "⚙️  Конфигурация Tor для Simulator..."
echo "📝 Вывод configure..."
echo ""

./configure \
    --prefix="$OUTPUT_DIR" \
    --disable-tool-name-check \
    --disable-unittests \
    --disable-system-torrc \
    --disable-systemd \
    --disable-lzma \
    --disable-zstd \
    --disable-gcc-hardening \
    --with-openssl-dir="$OPENSSL_DIR" \
    --with-libevent-dir="$LIBEVENT_DIR" \
    --enable-static-openssl \
    --enable-static-libevent \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}" \
    LIBS="${LIBS}" 2>&1 | tee configure.log

echo ""
echo "✅ Конфигурация завершена"

# Сборка
echo "🔨 Компиляция Tor..."
make -j$(sysctl -n hw.ncpu)

# Установка
echo "📦 Установка в $OUTPUT_DIR..."
make install

cd ../..

echo "✅ Tor ${VERSION} для Simulator успешно собран!"
echo "📁 Путь: $OUTPUT_DIR"
echo ""
echo "Библиотеки:"
find "$BUILD_DIR/tor-src" -name "*.a" -type f | head -10

