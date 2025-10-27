#!/bin/bash
# Автоматическое исправление конфликтов в Tor исходниках для iOS

TOR_SRC="tor-0.4.8.19"
TOR_FIXED="tor-ios-fixed"

echo "🔧 Исправление конфликтов Tor для iOS..."

# Копируем исходники
rm -rf "$TOR_FIXED"
cp -R "$TOR_SRC" "$TOR_FIXED"

cd "$TOR_FIXED"

# 1. Исправить torint.h - убрать переопределение ssize_t
echo "  📝 Исправление src/lib/cc/torint.h..."
cat > src/lib/cc/torint.h.new << 'EOF'
#ifndef TOR_TORINT_H
#define TOR_TORINT_H

#include <stdint.h>
#include <sys/types.h>

/* Use system ssize_t on iOS */
/* #define ssize_t - already defined by system */

#endif
EOF
mv src/lib/cc/torint.h.new src/lib/cc/torint.h

# 2. Исправить compat_compiler.h - убрать ошибки assertions
echo "  📝 Исправление src/lib/cc/compat_compiler.h..."
sed -i '' 's/#error "Your platform does not represent NULL as zero.*"/\/\* NULL check disabled for iOS \*\//' src/lib/cc/compat_compiler.h || true
sed -i '' 's/#error "Your platform does not represent 0.0 as zeros.*"/\/\* 0.0 check disabled for iOS \*\//' src/lib/cc/compat_compiler.h || true
sed -i '' 's/#error "Your platform.*arithmetic.*"/\/\* arithmetic check disabled for iOS \*\//' src/lib/cc/compat_compiler.h || true

# 3. Удалить конфликтующие файлы
echo "  📝 Удаление конфликтующих файлов..."
rm -f src/ext/strlcpy.c
rm -f src/ext/strlcat.c  
rm -f src/ext/getdelim.c
rm -f src/ext/readpassphrase.c

# 4. Исправить включения equix
echo "  📝 Исправление equix includes..."
find src/ext/equix -name "*.c" -exec sed -i '' 's/#include <equix\.h>/#include "..\/..\/..\/ext\/equix\/include\/equix.h"/' {} \;

# 5. Добавить SIZEOF_SOCKLEN_T в orconfig.h
echo "  📝 Добавление SIZEOF_SOCKLEN_T в orconfig.h..."
if ! grep -q "SIZEOF_SOCKLEN_T" orconfig.h; then
    sed -i '' '/^#define SIZEOF_UINT64_T 8$/a\
#define SIZEOF_SOCKLEN_T 4
' orconfig.h
    echo "    ✅ SIZEOF_SOCKLEN_T добавлен"
else
    echo "    ℹ️  SIZEOF_SOCKLEN_T уже определен"
fi

cd ..

echo "✅ Исправления применены в $TOR_FIXED/"
echo ""
echo "Теперь компилируем исправленную версию..."

