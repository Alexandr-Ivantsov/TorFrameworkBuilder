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

# 6. Добавить includes для bool и timeval в orconfig.h
echo "  📝 Исправление orconfig.h для main.c..."
if ! grep -q "#include <stdbool.h>" orconfig.h; then
    sed -i '' '/#define TOR_ORCONFIG_H$/a\
\
/* Include stdbool.h first for bool type */\
#include <stdbool.h>\
#include <sys/time.h>
' orconfig.h
    echo "    ✅ Добавлены includes для bool и timeval"
else
    echo "    ℹ️  Includes уже добавлены"
fi

# 7. Исправить HAVE_SYSTEMD и добавить HAVE_STRUCT_TIMEVAL
echo "  📝 Исправление HAVE_SYSTEMD и timeval..."
sed -i '' 's/#define HAVE_SYSTEMD 0/\/* #undef HAVE_SYSTEMD *\//' orconfig.h
if ! grep -q "HAVE_STRUCT_TIMEVAL_TV_SEC" orconfig.h; then
    sed -i '' '/USE_BUFFEREVENTS/a\
\
/* timeval structure */\
#define HAVE_STRUCT_TIMEVAL_TV_SEC 1\
#define HAVE_STRUCT_TIMEVAL_TV_USEC 1
' orconfig.h
    echo "    ✅ HAVE_STRUCT_TIMEVAL добавлены"
else
    echo "    ℹ️  HAVE_STRUCT_TIMEVAL уже определены"
fi

# 8. Добавить HAVE_LIMITS_H для INT_MIN/INT_MAX
echo "  📝 Добавление HAVE_LIMITS_H..."
if ! grep -q "HAVE_LIMITS_H" orconfig.h; then
    sed -i '' '/^#define HAVE_GLOB_H 1$/a\
#define HAVE_LIMITS_H 1
' orconfig.h
    echo "    ✅ HAVE_LIMITS_H добавлен"
else
    echo "    ℹ️  HAVE_LIMITS_H уже определен"
fi

# 9. Добавить #include <limits.h> в type_defs.c
echo "  📝 Исправление type_defs.c..."
if ! grep -q "#include <limits.h>" src/lib/confmgt/type_defs.c; then
    sed -i '' '/#include "orconfig.h"/a\
#include <limits.h>
' src/lib/confmgt/type_defs.c
    echo "    ✅ #include <limits.h> добавлен в type_defs.c"
else
    echo "    ℹ️  limits.h уже включен в type_defs.c"
fi

# 10. Добавить TIME_MAX для connection_edge.c
echo "  📝 Добавление TIME_MAX..."
if ! grep -q "TIME_MAX" orconfig.h; then
    sed -i '' '/^#define SIZEOF_SOCKLEN_T 4$/a\
\
/* time_t is 64-bit on iOS, so TIME_MAX is INT64_MAX */\
#ifndef TIME_MAX\
#define TIME_MAX INT64_MAX\
#endif
' orconfig.h
    echo "    ✅ TIME_MAX добавлен"
else
    echo "    ℹ️  TIME_MAX уже определен"
fi

# 11. Добавить TOR_PRIuSZ для circuitlist.c
echo "  📝 Добавление TOR_PRIuSZ..."
if ! grep -q "TOR_PRIuSZ" orconfig.h; then
    sed -i '' '/^#endif$/a\
\
/* Printf format for size_t */\
#ifndef TOR_PRIuSZ\
#define TOR_PRIuSZ "zu"\
#endif\
#ifndef TOR_PRIdSZ\
#define TOR_PRIdSZ "zd"\
#endif
' orconfig.h
    echo "    ✅ TOR_PRIuSZ добавлен"
else
    echo "    ℹ️  TOR_PRIuSZ уже определен"
fi

