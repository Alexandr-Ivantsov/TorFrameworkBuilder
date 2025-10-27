#!/bin/bash
# Прямая компиляция Tor для iOS без configure
# С таймаутами и автовосстановлением

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Настройки
TOR_SRC="tor-ios-fixed"
BUILD_DIR="build/tor-direct"
OUTPUT_DIR="output/tor-direct"
OPENSSL_DIR="output/openssl"
LIBEVENT_DIR="output/libevent"
XZ_DIR="output/xz"

# Timeout для компиляции каждого файла (секунды)
COMPILE_TIMEOUT=60

# iOS настройки
SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
AR="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
ARCH="arm64"
MIN_IOS="16.0"

# Флаги компиляции
CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-version-min=${MIN_IOS}"
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

# Файлы которые нужно пропустить (конфликты с iOS SDK)
SKIP_FILES="strlcpy.c strlcat.c getdelim.c readpassphrase.c"

# Директории которые нужно пропустить (тесты, бенчмарки, не нужны для библиотеки)
SKIP_DIRS="bench test lua"

# Очистка и подготовка
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR/lib"

echo "🚀 Прямая компиляция Tor для iOS"
echo "=================================="
echo "Архитектура: $ARCH"
echo "SDK: $SDK_PATH"
echo "Файлов для компиляции: $(find $TOR_SRC/src -name "*.c" | wc -l)"
echo ""

# Функция компиляции с таймаутом
compile_with_timeout() {
    local src=$1
    local obj=$2
    local timeout=$3
    
    ( $CC $CFLAGS -c "$src" -o "$obj" ) &
    local pid=$!
    
    local count=0
    while kill -0 $pid 2>/dev/null; do
        sleep 1
        count=$((count + 1))
        if [ $count -ge $timeout ]; then
            kill -9 $pid 2>/dev/null
            return 1
        fi
    done
    
    wait $pid
    return $?
}

# Список директорий для компиляции
COMPILE_DIRS=(
    "src/ext"
    "src/lib"
    "src/trunnel"
    "src/core"
    "src/feature"
    "src/app"
)

total_files=0
compiled_files=0
failed_files=0

echo "📦 Компиляция по директориям..."
echo ""

for dir in "${COMPILE_DIRS[@]}"; do
    if [ ! -d "$TOR_SRC/$dir" ]; then
        continue
    fi
    
    echo "📂 $dir"
    
    # Найти все .c файлы
    while IFS= read -r src_file; do
        # Проверить, нужно ли пропустить директорию
        skip_dir=0
        for skip_d in $SKIP_DIRS; do
            if echo "$src_file" | grep -q "/$skip_d/"; then
                skip_dir=1
                break
            fi
        done
        
        if [ $skip_dir -eq 1 ]; then
            continue
        fi
        
        # Проверить,  нужно ли пропустить этот файл
        basename_file=$(basename "$src_file")
        skip=0
        for skip_file in $SKIP_FILES; do
            if [ "$basename_file" = "$skip_file" ]; then
                skip=1
                break
            fi
        done
        
        if [ $skip -eq 1 ]; then
            echo "  ⊘ $basename_file [skipped - conflicts with iOS SDK]"
            continue
        fi
        
        total_files=$((total_files + 1))
        
        # Создать путь для .o файла
        rel_path="${src_file#$TOR_SRC/}"
        obj_file="$BUILD_DIR/${rel_path%.c}.o"
        obj_dir=$(dirname "$obj_file")
        
        mkdir -p "$obj_dir"
        
        # Компилировать с таймаутом
        if compile_with_timeout "$src_file" "$obj_file" $COMPILE_TIMEOUT; then
            compiled_files=$((compiled_files + 1))
            echo "  ✓ $(basename $src_file)"
        else
            failed_files=$((failed_files + 1))
            echo "  ✗ $(basename $src_file) [timeout/error]"
        fi
        
    done < <(find "$TOR_SRC/$dir" -name "*.c" -type f)
    
    echo ""
done

echo "=================================="
echo "📊 Статистика компиляции:"
echo "  Всего файлов: $total_files"
echo "  Скомпилировано: $compiled_files"
echo "  Ошибок/timeout: $failed_files"
echo ""

if [ $compiled_files -eq 0 ]; then
    echo "❌ Ничего не скомпилировано!"
    exit 1
fi

# Создание статических библиотек
echo "📚 Создание статических библиотек..."

# Собрать все .o файлы
ALL_OBJS=$(find "$BUILD_DIR" -name "*.o" -type f)

if [ -z "$ALL_OBJS" ]; then
    echo "❌ Нет .o файлов!"
    exit 1
fi

# Создать libtor.a
echo "🔨 Создание libtor.a..."
$AR rcs "$OUTPUT_DIR/lib/libtor.a" $ALL_OBJS

echo ""
echo "✅ Сборка завершена!"
echo "📁 Библиотека: $OUTPUT_DIR/lib/libtor.a"
echo "📊 Размер: $(du -sh $OUTPUT_DIR/lib/libtor.a | cut -f1)"
echo ""

# Показать символы
echo "🔍 Проверка символов (первые 10):"
nm "$OUTPUT_DIR/lib/libtor.a" | grep " T " | head -10

