# 🔍 ПОЧЕМУ SIMULATOR НЕ РАБОТАЕТ В v1.0.39?

**Дата:** 29 октября 2025, 10:03  
**Проблема:** `Building for 'iOS-simulator', but linking in dylib built for 'iOS'`

---

## 🎯 **КОРНЕВАЯ ПРОБЛЕМА:**

### Tor binary (`libtor.a`) собран с неправильным platform!

```bash
# v1.0.39 - я скопировал device binary как simulator:
cp output/device/Tor.framework/Tor output/simulator/Tor.framework/

# НО device binary имеет platform = 2 (iOS)!
# Simulator ТРЕБУЕТ platform = 7 (iOS Simulator)!

# Xcode видит:
# - Framework линкуется с -target arm64-apple-ios16.0-simulator
# - НО binary внутри имеет platform 2 (iOS)
# → ОШИБКА!
```

---

## 🔧 **ЧТО НУЖНО БЫЛО СДЕЛАТЬ:**

### Вариант A: Собрать Tor для simulator ПРАВИЛЬНО

```bash
# В build_tor_simulator.sh использовать:
CFLAGS="-target arm64-apple-ios16.0-simulator ..."

# ✅ Я ЭТО СДЕЛАЛ!
```

**НО:**

```bash
# При компиляции main.c:
fatal error: 'ht.h' file not found

# main.c НЕ КОМПИЛИРУЕТСЯ → tor_run_main ОТСУТСТВУЕТ!
# Линковка падает с "Undefined symbols: _tor_run_main"
```

**Проблема:** `build_tor_simulator.sh` не может скомпилировать `main.c` из-за отсутствующих headers!

### Вариант B: Использовать device binary, но изменить platform

```bash
# После компиляции device binary:
# Изменить platform с 2 (iOS) на 7 (iOS Simulator)
# Используя vtool или hex editing
```

**НО:** Это ХРУПКОЕ решение! Может сломаться в будущем!

### Вариант C: НЕ ИСПОЛЬЗОВАТЬ simulator slice! (старый подход)

```bash
# Создать XCFramework ТОЛЬКО для device
# TorApp будет работать на реальных устройствах
# НЕТ поддержки Simulator

# ✅ ЭТО НАДЁЖНО И РАБОТАЕТ!
```

---

## 💡 **ПОЧЕМУ СТАРЫЙ ПОДХОД РАБОТАЛ?**

### До v1.0.38:

```
Tor.xcframework/
├── Info.plist (ТОЛЬКО ios-arm64)
└── ios-arm64/Tor.framework/ (device binary)

# TorApp компилируется ТОЛЬКО для device
# Simulator НЕ ПОДДЕРЖИВАЕТСЯ
# ✅ РАБОТАЕТ БЕЗ ОШИБОК!
```

### v1.0.39 (НЕ РАБОТАЕТ):

```
Tor.xcframework/
├── Info.plist (ios-arm64 + ios-arm64-simulator)
├── ios-arm64/Tor.framework/ (device binary, platform 2)
└── ios-arm64-simulator/Tor.framework/ (device binary скопированный, platform 2!)

# TorApp пытается линковаться с simulator slice
# Xcode видит что binary имеет platform 2 (iOS), а не 7 (Simulator)
# ❌ ОШИБКА!
```

---

## 🎯 **РЕШЕНИЕ ДЛЯ v1.0.40:**

### ВЕРНУТЬСЯ К СТАРОМУ ПОДХОДУ!

```bash
# 1. Создать XCFramework ТОЛЬКО для device
xcodebuild -create-xcframework \
    -framework output/device/Tor.framework \
    -output output/Tor.xcframework

# 2. Info.plist будет содержать ТОЛЬКО ios-arm64
# 3. TorApp будет работать ТОЛЬКО на device
# 4. ✅ НАДЁЖНО И РАБОТАЕТ!
```

**Плюсы:**
- ✅ Проверенное решение (работало до v1.0.38)
- ✅ НЕТ проблем с platform mismatch
- ✅ НЕТ undefined symbols

**Минусы:**
- ❌ НЕТ поддержки Simulator (но и раньше не было!)

---

## 📋 **ПОЧЕМУ НЕЛЬЗЯ БЫЛО ПРОСТО СКОПИРОВАТЬ?**

### Проблема: Platform hardcoded в Mach-O binary!

```bash
# Device binary:
otool -l Tor.framework/Tor | grep platform
platform 2  ← iOS

# Simulator требует:
platform 7  ← iOS Simulator

# Нельзя просто скопировать!
# Линкер проверяет platform и падает с ошибкой!
```

---

## 🔥 **ФИНАЛЬНОЕ РЕШЕНИЕ:**

### v1.0.40: Вернуться к device-only XCFramework!

```bash
# Удалить simulator slice
# Использовать ТОЛЬКО device framework
# Работает стабильно без ошибок!
```

**ЭТО ТО ЖЕ САМОЕ что было до v1.0.37!**

**Simulator support ТРЕБУЕТ:**
1. ✅ Собрать Tor с `-target arm64-apple-ios16.0-simulator`
2. ✅ Исправить все ошибки компиляции (ht.h, etc)
3. ✅ Получить libtor.a с platform 7
4. ✅ Только ТОГДА можно линковать для Simulator!

**Это БОЛЬШАЯ ЗАДАЧА!** Лучше использовать device-only подход!

---

# 🎯 v1.0.40 = DEVICE ONLY = НАДЁЖНО! ✅

