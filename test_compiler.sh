#!/bin/bash
echo "🧪 Тест компилятора для iOS"
echo ""

SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

echo "1. Тест компиляции простой программы для iOS arm64..."
cat > /tmp/test_ios.c << 'EOF'
#include <stdio.h>
int main() { printf("Hello iOS\n"); return 0; }
EOF

echo "   Компилируем..."
if $CC -arch arm64 -isysroot "$SDK_PATH" /tmp/test_ios.c -o /tmp/test_ios 2>&1 | head -20; then
    echo "   ✅ Компиляция успешна!"
    ls -lh /tmp/test_ios
else
    echo "   ❌ Ошибка компиляции"
fi

echo ""
echo "2. Тест версии компилятора..."
timeout 5 $CC --version || echo "   ⏰ Команда зависла"

echo ""
echo "3. Тест iOS SDK..."
if [ -d "$SDK_PATH" ]; then
    echo "   ✅ SDK существует: $SDK_PATH"
    echo "   Версия SDK:"
    ls -l "$SDK_PATH" | head -3
else
    echo "   ❌ SDK не найден"
fi

rm -f /tmp/test_ios.c /tmp/test_ios