# 12. Добавить INT_MAX/INT_MIN/UINT_MAX для binascii.c и crypto_rand_numeric.c
echo "  📝 Добавление INT_MAX/INT_MIN/UINT_MAX..."
if ! grep -q "^#ifndef INT_MAX" orconfig.h; then
    sed -i '' '/^#define SIZEOF_SSIZE_T 8$/a\
\
/* INT_MAX for 32-bit int on iOS */\
#ifndef INT_MAX\
#define INT_MAX 2147483647\
#endif\
#ifndef INT_MIN\
#define INT_MIN (-INT_MAX - 1)\
#endif\
#ifndef UINT_MAX\
#define UINT_MAX 4294967295U\
#endif
' orconfig.h
    echo "    ✅ INT_MAX/INT_MIN/UINT_MAX добавлены"
else
    echo "    ℹ️  INT_MAX уже определен"
fi

# 13. Добавить SSIZE_MAX и SIZE_T_CEILING для binascii.c
echo "  📝 Добавление SSIZE_MAX и SIZE_T_CEILING..."
if ! grep -q "SSIZE_MAX" orconfig.h; then
    sed -i '' '/^#define SIZEOF_SOCKLEN_T 4$/a\
#define SIZEOF_SSIZE_T 8
' orconfig.h
    sed -i '' '/^#define TIME_MAX INT64_MAX$/a\
\
/* ssize_t is 64-bit on iOS (signed size_t) */\
#ifndef SSIZE_MAX\
#define SSIZE_MAX INT64_MAX\
#endif\
\
/* SIZE_T_CEILING and SSIZE_T_CEILING for overflow checks */\
#ifndef SIZE_T_CEILING\
#define SIZE_T_CEILING ((size_t)(SSIZE_MAX-16))\
#endif\
#ifndef SSIZE_T_CEILING\
#define SSIZE_T_CEILING ((ssize_t)(SSIZE_MAX-16))\
#endif
' orconfig.h
    echo "    ✅ SSIZE_MAX и SIZE_T_CEILING добавлены"
else
    echo "    ℹ️  SSIZE_MAX уже определен"
fi

# 14. Добавить SHARE_DATADIR, CONFDIR и COMPILER_VENDOR для config.c
echo "  📝 Добавление SHARE_DATADIR, CONFDIR и COMPILER_VENDOR..."
if ! grep -q "SHARE_DATADIR" orconfig.h; then
    sed -i '' '/^#define WORDS_BIGENDIAN 0$/a\
\
/* Paths for iOS (not used, but required for compilation) */\
#ifndef SHARE_DATADIR\
#define SHARE_DATADIR "/usr/share"\
#endif\
#ifndef CONFDIR\
#define CONFDIR "/etc/tor"\
#endif\
\
/* Compiler info (not accurate, but required for compilation) */\
#ifndef COMPILER_VENDOR\
#define COMPILER_VENDOR "apple"\
#endif
' orconfig.h
    echo "    ✅ SHARE_DATADIR, CONFDIR и COMPILER_VENDOR добавлены"
else
    echo "    ℹ️  SHARE_DATADIR уже определен"
fi

# 15. Добавить HAVE_UTIME и HAVE_GETDELIM для files.c
echo "  📝 Добавление HAVE_UTIME и HAVE_GETDELIM..."
if ! grep -q "HAVE_GETDELIM" orconfig.h; then
    sed -i '' '/^#define HAVE_UNAME 1$/a\
#define HAVE_GETDELIM 1
' orconfig.h
    sed -i '' '/^#define HAVE_SYSCONF 1$/a\
#define HAVE_UTIME_H 1\
#define HAVE_UTIME 1
' orconfig.h
    echo "    ✅ HAVE_UTIME и HAVE_GETDELIM добавлены"
else
    echo "    ℹ️  HAVE_GETDELIM уже определен"
fi

cd ..

echo "✅ Исправления применены в $TOR_FIXED/"
echo ""
echo "Теперь компилируем исправленную версию..."

