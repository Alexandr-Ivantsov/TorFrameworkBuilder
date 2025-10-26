#!/bin/bash
# Быстрый тест configure

echo "🧪 Тест configure для Tor (iOS arm64)"
echo ""

# Подготовка
rm -rf build/tor-test
mkdir -p build/tor-test
cp -R tor-0.4.8.19 build/tor-test/tor-src
cd build/tor-test/tor-src

# Параметры из основного скрипта
SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
OPENSSL_DIR="/Users/aleksandrivancov/admin/TorFrameworkBuilder/output/openssl"
LIBEVENT_DIR="/Users/aleksandrivancov/admin/TorFrameworkBuilder/output/libevent"
CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
BUILD_SYSTEM="$(uname -m)-apple-darwin"

echo "📝 Запуск configure (первые 100 строк вывода)..."
echo "   (прервите Ctrl+C если зависнет)"
echo ""

# Запуск с выводом (без timeout, так как на macOS его нет)
./configure \
    --build="${BUILD_SYSTEM}" \
    --host=arm-apple-darwin \
    --prefix="/tmp/tor-test" \
    --cache-file="/Users/aleksandrivancov/admin/TorFrameworkBuilder/tor-cross-compile.cache" \
    --disable-tool-name-check \
    --disable-unittests \
    --disable-gcc-hardening \
    --with-openssl-dir="$OPENSSL_DIR" \
    --with-libevent-dir="$LIBEVENT_DIR" \
    --enable-static-openssl \
    --enable-static-libevent \
    CC="${CC}" \
    CFLAGS="-arch arm64 -isysroot ${SDK_PATH}" \
    LDFLAGS="-arch arm64 -isysroot ${SDK_PATH}" \
    2>&1 | head -100

EXIT_CODE=$?

echo ""
echo "════════════════════════════════════════════════════════"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Configure прошел успешно!"
    echo "📁 config.log создан: $(ls -lh config.log 2>/dev/null | awk '{print $5}')"
    echo ""
    echo "🎯 Это ХОРОШИЙ ЗНАК! Configure работает!"
    echo "   Теперь можете запустить полную сборку:"
    echo "   bash scripts/build_tor.sh"
else
    echo "❌ Configure завершился с ошибкой: $EXIT_CODE"
    echo ""
    if [ -f config.log ]; then
        echo "📋 Последние 30 строк config.log:"
        tail -30 config.log
    else
        echo "📋 config.log не создан - configure не начал работу"
        echo ""
        echo "Возможные причины:"
        echo "  1. Проблема с путями к зависимостям"
        echo "  2. Неверные параметры компилятора"
        echo "  3. Отсутствует configure скрипт"
    fi
fi
echo "════════════════════════════════════════════════════════"

cd ../../..
