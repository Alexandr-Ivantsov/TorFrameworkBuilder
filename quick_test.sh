#!/bin/bash
# Ультра-быстрый тест configure

echo "🧪 Быстрый тест configure (без копирования файлов)"
echo ""

cd tor-0.4.8.19

SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
OPENSSL_DIR="/Users/aleksandrivancov/admin/TorFrameworkBuilder/output/openssl"
LIBEVENT_DIR="/Users/aleksandrivancov/admin/TorFrameworkBuilder/output/libevent"
CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
BUILD_SYSTEM="$(uname -m)-apple-darwin"

echo "📝 Запуск configure с полным cache..."
echo "   Первые 50 строк вывода:"
echo ""

(
./configure \
    --build="${BUILD_SYSTEM}" \
    --host=arm-apple-darwin \
    --prefix="/tmp/tor-test" \
    --cache-file="../tor-cross-compile.cache" \
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
    2>&1 &
CONF_PID=$!
echo "🔍 Configure PID: $CONF_PID"
echo ""

# Ждем 10 секунд и убиваем если не завершился
sleep 10
if kill -0 $CONF_PID 2>/dev/null; then
    echo ""
    echo "⏰ Configure все еще работает через 10 секунд"
    echo "📋 Проверяем config.log..."
    if [ -f config.log ]; then
        echo "✅ config.log создан, последние 5 строк:"
        tail -5 config.log
    else
        echo "❌ config.log не создан - configure завис ДО начала проверок"
    fi
    echo ""
    echo "🛑 Убиваем процесс..."
    kill -9 $CONF_PID 2>/dev/null
else
    echo ""
    echo "✅ Configure завершился быстро!"
fi
) | head -50

cd ..

echo ""
echo "════════════════════════════════════════════════════════"
echo "Проверяем результат..."
if [ -f tor-0.4.8.19/config.log ]; then
    SIZE=$(ls -lh tor-0.4.8.19/config.log | awk '{print $5}')
    echo "✅ config.log создан ($SIZE)"
    echo ""
    echo "Первая ошибка (если есть):"
    grep -i "error" tor-0.4.8.19/config.log | head -3 || echo "  Ошибок не найдено"
else
    echo "❌ config.log не создан"
fi
echo "════════════════════════════════════════════════════════"

# Очистка
rm -f tor-0.4.8.19/config.log tor-0.4.8.19/config.status
