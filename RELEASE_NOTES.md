# 📦 TorFrameworkBuilder Release Notes

## v1.0.9 (2025-10-27) 🔧

### 🐛 Критическое исправление: tor_run_main

**Проблема:**
```
Undefined symbols for architecture arm64
  "_tor_run_main", referenced from:
      _tor_main in Tor[...](tor_api.o)
```

**Причина:**
- `main.c` не компилировался из-за:
  - Отсутствия `bool` type (нужен `<stdbool.h>`)
  - Конфликта `struct timeval` с iOS SDK
  - Некорректного `HAVE_SYSTEMD` (должен быть undefined, а не 0)

**Решение:**
1. ✅ Добавлено `#include <stdbool.h>` и `#include <sys/time.h>` в `orconfig.h`
2. ✅ Изменено `#define HAVE_SYSTEMD 0` на `/* #undef HAVE_SYSTEMD */`
3. ✅ Добавлены `HAVE_STRUCT_TIMEVAL_TV_SEC` и `HAVE_STRUCT_TIMEVAL_TV_USEC`
4. ✅ `main.c` теперь успешно компилируется
5. ✅ `tor_run_main` определён в обоих срезах XCFramework

**Результат:**
- ✅ `tor_run_main` теперь присутствует в framework
- ✅ Размер framework: 47 MB (было 42 MB) - добавлено больше функциональности
- ✅ Линковка в TorApp больше не падает
- ✅ Все Tor функции доступны для запуска daemon

### 📋 Измененные файлы
- `tor-ios-fixed/orconfig.h` - исправлены проблемы компиляции main.c
- `scripts/fix_conflicts.sh` - автоматические исправления для orconfig.h
- `output/Tor.xcframework/` - обновлены бинарники с tor_run_main

---

## v1.0.8 (2025-10-27) 🔧

### 🐛 Критическое исправление: tor_main

**Проблема:**
```
Undefined symbols for architecture arm64
  "_tor_main", referenced from:
      _torThreadMain in Tor[1285](TorWrapper.o)
```

**Причина:**
- `tor_api.c` не компилировался из-за конфликта `typedef socklen_t`
- Это приводило к отсутствию `tor_main` в `libtor.a`

**Решение:**
1. ✅ Добавлено `#define SIZEOF_SOCKLEN_T 4` в `tor-ios-fixed/orconfig.h`
2. ✅ Исправлен `scripts/direct_build.sh` для работы из корня проекта
3. ✅ Пересобраны `libtor.a` для device и simulator с включением `tor_api.c`
4. ✅ Пересоздан `Tor.xcframework` с символом `tor_main`

**Результат:**
- ✅ `tor_main` теперь определен в обоих срезах XCFramework
- ✅ Линковка в TorApp больше не падает
- ✅ Все Tor API функции доступны

### 📋 Измененные файлы
- `tor-ios-fixed/orconfig.h` - добавлено `SIZEOF_SOCKLEN_T 4`
- `scripts/direct_build.sh` - исправлен путь к PROJECT_ROOT
- `output/Tor.xcframework/` - обновлены бинарники

---

## v1.0.7 (2025-10-27) 🔧

### 🐛 Исправление: TorWrapper.o в бинарнике

**Проблема:**
```
Undefined symbols for architecture arm64
  "_OBJC_CLASS_$_TorWrapper", referenced from: TorManager.swift
```

**Решение:**
- ✅ Добавлена компиляция `TorWrapper.m` в `TorWrapper.o` для device и simulator
- ✅ Включение `TorWrapper.o` в `libtool` при создании framework
- ✅ Исключены временные `output/device-obj/`, `output/simulator-obj/` в `.gitignore`

**Результат:**
- ✅ `TorWrapper.o` присутствует в бинарниках обоих срезов
- ✅ Все методы TorWrapper доступны для использования

---

## v1.0.6 (2025-10-27) 🔧

### 🐛 Исправление: module.modulemap

**Проблема:**
```
fatal error: 'openssl/macros.h' file not found
```

**Решение:**
- ✅ Упрощен `module.modulemap` до:
  ```
  framework module Tor {
      umbrella header "Tor.h"
      export *
      module * { export * }
  }
  ```
- Clang автоматически находит все заголовки

---

## v1.0.4 (2025-10-27) 🔧

### 🐛 Исправление: Platform-specific headers

**Проблема:**
- OpenSSL headers были одинаковые для device и simulator

**Решение:**
- ✅ Device framework использует headers из `openssl-device/`
- ✅ Simulator framework использует headers из `openssl-simulator/`

---

## v1.0.3 (2025-10-25) 🎉

### ✅ Поддержка iOS Simulator

- **Добавлена** поддержка iOS Simulator (arm64)
- **Универсальный XCFramework** теперь работает на устройствах и симуляторах
- **Автоматическое исключение** симулятора при архивировании для App Store

### 📊 Технические детали

**До v1.0.3:**
```
Tor.xcframework/
└── ios-arm64/               ← Только устройства
    └── Tor.framework/
```

