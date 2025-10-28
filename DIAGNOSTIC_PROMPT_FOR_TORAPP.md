# 🔍 Диагностический Промпт для TorApp - Проверка интеграции с TorFrameworkBuilder

**Дата:** 28 октября 2025  
**Версия TorFrameworkBuilder:** 1.0.26  
**Цель:** Найти ТОЧНУЮ причину EXC_BAD_ACCESS при вызове методов TorWrapper

---

## 📋 ЧТО НУЖНО ПРОВЕРИТЬ В TORAPP

### ЭТАП 1: Проверка что framework загружен в runtime

#### 1.1 Добавить диагностический код в TorApp

**Файл:** `TorApp/Sources/Features/Tor/TorManager.swift`

**Добавить в самое начало класса TorManager:**

```swift
import TorFrameworkBuilder
import Foundation

@MainActor
final class TorManager: ObservableObject {
    
    // ===== ДИАГНОСТИЧЕСКИЙ КОД - НАЧАЛО =====
    
    static func runDiagnostics() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 TORFRAMEWORKBUILDER DIAGNOSTICS")
        print(String(repeating: "=", count: 80) + "\n")
        
        // ТЕСТ 1: Класс TorWrapper доступен?
        print("📝 ТЕСТ 1: Проверка доступности класса TorWrapper")
        do {
            let torWrapperClass = TorWrapper.self
            print("✅ TorWrapper class loaded: \(torWrapperClass)")
        } catch {
            print("❌ FAILED: Cannot access TorWrapper class: \(error)")
            return
        }
        
        // ТЕСТ 2: Singleton создаётся?
        print("\n📝 ТЕСТ 2: Создание TorWrapper.shared")
        do {
            let wrapper = TorWrapper.shared
            print("✅ TorWrapper.shared created: \(wrapper)")
            print("   Address: \(Unmanaged.passUnretained(wrapper).toOpaque())")
        } catch {
            print("❌ FAILED: Cannot create TorWrapper.shared: \(error)")
            return
        }
        
        // ТЕСТ 3: Properties доступны?
        print("\n📝 ТЕСТ 3: Чтение properties")
        do {
            let wrapper = TorWrapper.shared
            let socksPort = wrapper.socksPort
            let controlPort = wrapper.controlPort
            let isRunning = wrapper.isRunning
            print("✅ Properties accessible:")
            print("   socksPort: \(socksPort)")
            print("   controlPort: \(controlPort)")
            print("   isRunning: \(isRunning)")
        } catch {
            print("❌ FAILED: Cannot read properties: \(error)")
            return
        }
        
        // ТЕСТ 4: Методы вызываются? (setStatusCallback с nil)
        print("\n📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)")
        do {
            let wrapper = TorWrapper.shared
            wrapper.setStatusCallback(nil)
            print("✅ setStatusCallback(nil) succeeded")
        } catch {
            print("❌ FAILED: setStatusCallback(nil) crashed: \(error)")
            return
        }
        
        // ТЕСТ 5: Callback можно установить?
        print("\n📝 ТЕСТ 5: Установка реального callback")
        do {
            let wrapper = TorWrapper.shared
            var callbackInvoked = false
            wrapper.setStatusCallback { status, message in
                callbackInvoked = true
                print("   📞 Callback invoked! Status: \(status), Message: \(message ?? "nil")")
            }
            print("✅ setStatusCallback with real block succeeded")
            print("   (Callback not invoked yet, but set successfully)")
        } catch {
            print("❌ FAILED: Cannot set real callback: \(error)")
            return
        }
        
        // ТЕСТ 6: Другие методы работают?
        print("\n📝 ТЕСТ 6: Другие методы")
        do {
            let wrapper = TorWrapper.shared
            let socksURL = wrapper.socksProxyURL()
            print("✅ socksProxyURL() succeeded: \(socksURL)")
            
            let isTorConfigured = wrapper.isTorConfigured()
            print("✅ isTorConfigured() succeeded: \(isTorConfigured)")
        } catch {
            print("❌ FAILED: Other methods crashed: \(error)")
            return
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("🎉 ВСЕ ТЕСТЫ ПРОШЛИ! TorFrameworkBuilder работает корректно!")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    // ===== ДИАГНОСТИЧЕСКИЙ КОД - КОНЕЦ =====
    
    // ... остальной код TorManager ...
}
```

#### 1.2 Вызвать диагностику при запуске приложения

**Файл:** `TorApp/Sources/TorAppApp.swift`

```swift
import SwiftUI
import TorFrameworkBuilder

@main
struct TorAppApp: App {
    
    init() {
        // ЗАПУСК ДИАГНОСТИКИ ПЕРЕД ВСЕМ ОСТАЛЬНЫМ
        print("🚀 Starting TorApp diagnostics...")
        TorManager.runDiagnostics()
        print("✅ Diagnostics complete, continuing app launch...\n")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### 1.3 Запустить приложение и собрать логи

```bash
cd ~/admin/TorApp
tuist clean
tuist generate
tuist build

