#!/bin/bash
# Асинхронная компиляция с мониторингом

cd "$(dirname "$0")"

LOG_FILE="direct_build.log"
PROGRESS_FILE="build_progress.txt"

# Очистка
rm -f "$LOG_FILE" "$PROGRESS_FILE"
echo "0" > "$PROGRESS_FILE"

# Запуск сборки в фоне
echo "🚀 Запуск компиляции в фоне..."
bash direct_build.sh > "$LOG_FILE" 2>&1 &
BUILD_PID=$!

echo "📊 PID сборки: $BUILD_PID"
echo "📝 Лог: $LOG_FILE"
echo ""
echo "Мониторинг (обновление каждые 3 секунды):"
echo "════════════════════════════════════════════════════════"

# Мониторинг
start_time=$(date +%s)
last_count=0

while kill -0 $BUILD_PID 2>/dev/null; do
    sleep 3
    
    elapsed=$(($(date +%s) - start_time))
    mins=$((elapsed / 60))
    secs=$((elapsed % 60))
    
    # Подсчет скомпилированных файлов
    current_count=$(grep -c "✓" "$LOG_FILE" 2>/dev/null || echo 0)
    failed_count=$(grep -c "✗" "$LOG_FILE" 2>/dev/null || echo 0)
    skipped_count=$(grep -c "⊘" "$LOG_FILE" 2>/dev/null || echo 0)
    
    # Прогресс
    if [ $current_count -gt $last_count ]; then
        echo "[$mins:$(printf %02d $secs)] ✓ $current_count | ✗ $failed_count | ⊘ $skipped_count"
        last_count=$current_count
    elif [ $((elapsed % 15)) -eq 0 ]; then
        echo "[$mins:$(printf %02d $secs)] Работает... (последние строки:)"
        tail -3 "$LOG_FILE" 2>/dev/null | sed 's/^/  /'
    fi
done

# Результат
wait $BUILD_PID
EXIT_CODE=$?

echo "════════════════════════════════════════════════════════"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Сборка завершена успешно!"
    echo ""
    tail -20 "$LOG_FILE"
else
    echo "❌ Ошибка сборки (код: $EXIT_CODE)"
    echo ""
    echo "Последние 30 строк лога:"
    tail -30 "$LOG_FILE"
fi

echo ""
echo "📁 Полный лог: $LOG_FILE"

