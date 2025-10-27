#!/bin/bash
set -e

# Сборка OpenSSL 3.4.0 для iOS Simulator arm64
VERSION="3.4.0"
SOURCE_DIR="$(pwd)/sources/openssl-${VERSION}"
BUILD_DIR="$(pwd)/build/openssl-simulator"
OUTPUT_DIR="$(pwd)/output/openssl-simulator"

echo "🔐 Сборка OpenSSL ${VERSION} для iOS Simulator..."

# Создаём директории
mkdir -p sources build output

# Скачивание OpenSSL если еще не скачан
if [ ! -d "$SOURCE_DIR" ]; then
    echo "⬇️  Скачивание OpenSSL ${VERSION}..."
    cd sources
    wget https://www.openssl.org/source/openssl-${VERSION}.tar.gz
    tar -xzf openssl-${VERSION}.tar.gz
    cd ..
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

# Настройка переменных окружения для симулятора
export CROSS_TOP="${PLATFORM_PATH}/Developer"
export CROSS_SDK="${PLATFORM}.sdk"
export CC="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

# Копирование исходников в build директорию
cp -R "$SOURCE_DIR" "$BUILD_DIR/openssl-src"
cd "$BUILD_DIR/openssl-src"

# Конфигурация OpenSSL для iOS Simulator
echo "⚙️  Конфигурация OpenSSL для Simulator..."
export CFLAGS="-arch arm64 -mios-simulator-version-min=${MIN_IOS_VERSION} -isysroot ${SDK_PATH}"
export LDFLAGS="-arch arm64 -isysroot ${SDK_PATH}"

./Configure darwin64-arm64-cc \
    --prefix="$OUTPUT_DIR" \
    no-shared \
    no-asm

# Сборка
echo "🔨 Компиляция OpenSSL..."
make -j$(sysctl -n hw.ncpu)

# Установка
echo "📦 Установка в $OUTPUT_DIR..."
make install_sw

cd ../..

echo "✅ OpenSSL ${VERSION} для Simulator готов!"
echo "📁 Путь: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR/lib" | head -10