# Или запустить через Xcode и смотреть Console
```

---

## 📊 РЕЗУЛЬТАТЫ: Что означают логи?

### Сценарий 1: Краш на ТЕСТ 1

```
📝 ТЕСТ 1: Проверка доступности класса TorWrapper
❌ FAILED: Cannot access TorWrapper class
```

**Причина:** Framework не импортирован или не линкуется

**Решение:**
1. Проверить `import TorFrameworkBuilder` есть
2. Проверить `Dependencies.swift`:
   ```swift
   .remote(
       url: "https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git",
       requirement: .upToNextMajor(from: "1.0.26")
   )
   ```
3. Выполнить:
   ```bash
   rm -rf .build
   tuist clean
   tuist install --update
   tuist generate
   ```

---

### Сценарий 2: Краш на ТЕСТ 2

```
✅ TorWrapper class loaded: TorWrapper
📝 ТЕСТ 2: Создание TorWrapper.shared
❌ FAILED: Cannot create TorWrapper.shared
```

**Причина:** Проблема в `+shared` или `initPrivate`

**Решение:**
- Это был баг в v1.0.20, исправлен в v1.0.21
- Обновить на latest версию (1.0.26)

---

### Сценарий 3: Краш на ТЕСТ 3

```
✅ TorWrapper.shared created: <TorWrapper: 0x...>
📝 ТЕСТ 3: Чтение properties
❌ FAILED: Cannot read properties
```

**Причина:** Properties не доступны (маловероятно, но возможно)

**Решение:**
- Проверить что TorWrapper.h правильно импортирован
- Проверить module.modulemap в framework

---

### Сценарий 4: Краш на ТЕСТ 4

```
✅ Properties accessible
📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
❌ FAILED: setStatusCallback(nil) crashed
```

**Причина:** Методы НЕ экспортированы из framework

**ЭТО ОЗНАЧАЕТ ЧТО ПРОБЛЕМА В TORFRAMEWORKBUILDER!**

**Решение:**
- Проверить `nm -gU Tor.framework/Tor | grep OBJC_CLASS`
- Если `OBJC_CLASS_$_TorWrapper` НЕТ → пересобрать framework

---

### Сценарий 5: Краш на ТЕСТ 5

```
✅ setStatusCallback(nil) succeeded
📝 ТЕСТ 5: Установка реального callback
❌ FAILED: Cannot set real callback
```

**Причина:** Проблема с callback lifecycle

**Решение:**
- Это был баг в v1.0.22, исправлен в v1.0.23
- Обновить на latest версию (1.0.26)

---

### Сценарий 6: Все тесты прошли!

```
🎉 ВСЕ ТЕСТЫ ПРОШЛИ! TorFrameworkBuilder работает корректно!
```

**Вывод:** Framework работает! Проблема где-то в другом месте.

**Проверить:**
1. Реальный код вызова Tor (возможно другой баг)
2. Thread safety (вызываете ли с правильного потока?)
3. Tor configuration (правильный torrc?)

---

## 🔍 ЭТАП 2: Проверка Build Settings

### 2.1 Проверить Other Linker Flags

```bash
cd ~/admin/TorApp
cat Project.swift | grep -A 20 "OTHER_LDFLAGS"
```

**Должно содержать:**
```
"-framework", "Tor",
"-lz",
"-Wl,-ObjC"
```

**Если нет - добавить в Project.swift:**
```swift
settings: .settings(
    base: [
        "OTHER_LDFLAGS": [
            "-framework", "Tor",
            "-lz",
            "-Wl,-ObjC"
        ]
    ]
)
```

---

### 2.2 Проверить Runpath Search Paths

```bash
cd ~/admin/TorApp
cat Project.swift | grep -A 20 "LD_RUNPATH_SEARCH_PATHS"
```

**Должно содержать:**
```
"@executable_path/Frameworks"
```

**Если нет - добавить:**
```swift
settings: .settings(
    base: [
        "LD_RUNPATH_SEARCH_PATHS": ["@executable_path/Frameworks"]
    ]
)
```

---

### 2.3 Проверить что Framework в Bundle

После сборки проверить:
```bash
cd ~/admin/TorApp
find .build -name "Tor.framework" -type d

# Должен вывести путь к framework
```

---

## 🧪 ЭТАП 3: Проверка самого Framework

### 3.1 Проверить OBJC_CLASS экспортирован

```bash
cd ~/admin/TorFrameworkBuilder

# Для симулятора:
nm -gU output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor | grep "OBJC_CLASS.*TorWrapper"

# Ожидаемо:
# 000000000065c560 S _OBJC_CLASS_$_TorWrapper
# 000000000065c588 S _OBJC_METACLASS_$_TorWrapper
```

**Если пусто:**
```bash
# Пересобрать framework:
bash scripts/create_xcframework_universal.sh

