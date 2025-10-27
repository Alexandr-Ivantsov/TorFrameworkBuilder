# Скрипты для пересборки

## Основные скрипты

- `build_openssl.sh` - Сборка OpenSSL 3.4.0
- `build_libevent.sh` - Сборка libevent 2.1.12
- `build_xz.sh` - Сборка xz 5.6.3
- `fix_conflicts.sh` - Исправление конфликтов Tor для iOS
- `direct_build.sh` - Прямая компиляция Tor
- `create_framework_final.sh` - Создание Tor.xcframework

## Порядок пересборки

```bash
# 1. Собрать зависимости (если еще нет)
bash scripts/build_openssl.sh
bash scripts/build_libevent.sh
bash scripts/build_xz.sh

# 2. Исправить конфликты Tor
bash scripts/fix_conflicts.sh

# 3. Скомпилировать Tor
bash scripts/direct_build.sh > build.log 2>&1 &
# Подождать ~5 минут

# 4. Создать XCFramework
bash scripts/create_framework_final.sh
```

Результат: `output/Tor.xcframework`

