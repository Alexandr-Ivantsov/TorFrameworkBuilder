#!/bin/bash
set -e

# Сборка libevent 2.1.12 для iOS Simulator arm64
VERSION="2.1.12-stable"
SOURCE_DIR="$(pwd)/sources/libevent-${VERSION}"
BUILD_DIR="$(pwd)/build/libevent-simulator"
OUTPUT_DIR="$(pwd)/output/libevent-simulator"
OPENSSL_DIR="$(pwd)/output/openssl-simulator"

echo "🌐 Сборка libevent ${VERSION} для iOS Simulator..."

# Создаём директории
mkdir -p sources build output

# Скачивание libevent если еще не скачан
if [ ! -d "$SOURCE_DIR" ]; then
    echo "⬇️  Скачивание libevent ${VERSION}..."
    cd sources
    wget https://github.com/libevent/libevent/releases/download/release-${VERSION}/libevent-${VERSION}.tar.gz
    tar -xzf libevent-${VERSION}.tar.gz
    cd ..
fi

# Проверка наличия OpenSSL для симулятора
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "❌ OpenSSL для симулятора не найден. Сначала: bash scripts/build_openssl_simulator.sh"
    exit 1
fi

# Очистка предыдущей сборки
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

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
export CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-simulator-version-min=${MIN_IOS_VERSION} -I${OPENSSL_DIR}/include"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -L${OPENSSL_DIR}/lib"

# Копирование исходников
cp -R "$SOURCE_DIR" "$BUILD_DIR/libevent-src"
cd "$BUILD_DIR/libevent-src"

# Ensure generated configure script is newer than configure.ac to avoid autoconf reruns
if [ -f "configure" ]; then
    touch configure
fi

# Конфигурация libevent
echo "⚙️  Конфигурация libevent для Simulator..."
./configure \
    --host=arm-apple-darwin \
    --prefix="$OUTPUT_DIR" \
    --disable-shared \
    --enable-static \
    --disable-openssl \
    --disable-samples \
    --disable-libevent-regress \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}"

# Сборка
echo "🔨 Компиляция libevent..."
make -j$(sysctl -n hw.ncpu)

# Установка
echo "📦 Установка в $OUTPUT_DIR..."
make install

cd ../..

echo "✅ libevent ${VERSION} для Simulator готов!"
echo "📁 Путь: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR/lib" | head -10

