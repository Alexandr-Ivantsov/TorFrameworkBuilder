#!/bin/bash
# Скрипт для запуска сборки с мониторингом (macOS compatible)

echo "🚀 Запуск сборки Tor с мониторингом..."
echo ""
echo "📊 В другом терминале можно следить за процессом:"
echo "   tail -f build/tor/tor-src/configure.log"
echo ""
echo "⏰ Мониторинг будет показывать прогресс каждые 10 секунд"
echo "   Прервите Ctrl+C если что-то пойдет не так"
echo ""

# Запуск в фоне
bash scripts/build_tor.sh &
BUILD_PID=$!

echo "🔍 PID процесса сборки: $BUILD_PID"
echo ""

# Мониторинг
SECONDS=0
LAST_SIZE=0
STUCK_COUNT=0

while kill -0 $BUILD_PID 2>/dev/null; do
    sleep 10
    elapsed=$SECONDS
    mins=$((elapsed / 60))
    secs=$((elapsed % 60))
    
    # Проверяем, создался ли config.log
    if [ -f "build/tor/tor-src/config.log" ]; then
        current_size=$(stat -f%z build/tor/tor-src/config.log 2>/dev/null || echo 0)
        last_line=$(tail -1 build/tor/tor-src/config.log 2>/dev/null | cut -c1-70)
        
        # Проверка на зависание
        if [ "$current_size" -eq "$LAST_SIZE" ]; then
            STUCK_COUNT=$((STUCK_COUNT + 1))
            echo "⏱️  [$mins:$(printf %02d $secs)] ⚠️  Файл не растет ($STUCK_COUNT/6)"
            
            if [ $STUCK_COUNT -ge 6 ]; then
                echo ""
                echo "❌ Configure не работает уже минуту! Скорее всего завис."
                echo "   Прерываем процесс..."
                kill -9 $BUILD_PID
                break
            fi
        else
            STUCK_COUNT=0
            echo "⏱️  [$mins:$(printf %02d $secs)] ✓ Configure работает: $last_line"
        fi
        
        LAST_SIZE=$current_size
    elif [ -f "build/tor/tor-src/Makefile" ]; then
        echo "⏱️  [$mins:$(printf %02d $secs)] 🔨 Компиляция..."
    else
        echo "⏱️  [$mins:$(printf %02d $secs)] 📋 Подготовка..."
    fi
done

# Проверка результата
wait $BUILD_PID 2>/dev/null
EXIT_CODE=$?

echo ""
echo "════════════════════════════════════════════════════════"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Сборка завершена успешно!"
    echo ""
    echo "📦 Результаты:"
    find build/tor/tor-src/src -name "*.a" 2>/dev/null | head -10
else
    echo "❌ Сборка завершилась с ошибкой (код: $EXIT_CODE)"
    echo ""
    echo "📋 Последние строки логов:"
    if [ -f "build/tor/tor-src/configure.log" ]; then
        echo "   Configure log:"
        tail -10 build/tor/tor-src/configure.log 2>/dev/null
    fi
    if [ -f "build/tor/tor-src/config.log" ]; then
        echo "   Config log:"
        tail -10 build/tor/tor-src/config.log 2>/dev/null
    fi
fi
echo "════════════════════════════════════════════════════════"
