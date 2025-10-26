#!/bin/bash
set -e

# Сборка Tor 0.4.8.19 для macOS (для тестирования)
# Это должно работать без проблем, так как нет кросс-компиляции

VERSION="0.4.8.19"
SOURCE_DIR="$(pwd)/tor-${VERSION}"
BUILD_DIR="$(pwd)/build/tor-macos"
OUTPUT_DIR="$(pwd)/output/tor-macos"

echo "🧅 Сборка Tor ${VERSION} для macOS (host)..."
echo "   Это позволит проверить, что configure вообще работает"
echo ""

# Проверка наличия исходников
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Исходники Tor не найдены"
    exit 1
fi

# Очистка
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# Копирование исходников
echo "📋 Копирование исходников..."
cp -R "$SOURCE_DIR" "$BUILD_DIR/tor-src"
cd "$BUILD_DIR/tor-src"

# Конфигурация для macOS (БЕЗ кросс-компиляции, БЕЗ custom SDK)
echo "⚙️  Конфигурация Tor для macOS..."
echo "📝 Вывод configure (первые 50 строк)..."
echo ""

./configure \
    --prefix="$OUTPUT_DIR" \
    --disable-tool-name-check \
    --disable-unittests \
    --disable-system-torrc \
    --disable-systemd \
    --disable-lzma \
    --disable-zstd \
    2>&1 | head -100

EXIT_CODE=${PIPESTATUS[0]}

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Конфигурация успешна!"
    echo ""
    echo "🔨 Компиляция Tor..."
    make -j$(sysctl -n hw.ncpu)
    
    echo "📦 Установка в $OUTPUT_DIR..."
    make install
    
    echo ""
    echo "✅ Tor для macOS успешно собран!"
    echo "📁 Путь: $OUTPUT_DIR"
    echo ""
    echo "Библиотеки:"
    find . -name "*.a" -type f | head -10
else
    echo "❌ Ошибка конфигурации"
    echo "Проверьте config.log:"
    tail -30 config.log
fi

cd ../..

