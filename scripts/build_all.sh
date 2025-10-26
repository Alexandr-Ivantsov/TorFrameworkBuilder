#!/bin/bash
set -e

# Мастер-скрипт для сборки всех компонентов
# Последовательно собирает: OpenSSL -> libevent -> xz -> Tor

echo "🚀 Начинаем полную сборку Tor Framework для iOS"
echo "================================================"
echo ""

START_TIME=$(date +%s)

# Проверка необходимых инструментов
echo "🔍 Проверка инструментов..."
for tool in wget tar make gcc clang autoconf automake libtool pkg-config; do
    if ! command -v $tool &> /dev/null; then
        echo "❌ Необходимый инструмент не найден: $tool"
        echo "Установите через: brew install autoconf automake libtool pkg-config wget"
        exit 1
    fi
done
echo "✅ Все необходимые инструменты установлены"
echo ""

# Проверка Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode не установлен"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n1)
echo "✅ Xcode: $XCODE_VERSION"
echo ""

# Этап 1: OpenSSL
echo "════════════════════════════════════════════════"
echo "📦 Этап 1/4: Сборка OpenSSL 3.4.0"
echo "════════════════════════════════════════════════"
bash scripts/build_openssl.sh
echo ""

# Этап 2: libevent
echo "════════════════════════════════════════════════"
echo "📦 Этап 2/4: Сборка libevent 2.1.12"
echo "════════════════════════════════════════════════"
bash scripts/build_libevent.sh
echo ""

# Этап 3: xz (lzma)
echo "════════════════════════════════════════════════"
echo "📦 Этап 3/4: Сборка xz 5.6.3"
echo "════════════════════════════════════════════════"
bash scripts/build_xz.sh
echo ""

# Этап 4: Tor
echo "════════════════════════════════════════════════"
echo "📦 Этап 4/4: Сборка Tor 0.4.8.19"
echo "════════════════════════════════════════════════"
bash scripts/build_tor.sh
echo ""

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "════════════════════════════════════════════════"
echo "✅ Сборка завершена успешно!"
echo "════════════════════════════════════════════════"
echo "⏱️  Время сборки: ${MINUTES}м ${SECONDS}с"
echo ""
echo "📁 Результаты сборки:"
echo "  • OpenSSL:  output/openssl/lib/"
echo "  • libevent: output/libevent/lib/"
echo "  • xz:       output/xz/lib/"
echo "  • Tor:      output/tor/bin/"
echo ""
echo "🎯 Следующие шаги:"
echo "  1. bash scripts/create_xcframework.sh - создание XCFramework"
echo "  2. bash scripts/deploy.sh - деплой в TorApp"
echo ""

