# 📦 TorFrameworkBuilder v1.0.3

## 🎉 Что нового

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
