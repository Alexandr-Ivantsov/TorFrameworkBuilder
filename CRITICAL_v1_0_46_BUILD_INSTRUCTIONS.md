# 🚨 CRITICAL: v1.0.46 - ИНСТРУКЦИЯ ПО СБОРКЕ С ПАТЧЕМ

**Дата:** 29 октября 2025, 13:10  
**Статус:** 🔴 **BINARY БЕЗ ПАТЧА - ТРЕБУЕТСЯ ЛОКАЛЬНАЯ СБОРКА!**

---

## 🔍 ПРОБЛЕМА

**Package.swift использует `.binaryTarget`** - это значит SPM **НЕ КОМПИЛИРУЕТ** Tor, а просто **КОПИРУЕТ ГОТОВЫЙ BINARY** из репозитория!

```swift
.binaryTarget(
    name: "TorFrameworkBuilder",
    path: "output/Tor.xcframework"  // ← Готовый binary!
)
```

**Это объясняет почему патч не работал 12 версий!**

---

## ✅ РЕШЕНИЕ: ЛОКАЛЬНАЯ СБОРКА

### Вариант 1: Использовать локальную копию TorFrameworkBuilder

#### Шаг 1: Клонировать TorFrameworkBuilder локально

```bash
cd ~/admin
git clone https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git
cd TorFrameworkBuilder
git checkout 1.0.46
```

#### Шаг 2: В TorApp использовать локальную зависимость

**В `Tuist/Dependencies.swift` - УДАЛИТЬ remote:**

```swift
dependencies: [
    .external(name: "Store")
    // УДАЛИТЬ: .remote TorFrameworkBuilder
]
```

**В `Project.swift` - ДОБАВИТЬ локальный путь:**

```swift
dependencies: [
    .external(name: "Store"),
    .xcframework(path: "../TorFrameworkBuilder/output/Tor.xcframework")
]
```

#### Шаг 3: Пересобрать Tor С ПАТЧЕМ

```bash
cd ~/admin/TorFrameworkBuilder

# 1. Проверить что патч применён:
grep "Using memory with INHERIT_RES_KEEP" \
    tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c

# Должно показать:
# log_info(LD_CRYPTO, "Using memory with INHERIT_RES_KEEP on iOS (with PID check).");

# 2. Если патча НЕТ - применить:
bash scripts/fix_conflicts.sh

# 3. Собрать зависимости (если ещё не собраны):
bash scripts/build_openssl.sh
bash scripts/build_libevent.sh
bash scripts/build_xz.sh

# 4. Собрать зависимости для simulator:
bash scripts/build_all_simulator.sh

# 5. Собрать Tor для device:
bash scripts/direct_build.sh

# 6. Собрать Tor для simulator:
bash scripts/build_tor_simulator.sh

# 7. Создать XCFramework:
bash scripts/create_xcframework_universal.sh

# 8. КРИТИЧЕСКАЯ ПРОВЕРКА:
./verify_patch.sh output/Tor.xcframework/ios-arm64/Tor.framework/Tor

# Должно показать:
# ✅✅✅ SUCCESS: Patch FOUND in binary!
```

#### Шаг 4: Использовать в TorApp

```bash
cd ~/admin/TorApp
tuist clean
tuist generate
open TorApp.xcworkspace
# Run on Simulator
```

---

### Вариант 2: Форк с предсобранным binary

Если локальная сборка не работает, создайте форк с **УЖЕ ПЕРЕСОБРАННЫМ** binary.

---

## 🎯 ПОЧЕМУ ЭТО ЕДИНСТВЕННОЕ РЕШЕНИЕ

### Архитектура v1.0.45 (НЕ РАБОТАЕТ):

```
Package.swift → .binaryTarget
    ↓
SPM копирует output/Tor.xcframework (готовый binary)
    ↓
НЕТ компиляции! НЕТ применения патча!
    ↓
Binary БЕЗ патча → КРАШ!
```

### Архитектура v1.0.46 (РАБОТАЕТ):

```
Локальная копия TorFrameworkBuilder
    ↓
Пользователь запускает сборку вручную
    ↓
Tor компилируется С ПАТЧЕМ
    ↓
XCFramework создаётся С ПАТЧЕМ
    ↓
Проект использует локальный XCFramework
    ↓
Binary С ПАТЧЕМ → НЕТ краша! ✅
```

---

## 📊 АЛЬТЕРНАТИВА: iCepa Tor.framework

Если локальная сборка слишком сложна, используйте **проверенное решение**:

```bash
cd ~/admin/TorApp/Frameworks
curl -L -o Tor.xcframework.zip \
  https://github.com/iCepa/Tor.framework/releases/latest/download/Tor.xcframework.zip
unzip Tor.xcframework.zip
```

**В `Project.swift`:**
```swift
.xcframework(path: "Frameworks/Tor.xcframework")  // iCepa
```

**Минус:** Может потребовать изменений в TorManager (другой API).

---

## 🔥 КРИТИЧНО ВАЖНО

**Binary в репозитории v1.0.46 БЕЗ патча!**

**Это НЕ БАГ, это ОГРАНИЧЕНИЕ `.binaryTarget`!**

**Единственный способ получить binary С ПАТЧЕМ:**
1. Локальная сборка
2. ИЛИ форк с предсобранным binary
3. ИЛИ iCepa Tor.framework

**ВЫБОР ЗА ВАМИ!**

---

**Дата:** 29 октября 2025  
**Версия:** v1.0.46  
**Автор:** TorFrameworkBuilder