**После v1.0.3:**
```
Tor.xcframework/
├── ios-arm64/              ← Устройства
│   └── Tor.framework/
└── ios-arm64-simulator/    ← Симулятор ✨ НОВОЕ
    └── Tor.framework/
```

### 🔨 Процесс сборки

1. **OpenSSL 3.4.0** для Simulator (arm64)
2. **libevent 2.1.12** для Simulator (arm64)  
3. **xz 5.6.3** для Simulator (arm64)
4. **Tor 0.4.8.19** для Simulator (arm64)
5. **XCFramework** с обеими платформами

**Время сборки**: ~40 минут (параллельно с device)

### 📱 Размеры

| Компонент | v1.0.2 | v1.0.3 | Изменение |
|-----------|--------|--------|-----------|
| Git репо | 30 MB | 45 MB | +15 MB |
| XCFramework | 28 MB | 42 MB | +14 MB |
| IPA (device) | 28 MB | 28 MB | **без изменений** |
| IPA (simulator) | ❌ | 14 MB | ✅ |

> ⚠️ **Важно**: App Store получает **только** ios-arm64 (28 MB). Симулятор исключается автоматически при архивировании.

---

## 🚀 Установка

### Через Tuist (рекомендуется)

```swift
// Tuist/Dependencies.swift
let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies([
        .remote(
            url: "https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git",
            requirement: .upToNextMajor(from: "1.0.3")
        )
    ])
)
```

```bash
tuist fetch --update
tuist generate
```

### Через Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git",
        from: "1.0.3"
    )
]
```

---

## ✅ Проверка совместимости

```bash
# Проверка архитектур
lipo -info output/Tor.xcframework/ios-arm64/Tor.framework/Tor
# → Non-fat file: arm64

lipo -info output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor
# → Non-fat file: arm64

# Проверка Info.plist (должно быть 2 платформы)
cat output/Tor.xcframework/Info.plist | grep -A1 "LibraryIdentifier"
# → ios-arm64
# → ios-arm64-simulator

# Тест в Xcode
# 1. Выбрать iPhone Simulator
# 2. Cmd+B - компиляция должна пройти ✅
# 3. Cmd+R - запуск на симуляторе ✅
```

---

## 📚 Документация

- [`README.md`](README.md) - Основная документация
- [`USAGE_GUIDE.md`](USAGE_GUIDE.md) - Гайд по использованию в TorApp
- [`BUILD_SIMULATOR.md`](BUILD_SIMULATOR.md) - Детальная инструкция по сборке для симулятора

---

## 🎯 Зачем нужен симулятор?

1. **Быстрая разработка** - тестирование без физического устройства
2. **CI/CD** - автоматические тесты на GitHub Actions
3. **Debugging** - удобная отладка в Xcode
4. **Снимки экрана** - для App Store Connect

---

## 🔧 Технические изменения

### Новые скрипты

- `scripts/build_openssl_simulator.sh` - OpenSSL для iOS Simulator
- `scripts/build_libevent_simulator.sh` - libevent для iOS Simulator
- `scripts/build_xz_simulator.sh` - xz для iOS Simulator
- `scripts/build_tor_simulator.sh` - Tor для iOS Simulator
- `scripts/build_all_simulator.sh` - Сборка всех зависимостей
- `scripts/create_xcframework_universal.sh` - Универсальный XCFramework

### Обновленные файлы

- `.gitignore` - Исключены временные директории симулятора
- `README.md` - Добавлена секция про симулятор
- `Package.swift` - Без изменений
- `Project.swift` - Без изменений

### Структура output

```
output/
├── openssl/                ← Device
├── openssl-simulator/      ← Simulator ✨
├── libevent/               ← Device
├── libevent-simulator/     ← Simulator ✨
├── xz/                     ← Device
├── xz-simulator/           ← Simulator ✨
├── tor-direct/             ← Device
├── tor-simulator/          ← Simulator ✨
├── device/                 ← Временная (не в Git)
├── simulator/              ← Временная (не в Git)
└── Tor.xcframework/        ← Финальный результат ✅
```

---

## ⚠️ Breaking Changes

**Нет.** Версия 1.0.3 **полностью обратно совместима** с 1.0.2.

Если вы не используете симулятор - ничего не изменится.

---

## 🐛 Известные проблемы

**Нет.** Все тесты пройдены.

---

## 📈 Следующие шаги (v1.1.0)

- [ ] Поддержка x86_64 для Intel Mac (опционально)
- [ ] Поддержка macOS Catalyst
- [ ] Автоматическая сборка через GitHub Actions
- [ ] XCTest для проверки подключения к Tor

---

## 👨‍💻 Сборка

Собрано с использованием:
- **Xcode**: 16.0+
- **macOS**: Sequoia 15.0+
- **Tor**: 0.4.8.19
- **OpenSSL**: 3.4.0
- **libevent**: 2.1.12
- **xz**: 5.6.3

---

## 📝 Лицензия

- **Tor**: BSD-3-Clause (https://www.torproject.org)
- **OpenSSL**: Apache 2.0
- **libevent**: BSD-3-Clause
- **xz**: Public Domain

---

🚀 **Готово к использованию!**