# Проверить снова
```

---

### 3.2 Проверить методы присутствуют в binary

```bash
nm output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor | grep "setStatusCallback"

# Ожидаемо:
# 00000000000017a8 t -[TorWrapper setStatusCallback:]
```

**'t' flag - это НОРМАЛЬНО для ObjC методов!**

**Если пусто - TorWrapper.o не был слинкован:**
```bash
# Проверить что TorWrapper.o существует:
ls output/simulator-obj/TorWrapper.o

# Если нет - пересобрать:
bash scripts/create_xcframework_universal.sh
```

---

### 3.3 Проверить архитектуру

```bash
lipo -info output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor

# Ожидаемо:
# Non-fat file ... is architecture: arm64
```

---

## 📝 ЭТАП 4: Собрать полный отчёт

### 4.1 Результаты всех тестов

Скопировать ВСЕ логи из Console после запуска TorApp с диагностикой:
```
🔍 TORFRAMEWORKBUILDER DIAGNOSTICS
... (весь вывод) ...
```

### 4.2 Build Settings

```bash
cd ~/admin/TorApp
cat Project.swift > /tmp/torapp_project.txt
```

Приложить содержимое `/tmp/torapp_project.txt`

### 4.3 Framework info

```bash
cd ~/admin/TorFrameworkBuilder

echo "===== OBJC_CLASS check =====" > /tmp/framework_info.txt
nm -gU output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor | grep "OBJC" >> /tmp/framework_info.txt

echo "\n===== Methods check =====" >> /tmp/framework_info.txt
nm output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor | grep "setStatusCallback" >> /tmp/framework_info.txt

echo "\n===== Architecture =====" >> /tmp/framework_info.txt
lipo -info output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor >> /tmp/framework_info.txt
```

Приложить содержимое `/tmp/framework_info.txt`

### 4.4 Crash Log (если есть краш)

Если приложение крашится, найти crash log:
```bash
# На симуляторе:
~/Library/Logs/DiagnosticReports/TorApp*.crash

# Или в Xcode:
# Window → Organizer → Crashes
```

Приложить последний crash log

---

## 🎯 ИТОГОВЫЙ CHECKLIST

Перед отправкой отчёта убедитесь что собрали:

- [ ] Логи всех диагностических тестов (ТЕСТ 1-6)
- [ ] `Project.swift` содержимое
- [ ] Результаты проверки OBJC_CLASS
- [ ] Результаты проверки методов
- [ ] Архитектура framework
- [ ] Crash log (если был краш)
- [ ] Версия TorFrameworkBuilder (из Dependencies.swift)
- [ ] Версия Xcode: `xcodebuild -version`
- [ ] Версия macOS: `sw_vers`

---

## 📤 ФОРМАТ ОТЧЁТА

```markdown
# TorApp Diagnostic Report

## Environment
- TorFrameworkBuilder version: 1.0.26
- Xcode version: [ВСТАВИТЬ]
- macOS version: [ВСТАВИТЬ]
- Device/Simulator: [ВСТАВИТЬ]

## Diagnostic Tests Results
[ВСТАВИТЬ ПОЛНЫЙ ВЫВОД ТЕСТОВ 1-6]

## Framework Verification
### OBJC_CLASS Check
[ВСТАВИТЬ nm -gU ... grep OBJC]

### Methods Check
[ВСТАВИТЬ nm ... grep setStatusCallback]

### Architecture
[ВСТАВИТЬ lipo -info]

## Build Settings
### OTHER_LDFLAGS
[ВСТАВИТЬ из Project.swift]

### LD_RUNPATH_SEARCH_PATHS
[ВСТАВИТЬ из Project.swift]

## Crash Log (if any)
[ВСТАВИТЬ crash log или "No crash"]

## Conclusion
[На каком тесте упало? Или все прошли?]
```

---

## 🚀 ПОСЛЕ СБОРА ОТЧЁТА

**Отправить отчёт с тегами:**
- `#torapp-diagnostics`
- `#exc-bad-access`
- `#torframeworkbuilder-v1.0.26`

**Я смогу:**
1. Точно определить причину проблемы
2. Предоставить конкретное решение
3. Исправить баг если он в TorFrameworkBuilder
4. Дать рекомендации если проблема в TorApp

---

## 💡 БЫСТРАЯ ДИАГНОСТИКА

**Если нет времени на полный отчёт, минимум:**

```swift
// В TorAppApp.swift - добавить в init():
let wrapper = TorWrapper.shared
print("✅ TorWrapper.shared: \(wrapper)")

wrapper.setStatusCallback(nil)
print("✅ setStatusCallback(nil) OK")

wrapper.setStatusCallback { status, message in
    print("✅ Callback set!")
}
print("✅ setStatusCallback with block OK")

print("🎉 Framework works!")
```

**Если краш - скажите на какой строке!**

---

**TorFrameworkBuilder v1.0.26 - Comprehensive Diagnostics!** 🔍🧅

