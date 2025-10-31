#!/bin/bash
# Прямая компиляция Tor для iOS без configure
# С таймаутами и автовосстановлением

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Настройки
# Try Sources/Tor/tor-ios-fixed first (for CI/CD), fallback to tor-ios-fixed (for local dev)
if [ -d "Sources/Tor/tor-ios-fixed" ]; then
    TOR_SRC="Sources/Tor/tor-ios-fixed"
elif [ -d "tor-ios-fixed" ]; then
    TOR_SRC="tor-ios-fixed"
else
    echo "❌ ERROR: Tor sources not found!"
    echo "   Expected: Sources/Tor/tor-ios-fixed/ or tor-ios-fixed/"
    exit 1
fi
BUILD_DIR="build/tor-direct"
OUTPUT_DIR="output/tor-direct"
OPENSSL_DIR="output/openssl"
LIBEVENT_DIR="output/libevent"
XZ_DIR="output/xz"

# Timeout для компиляции каждого файла (секунды)
COMPILE_TIMEOUT=120

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
CFLAGS="$CFLAGS -I${TOR_SRC}/src/ext/equix/hashx/include"
CFLAGS="$CFLAGS -I${TOR_SRC}/src/trunnel"
CFLAGS="$CFLAGS -I${TOR_SRC}"
CFLAGS="$CFLAGS -ISources/Tor/include"
CFLAGS="$CFLAGS -I${OPENSSL_DIR}/include"
CFLAGS="$CFLAGS -I${LIBEVENT_DIR}/include"
CFLAGS="$CFLAGS -I${XZ_DIR}/include"
CFLAGS="$CFLAGS -DHAVE_CONFIG_H"
CFLAGS="$CFLAGS -DRSHIFT_DOES_SIGN_EXTEND=1"
CFLAGS="$CFLAGS -DSIZE_T_CEILING=SIZE_MAX"
CFLAGS="$CFLAGS -DTOR_UNIT_TESTS=0"
CFLAGS="$CFLAGS -DCHAR_BIT=8"
CFLAGS="$CFLAGS -DHAVE_MODULE_POW=1"
CFLAGS="$CFLAGS -DUSE_CURVE25519_DONNA=1"
CFLAGS="$CFLAGS -DHAVE_GETDELIM=1"
CFLAGS="$CFLAGS -DHAVE_GETLINE=1"
CFLAGS="$CFLAGS -DHAVE_SSL_GET_CLIENT_RANDOM=1"
CFLAGS="$CFLAGS -DHAVE_SSL_GET_SERVER_RANDOM=1"
CFLAGS="$CFLAGS -DHAVE_SSL_SESSION_GET_MASTER_KEY=1"
CFLAGS="$CFLAGS -DHAVE_SSL_GET_CLIENT_CIPHERS=1"
CFLAGS="$CFLAGS -D__APPLE_USE_RFC_3542=1"
CFLAGS="$CFLAGS -O2"
CFLAGS="$CFLAGS -Wno-error"
CFLAGS="$CFLAGS -D_FORTIFY_SOURCE=0"
CFLAGS="$CFLAGS -fvisibility=default"

# Файлы которые нужно пропустить (конфликты с iOS SDK или не нужны на iOS)
SKIP_FILES="strlcpy.c strlcat.c getdelim.c readpassphrase.c x509_nss.c tortls_nss.c nss_countbytes.c crypto_digest_nss.c crypto_rsa_nss.c crypto_nss_mgt.c crypto_dh_nss.c aes_nss.c OpenBSD_malloc_Linux.c mulodi4.c test-internals.c compat_mutex_winthreads.c compat_winthreads.c"

# Директории которые нужно пропустить (тесты, бенчмарки, серверные функции и др.)
SKIP_DIRS="bench test lua feature/dirauth feature/relay feature/dircache ext/mulodi ext/timeouts/bench ext/timeouts/lua lib/term"

# Очистка и подготовка
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR/lib"

echo "🚀 Прямая компиляция Tor для iOS"
echo "=================================="
echo "Архитектура: $ARCH"
echo "SDK: $SDK_PATH"
echo "Tor sources: $TOR_SRC"
echo "Файлов для компиляции: $(find $TOR_SRC/src -name "*.c" 2>/dev/null | wc -l | tr -d ' ')"
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
    "src/mobile"
)

EXTRA_FILES=(
    "src/feature/relay/relay_stub.c"
    "src/feature/dirauth/dirauth_stub.c"
    "src/feature/dircache/dircache_stub.c"
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

echo ""
echo "📦 Компиляция stub-файлов ядра..."
for extra in "${EXTRA_FILES[@]}"; do
    src_file="$TOR_SRC/$extra"
    if [ ! -f "$src_file" ]; then
        echo "  ⚠️  Stub not found: $extra"
        continue
    fi
    obj_file="$BUILD_DIR/${extra%.c}.o"
    obj_dir=$(dirname "$obj_file")
    mkdir -p "$obj_dir"
    total_files=$((total_files + 1))
    if compile_with_timeout "$src_file" "$obj_file" $COMPILE_TIMEOUT; then
        compiled_files=$((compiled_files + 1))
        echo "  ✓ stub $(basename "$extra")"
    else
        failed_files=$((failed_files + 1))
        echo "  ✗ stub $(basename "$extra")"
    fi
done

echo ""
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

if [ $failed_files -ne 0 ]; then
    echo "❌ Компиляция завершилась с ошибками для $failed_files файлов!"
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
LIBTOOL="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool"
$LIBTOOL -static -o "$OUTPUT_DIR/lib/libtor.a" $ALL_OBJS

echo ""
echo "✅ Сборка завершена!"
echo "📁 Библиотека: $OUTPUT_DIR/lib/libtor.a"
echo "📊 Размер: $(du -sh $OUTPUT_DIR/lib/libtor.a | cut -f1)"
echo ""

# Показать символы
echo "🔍 Проверка символов (первые 10):"
nm "$OUTPUT_DIR/lib/libtor.a" | grep " T " | head -10

