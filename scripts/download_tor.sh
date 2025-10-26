#!/bin/bash
set -e

# Скрипт для скачивания Tor исходников
# Tor уже скачан, но оставляем для документации

VERSION="0.4.8.19"
FILENAME="tor-${VERSION}.tar.gz"
URL="https://dist.torproject.org/${FILENAME}"

echo "📦 Скачивание Tor ${VERSION}..."

if [ -f "$FILENAME" ]; then
    echo "✅ Файл ${FILENAME} уже существует"
    exit 0
fi

echo "⬇️  Загрузка из ${URL}..."
wget "${URL}"

echo "✅ Tor ${VERSION} успешно скачан!"
echo "📁 Файл: ${FILENAME}"
echo ""
echo "Следующий шаг: bash scripts/build_all.sh"

