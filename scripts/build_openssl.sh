#!/bin/bash
set -e

# Сборка OpenSSL 3.4.0 для iOS arm64
VERSION="3.4.0"
SOURCE_DIR="$(pwd)/sources/openssl-${VERSION}"
BUILD_DIR="$(pwd)/build/openssl"
OUTPUT_DIR="$(pwd)/output/openssl"

echo "🔐 Сборка OpenSSL ${VERSION} для iOS..."

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

# Настройки для iOS
export PLATFORM="iPhoneOS"
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
export CROSS_TOP="${PLATFORM_PATH}/Developer"
export CROSS_SDK="${PLATFORM}.sdk"
export CC="${DEVELOPER}/usr/bin/gcc -arch ${ARCH}"

# Копирование исходников в build директорию
cp -R "$SOURCE_DIR" "$BUILD_DIR/openssl-src"
cd "$BUILD_DIR/openssl-src"

# Конфигурация OpenSSL для iOS
echo "⚙️  Конфигурация OpenSSL..."
./Configure ios64-cross \
    --prefix="$OUTPUT_DIR" \
    no-shared \
    no-asm \
    -fembed-bitcode \
    -mios-version-min=${MIN_IOS_VERSION} \
    -isysroot "${SDK_PATH}"

# Сборка
echo "🔨 Компиляция OpenSSL..."
make -j$(sysctl -n hw.ncpu)

# Установка
echo "📦 Установка в $OUTPUT_DIR..."
make install_sw

cd ../..

echo "✅ OpenSSL ${VERSION} успешно собран!"
echo "📁 Путь: $OUTPUT_DIR"
echo ""
ls -la "$OUTPUT_DIR/lib"

