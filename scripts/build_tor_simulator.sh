#!/bin/bash
set -e

# Сборка Tor для iOS Simulator arm64
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

# Проверка исходников (уже проверено выше, но для ясности)
if [ ! -d "$TOR_SRC/src" ]; then
    echo "❌ $TOR_SRC/src не найден!"
    echo "   Проверьте что исходники Tor находятся в правильном месте"
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

CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-simulator-version-min=${MIN_IOS_VERSION}"
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

# Файлы для пропуска
SKIP_FILES="strlcpy.c strlcat.c getdelim.c readpassphrase.c x509_nss.c tortls_nss.c nss_countbytes.c crypto_digest_nss.c crypto_rsa_nss.c crypto_nss_mgt.c crypto_dh_nss.c aes_nss.c OpenBSD_malloc_Linux.c mulodi4.c test-internals.c compat_mutex_winthreads.c compat_winthreads.c"
SKIP_DIRS="bench test lua feature/dirauth feature/relay feature/dircache ext/mulodi ext/timeouts/bench ext/timeouts/lua lib/term"

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

echo "📦 Компиляция модулей..."

compiled=0
failed=0
for dir in "${COMPILE_DIRS[@]}"; do
    if [ ! -d "$TOR_SRC/$dir" ]; then
        continue
    fi
    
    echo "📂 $dir"
    while IFS= read -r src_file; do
        skip=0
        for skip_d in $SKIP_DIRS; do
            if echo "$src_file" | grep -q "/$skip_d/"; then
                skip=1
                break
            fi
        done
        [ $skip -eq 1 ] && continue
        basename_file=$(basename "$src_file")
        for skip_file in $SKIP_FILES; do
            if [ "$basename_file" = "$skip_file" ]; then
                skip=1
                break
            fi
        done
        [ $skip -eq 1 ] && continue

        rel_path="${src_file#$TOR_SRC/}"
        obj_file="$BUILD_DIR/${rel_path%.c}.o"
        obj_dir=$(dirname "$obj_file")
        mkdir -p "$obj_dir"

        if $CC $CFLAGS -c "$src_file" -o "$obj_file"; then
            compiled=$((compiled + 1))
            echo "  ✓ $(basename $src_file)"
        else
            failed=$((failed + 1))
            echo "  ✗ $(basename $src_file)"
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
    if $CC $CFLAGS -c "$src_file" -o "$obj_file"; then
        compiled=$((compiled + 1))
        echo "  ✓ stub $(basename "$extra")"
    else
        failed=$((failed + 1))
        echo "  ✗ stub $(basename "$extra")"
    fi
done

echo ""
echo "=================================="
echo "📊 Статистика компиляции:"
echo "  Скомпилировано: $compiled"
echo "  Ошибок/timeout: $failed"

echo ""
if [ $compiled -eq 0 ]; then
    echo "❌ Нет скомпилированных файлов"
    exit 1
fi

if [ $failed -ne 0 ]; then
    echo "❌ Компиляция завершилась с ошибками для $failed файлов!"
    exit 1
fi

echo "🔗 Создание libtor.a..."
OBJS=$(find "$BUILD_DIR" -name "*.o")
if [ -z "$OBJS" ]; then
    echo "❌ Нет объектных файлов для архивации!"
    exit 1
fi
LIBTOOL="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool"
$LIBTOOL -static -o "$OUTPUT_DIR/lib/libtor.a" $OBJS

echo "✅ Tor для Simulator готов!"
echo "📁 Библиотека: $OUTPUT_DIR/lib/libtor.a"
du -h "$OUTPUT_DIR/lib/libtor.a"

