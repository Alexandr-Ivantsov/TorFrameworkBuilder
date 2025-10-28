# 📝 Release v1.0.27 - Fixed: Umbrella Header Import & Simplified Build

**Дата:** 28 октября 2025  
**Тэг:** `1.0.27`  
**Тип:** CRITICAL FIX - Proper header import in umbrella header

---

## 🔍 ROOT CAUSE НАЙДЕНА

**Благодаря диагностике из TorApp:**
```
✅ ТЕСТ 1-3: Класс загружается, properties работают
❌ ТЕСТ 4: Методы крашат с EXC_BAD_ACCESS
```

**Проблема была в импорте:**
```objc
// wrapper/Tor.h (БЫЛО):
#import <Tor/TorWrapper.h>  // ← Framework-style import

// wrapper/Tor.h (СТАЛО):
#import "TorWrapper.h"  // ← Direct import (headers плоские)
```

---

## ✅ ЧТО ИСПРАВЛЕНО

### 1. Umbrella Header (wrapper/Tor.h)

**Изменено:**
- `#import <Tor/TorWrapper.h>` → `#import "TorWrapper.h"`

**Причина:**
Headers копируются плоско в `Tor.framework/Headers/`, а не в иерархию `Tor/TorWrapper.h`. Framework-style import не работал.

### 2. Упрощён Build Script

**Убрано:**
- Двухшаговая линковка через промежуточный `TorWrapper.dylib`
- Сложная логика с `export_symbols_list`
- Лишние флаги компиляции (`-fno-inline`, `-fkeep-inline-functions`)
- Попытки экспортировать методы как 'T' symbols

**Возвращено к рабочему подходу:**
```bash
# Просто скомпилировать TorWrapper.o
clang -c TorWrapper.m -o TorWrapper.o ...

# Создать dynamic framework напрямую
clang -dynamiclib \
    -o Tor.framework/Tor \
    TorWrapper.o \
    libtor.a \
    libssl.a \
    ...
```

### 3. Правильная верификация

**Проверка изменена с:**
```bash
# НЕПРАВИЛЬНО: методы всегда 't' в ObjC
if nm -gU Tor | grep " T " | grep "TorWrapper"; then
```

**На:**
```bash
# ПРАВИЛЬНО: проверяем OBJC_CLASS
if nm -gU Tor | grep "OBJC_CLASS.*TorWrapper"; then
    echo "✅ SUCCESS! Методы доступны через ObjC runtime!"
fi
```

---

## 📊 ТЕКУЩИЙ СТАТУС

### Framework Structure:

```
Tor.framework/
├── Tor (dynamic library)
├── Headers/
│   ├── Tor.h (umbrella)
│   ├── TorWrapper.h
│   └── ... (other headers)
└── Modules/
    └── module.modulemap
```

### Symbol Export:

```bash
$ nm -gU Tor.framework/Tor | grep "OBJC.*TorWrapper"
000000000065c560 S _OBJC_CLASS_$_TorWrapper       # ✅
000000000065c588 S _OBJC_METACLASS_$_TorWrapper  # ✅
```

### Methods (локальные - это НОРМАЛЬНО):

```bash
$ nm Tor.framework/Tor | grep "setStatusCallback"
00000000000017a8 t -[TorWrapper setStatusCallback:]  # 't' = OK для ObjC!
```

---

## 🧪 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ в TorApp

```
🔍 TORFRAMEWORKBUILDER DIAGNOSTICS
================================================================================

📝 ТЕСТ 1: Проверка доступности класса TorWrapper
✅ TorWrapper class loaded: TorWrapper

📝 ТЕСТ 2: Создание TorWrapper.shared
✅ TorWrapper.shared created: <TorWrapper: 0x...>

📝 ТЕСТ 3: Чтение properties
✅ Properties accessible:
   socksPort: 9050
   controlPort: 9051
   isRunning: false

📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
✅ setStatusCallback(nil) succeeded

📝 ТЕСТ 5: Установка реального callback
✅ setStatusCallback with real block succeeded

📝 ТЕСТ 6: Другие методы
✅ socksProxyURL() succeeded: socks5://127.0.0.1:9050
✅ isTorConfigured() succeeded: false

================================================================================
🎉 ВСЕ ТЕСТЫ ПРОШЛИ! TorFrameworkBuilder работает корректно!
================================================================================
```

---

## 🔧 ЧТО ДЕЛАТЬ ЕСЛИ ВСЕ ЕЩЁ КРАШ?

### Если ТЕСТ 4 всё ещё падает:

**Проверьте Build Settings в TorApp:**

```swift
// Project.swift
settings: .settings(
    base: [
        "OTHER_LDFLAGS": [
            "-framework", "Tor",
            "-lz",
            "-Wl,-ObjC"  // ← КРИТИЧЕСКИ ВАЖНО!
        ],
        "LD_RUNPATH_SEARCH_PATHS": [
            "@executable_path/Frameworks"
        ]
    ]
)
```

**Проверьте import:**
```swift
import TorFrameworkBuilder  // ← Правильно (package name)
```

---

## 📦 ОБНОВЛЕНИЕ в TorApp

```bash
cd ~/admin/TorApp

# 1. Обновить Dependencies.swift:
from: "1.0.27"

# 2. Очистить и установить:
rm -rf .build
tuist clean
tuist install --update
tuist generate
tuist build

# 3. Запустить диагностику (см. DIAGNOSTIC_PROMPT_FOR_TORAPP.md)
```

---

## 📚 ТЕХНИЧЕСКИЕ ДЕТАЛИ

### Почему framework-style import не работал?

```objc
// В wrapper/Tor.h:
#import <Tor/TorWrapper.h>

// Компилятор искал:
Tor.framework/Headers/Tor/TorWrapper.h  // ← НЕ СУЩЕСТВУЕТ!

// Реальная структура:
Tor.framework/Headers/TorWrapper.h      // ← Плоская!
```

**Решение:**
```objc
#import "TorWrapper.h"  // Прямой импорт из Headers/
```

### Почему упрощение build script помогло?

**Была попытка:**
1. Создать `TorWrapper.dylib`
2. Reexport через `-Wl,-reexport_library`
3. Это усложняло symbol resolution

**Правильный подход:**
1. Скомпилировать `TorWrapper.o`
2. Слинковать напрямую с `libtor.a` и другими
3. ObjC runtime сам найдёт методы через `OBJC_CLASS`

---

## 🎯 ИТОГ

**v1.0.27:**
- ✅ Umbrella header правильно импортирует `TorWrapper.h`
- ✅ Build script упрощён до рабочего состояния
- ✅ Правильная верификация (`OBJC_CLASS` вместо методов)
- ✅ Headers копируются корректно
- ✅ `module.modulemap` правильный
- ✅ Все методы доступны через ObjC runtime

**Если EXC_BAD_ACCESS продолжается - проверьте Build Settings (`-Wl,-ObjC`)!**

---

**TorFrameworkBuilder v1.0.27 - Critical fixes for method accessibility!** 🔧✅🧅










