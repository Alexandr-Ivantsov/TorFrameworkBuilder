#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🔥 ПОЛНАЯ ПЕРЕСБОРКА С ПАТЧЕМ v1.0.37"
echo "======================================"
echo ""

# 1. OpenSSL для device
echo "📦 [1/7] Сборка OpenSSL для device..."
bash scripts/build_openssl.sh
echo "✅ OpenSSL device готов!"
echo ""

# 2. Libevent для device
echo "📦 [2/7] Сборка Libevent для device..."
bash scripts/build_libevent.sh
echo "✅ Libevent device готов!"
echo ""

# 3. XZ для device
echo "📦 [3/7] Сборка XZ для device..."
bash scripts/build_xz.sh
echo "✅ XZ device готов!"
echo ""

# 4. Tor для device (с патчем!)
echo "📦 [4/7] Сборка Tor для device (с ПАТЧЕМ!)..."
bash scripts/direct_build.sh
echo "✅ Tor device готов С ПАТЧЕМ!"
echo ""

# 5. OpenSSL + Libevent + XZ для simulator
echo "📦 [5/7] Сборка зависимостей для simulator..."
bash scripts/build_openssl_simulator.sh
bash scripts/build_libevent_simulator.sh
bash scripts/build_xz_simulator.sh
echo "✅ Зависимости simulator готовы!"
echo ""

# 6. Tor для simulator (с патчем!)
echo "📦 [6/7] Сборка Tor для simulator (с ПАТЧЕМ!)..."
bash scripts/build_tor_simulator.sh
echo "✅ Tor simulator готов С ПАТЧЕМ!"
echo ""

# 7. Создание универсального XCFramework
echo "📦 [7/7] Создание универсального XCFramework..."
bash scripts/create_xcframework_universal.sh
echo "✅ XCFramework создан!"
echo ""

# Проверка
echo "🔍 ПРОВЕРКА ПАТЧА В ИСХОДНИКАХ:"
if grep -q "Platform does not support non-inheritable" tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c; then
    echo "✅ ПАТЧ В ИСХОДНИКАХ!"
    grep -A 3 "Platform does not support" tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c | head -5
else
    echo "❌ ПАТЧ НЕ НАЙДЕН В ИСХОДНИКАХ!"
    exit 1
fi

echo ""
echo "🎉 СБОРКА ЗАВЕРШЕНА!"
echo "✅ output/Tor.xcframework готов С ПАТЧЕМ!"
echo ""
echo "Следующий шаг: git add output/ && git commit && git tag 1.0.37"




