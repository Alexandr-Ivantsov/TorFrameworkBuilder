#!/bin/bash
set -e

# Деплой Tor.xcframework в TorApp проект

XCFRAMEWORK_PATH="$(pwd)/output/Tor.xcframework"
TARGET_PROJECT="$HOME/admin/TorApp"
TARGET_FRAMEWORKS="$TARGET_PROJECT/Frameworks"
WRAPPER_SOURCE="$(pwd)/wrapper"

echo "📦 Деплой Tor.xcframework в TorApp"
echo "================================================"
echo ""

# Проверка наличия XCFramework
if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    echo "❌ Tor.xcframework не найден в $XCFRAMEWORK_PATH"
    echo "Сначала выполните: bash scripts/create_xcframework.sh"
    exit 1
fi

# Проверка наличия TorApp проекта
if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ TorApp проект не найден в $TARGET_PROJECT"
    echo "Укажите правильный путь к проекту TorApp"
    exit 1
fi

# Создание директории Frameworks если не существует
mkdir -p "$TARGET_FRAMEWORKS"

# Копирование XCFramework
echo "📋 Копирование Tor.xcframework..."
rm -rf "$TARGET_FRAMEWORKS/Tor.xcframework"
cp -R "$XCFRAMEWORK_PATH" "$TARGET_FRAMEWORKS/"

echo "✅ Tor.xcframework скопирован"
echo "📁 Путь: $TARGET_FRAMEWORKS/Tor.xcframework"
echo ""

# Копирование wrapper файлов (опционально, для справки)
WRAPPER_TARGET="$TARGET_PROJECT/TorWrapper"
if [ -d "$WRAPPER_SOURCE" ]; then
    echo "📋 Копирование wrapper файлов для справки..."
    mkdir -p "$WRAPPER_TARGET"
    cp "$WRAPPER_SOURCE/TorWrapper.h" "$WRAPPER_TARGET/" 2>/dev/null || true
    cp "$WRAPPER_SOURCE/TorWrapper.m" "$WRAPPER_TARGET/" 2>/dev/null || true
    cp "$WRAPPER_SOURCE/Tor.h" "$WRAPPER_TARGET/" 2>/dev/null || true
    cp "$WRAPPER_SOURCE/module.modulemap" "$WRAPPER_TARGET/" 2>/dev/null || true
    echo "✅ Wrapper файлы скопированы в $WRAPPER_TARGET"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "✅ Деплой завершен успешно!"
echo "════════════════════════════════════════════════"
echo ""
echo "📋 Следующие шаги для интеграции в TorApp:"
echo ""
echo "1️⃣  Добавьте Tor.xcframework в Project.swift:"
echo ""
cat << 'EOF'
   .package(localPath: "Frameworks/Tor.xcframework")
EOF
echo ""
echo "2️⃣  Добавьте в зависимости target:"
echo ""
cat << 'EOF'
   .target(
       name: "TorApp",
       dependencies: [
           "Tor"
       ]
   )
EOF
echo ""
echo "3️⃣  Импортируйте в Swift коде:"
echo ""
cat << 'EOF'
   import Tor
   
   // Использование
   let tor = TorWrapper.shared()
   tor.start { success, error in
       if success {
           print("Tor запущен!")
           print("SOCKS: \(tor.socksProxyURL())")
       }
   }
EOF
echo ""
echo "4️⃣  Обновите URLSessionConfiguration для использования Tor:"
echo ""
cat << 'EOF'
   let config = URLSessionConfiguration.default
   config.connectionProxyDictionary = [
       kCFNetworkProxiesSOCKSEnable: true,
       kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
       kCFNetworkProxiesSOCKSPort: tor.socksPort
   ]
   let session = URLSession(configuration: config)
EOF
echo ""
echo "📝 Примечания:"
echo "  • Framework содержит все необходимые зависимости (OpenSSL, libevent, xz)"
echo "  • Поддерживается iOS 16.0+ arm64"
echo "  • Размер framework: $(du -sh $XCFRAMEWORK_PATH | cut -f1)"
echo ""
echo "🎉 Готово! Теперь можно использовать Tor в TorApp!"

