#!/bin/bash
set -e

# Сборка xz (lzma) 5.6.3 для iOS arm64
VERSION="5.6.3"
SOURCE_DIR="$(pwd)/sources/xz-${VERSION}"
BUILD_DIR="$(pwd)/build/xz"
OUTPUT_DIR="$(pwd)/output/xz"

echo "🗜️  Сборка xz (lzma) ${VERSION} для iOS..."

# Создаём директории
mkdir -p sources build output

# Скачивание xz если еще не скачан
if [ ! -d "$SOURCE_DIR" ]; then
    echo "⬇️  Скачивание xz ${VERSION}..."
    cd sources
    wget https://github.com/tukaani-project/xz/releases/download/v${VERSION}/xz-${VERSION}.tar.gz
    tar -xzf xz-${VERSION}.tar.gz
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
export CC="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
export CXX="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
export CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-version-min=${MIN_IOS_VERSION} -fembed-bitcode"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH}"

# Копирование исходников в build директорию
cp -R "$SOURCE_DIR" "$BUILD_DIR/xz-src"
cd "$BUILD_DIR/xz-src"

# Конфигурация xz
echo "⚙️  Конфигурация xz..."
./configure \
    --host=arm-apple-darwin \
    --prefix="$OUTPUT_DIR" \
    --disable-shared \
    --enable-static \
    --disable-xz \
    --disable-xzdec \
    --disable-lzmadec \
    --disable-lzmainfo \
    --disable-lzma-links \
    --disable-scripts \
    --disable-doc \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}"

# Сборка
echo "🔨 Компиляция xz..."
make -j$(sysctl -n hw.ncpu)

# Установка
echo "📦 Установка в $OUTPUT_DIR..."
make install

cd ../..

echo "✅ xz ${VERSION} успешно собран!"
echo "📁 Путь: $OUTPUT_DIR"
echo ""
ls -la "$OUTPUT_DIR/lib"

