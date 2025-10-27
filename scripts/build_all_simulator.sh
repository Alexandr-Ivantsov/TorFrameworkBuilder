#!/bin/bash
set -e

# Сборка всех зависимостей для iOS Simulator (arm64)
# Это позволит тестировать Tor на симуляторе

echo "🚀 Сборка зависимостей для iOS Simulator"
echo "=========================================="
echo ""

START_TIME=$(date +%s)

# Этап 1: OpenSSL для симулятора
echo "════════════════════════════════════════════════"
echo "📦 Этап 1/3: OpenSSL для Simulator"
echo "════════════════════════════════════════════════"
bash scripts/build_openssl_simulator.sh
echo ""

# Этап 2: libevent для симулятора
echo "════════════════════════════════════════════════"
echo "📦 Этап 2/3: libevent для Simulator"
echo "════════════════════════════════════════════════"
bash scripts/build_libevent_simulator.sh
echo ""

# Этап 3: xz для симулятора
echo "════════════════════════════════════════════════"
echo "📦 Этап 3/3: xz для Simulator"
echo "════════════════════════════════════════════════"
bash scripts/build_xz_simulator.sh
echo ""

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "════════════════════════════════════════════════"
echo "✅ Зависимости для Simulator готовы!"
echo "════════════════════════════════════════════════"
echo "⏱️  Время: ${MINUTES}м ${SECONDS}с"
echo ""
echo "🎯 Следующий шаг:"
echo "   bash scripts/build_tor_simulator.sh"

