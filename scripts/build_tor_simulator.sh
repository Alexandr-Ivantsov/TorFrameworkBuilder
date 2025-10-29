#!/bin/bash
set -e

# Сборка Tor для iOS Simulator arm64
TOR_SRC="tor-ios-fixed"
BUILD_DIR="$(pwd)/build/tor-simulator"
OUTPUT_DIR="$(pwd)/output/tor-simulator"
OPENSSL_DIR="$(pwd)/output/openssl-simulator"
LIBEVENT_DIR="$(pwd)/output/libevent-simulator"
XZ_DIR="$(pwd)/output/xz-simulator"

echo "🧅 Сборка Tor для iOS Simulator..."

# Проверка зависимостей
if [ ! -d "$OPENSSL_DIR" ] || [ ! -d "$LIBEVENT_DIR" ] || [ ! -d "$XZ_DIR" ]; then
    echo "❌ Зависимости для симулятора не найдены"
    echo "Сначала выполните: bash scripts/build_all_simulator.sh"
    exit 1
fi

# Проверка исходников
if [ ! -d "$TOR_SRC" ]; then
    echo "❌ $TOR_SRC не найден. Сначала: bash scripts/fix_conflicts.sh"
    exit 1
fi

# Очистка
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR/lib"

# Настройки для iOS Simulator
export PLATFORM="iPhoneSimulator"
export MIN_IOS_VERSION="16.0"
export ARCH="arm64"

# Поиск SDK
DEVELOPER=$(xcode-select --print-path)
SDK_PATH="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"

if [ ! -d "$SDK_PATH" ]; then
    echo "❌ SDK не найден: $SDK_PATH"
    exit 1
fi

echo "🛠  SDK: $SDK_PATH"
echo "📋 Компиляция Tor для Simulator..."

# Флаги компиляции
CC="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
AR="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"

CFLAGS="-target ${ARCH}-apple-ios${MIN_IOS_VERSION}-simulator -isysroot ${SDK_PATH}"
CFLAGS="$CFLAGS -I${TOR_SRC}/src"
CFLAGS="$CFLAGS -I${TOR_SRC}/src/ext"
CFLAGS="$CFLAGS -I${TOR_SRC}/src/ext/trunnel"
CFLAGS="$CFLAGS -I${TOR_SRC}/src/ext/equix/include"
CFLAGS="$CFLAGS -I${TOR_SRC}/src/ext/equix/hashx/src"
CFLAGS="$CFLAGS -I${TOR_SRC}/src/trunnel"
CFLAGS="$CFLAGS -I${TOR_SRC}"
CFLAGS="$CFLAGS -I${OPENSSL_DIR}/include"
CFLAGS="$CFLAGS -I${LIBEVENT_DIR}/include"
CFLAGS="$CFLAGS -I${XZ_DIR}/include"
CFLAGS="$CFLAGS -DHAVE_CONFIG_H"
CFLAGS="$CFLAGS -O2"
CFLAGS="$CFLAGS -Wno-error"
CFLAGS="$CFLAGS -D_FORTIFY_SOURCE=0"
CFLAGS="$CFLAGS -fvisibility=default"

# Файлы для пропуска
SKIP_FILES="strlcpy.c strlcat.c getdelim.c readpassphrase.c"
SKIP_DIRS="bench test lua"

COMPILE_DIRS=(
    "src/ext"
    "src/lib"
    "src/trunnel"
    "src/core"
    "src/feature"
    "src/app"
)

echo "📦 Компиляция модулей..."

compiled=0
for dir in "${COMPILE_DIRS[@]}"; do
    if [ ! -d "$TOR_SRC/$dir" ]; then
        continue
    fi
    
    find "$TOR_SRC/$dir" -name "*.c" -type f | while read src_file; do
        # Пропуск test/bench директорий
        skip=0
        for skip_d in $SKIP_DIRS; do
            if echo "$src_file" | grep -q "/$skip_d/"; then
                skip=1
                break
            fi
        done
        [ $skip -eq 1 ] && continue
        
        # Пропуск конфликтующих файлов
        basename_file=$(basename "$src_file")
        for skip_file in $SKIP_FILES; do
            if [ "$basename_file" = "$skip_file" ]; then
                skip=1
                break
            fi
        done
        [ $skip -eq 1 ] && continue
        
        # Компиляция
        rel_path="${src_file#$TOR_SRC/}"
        obj_file="$BUILD_DIR/${rel_path%.c}.o"
        obj_dir=$(dirname "$obj_file")
        
        mkdir -p "$obj_dir"
        
        $CC $CFLAGS -c "$src_file" -o "$obj_file" 2>/dev/null && echo "  ✓ $(basename $src_file)" || true
    done
done

echo ""
echo "🔗 Создание libtor.a..."
$AR rcs "$OUTPUT_DIR/lib/libtor.a" $(find "$BUILD_DIR" -name "*.o")

echo "✅ Tor для Simulator готов!"
echo "📁 Библиотека: $OUTPUT_DIR/lib/libtor.a"
du -h "$OUTPUT_DIR/lib/libtor.a"

