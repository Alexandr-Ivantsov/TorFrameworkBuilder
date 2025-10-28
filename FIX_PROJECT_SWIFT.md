# 🔧 Исправление Project.swift для TorApp

## ❌ ПРОБЛЕМА НАЙДЕНА

В вашем `Project.swift` отсутствует `-framework Tor` в `OTHER_LDFLAGS`!

**Текущее состояние:**
```swift
"OTHER_LDFLAGS": ["-lz", "-Wl,-ObjC"],
```

**Должно быть:**
```swift
"OTHER_LDFLAGS": ["-framework", "Tor", "-lz", "-Wl,-ObjC"],
```

---

## ✅ ИСПРАВЛЕНИЕ

### Замените в `Project.swift`:

```swift
.target(
    name: "TorApp",
    // ...
    settings: .settings(
        base: [
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "7AFA87CCA7",
            "OTHER_LDFLAGS": ["-framework", "Tor", "-lz", "-Wl,-ObjC"],  // ← ДОБАВИТЬ "-framework", "Tor"
            "LD_RUNPATH_SEARCH_PATHS": ["@executable_path/Frameworks", "@loader_path/Frameworks"],
            "CODE_SIGN_IDENTITY": "iPhone Developer",
            "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
            "TARGETED_DEVICE_FAMILY": "1",
            "SWIFT_OBJC_BRIDGING_HEADER": "Sources/TorApp-Bridging-Header.h"
        ]
    )
),
.target(
    name: "TorAppTests",
    // ...
    settings: .settings(
        base: [
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "7AFA87CCA7",
            "OTHER_LDFLAGS": ["-framework", "Tor", "-lz", "-Wl,-ObjC"],  // ← И здесь тоже
            "CODE_SIGN_IDENTITY": "iPhone Developer",
            "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
            "TARGETED_DEVICE_FAMILY": "1"
        ]
    )
)
```

---

## 🔍 ТАКЖЕ ПРОВЕРЬТЕ BRIDGING HEADER

**У вас есть:**
```swift
"SWIFT_OBJC_BRIDGING_HEADER": "Sources/TorApp-Bridging-Header.h"
```

**Проверьте содержимое `Sources/TorApp-Bridging-Header.h`:**

```objc
// TorApp-Bridging-Header.h

// ✅ ДОЛЖНО БЫТЬ ТАК:
#import <Tor/TorWrapper.h>

// ИЛИ:
@import Tor;
```

**Если файл пустой или импорт неправильный - это тоже может быть причиной краша!**

---

## 🚀 ПОСЛЕ ИСПРАВЛЕНИЯ

```bash
cd ~/admin/TorApp

# 1. Обновить Dependencies.swift на v1.0.28
tuist clean
rm -rf .build

# 2. Установить
tuist install --update
tuist generate

# 3. Запустить
tuist build
```

---

## 📊 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

```
📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
[TorWrapper] 🔵 setStatusCallback called
[TorWrapper] 🔵 self = 0x...
[TorWrapper] 🔵 callbackQueue = 0x...
[TorWrapper] 🔵 About to call dispatch_async...
[TorWrapper] 🔵 dispatch_async returned
[TorWrapper] 🔵 Inside dispatch_async block
[TorWrapper] ✅ Status callback set successfully
✅ setStatusCallback(nil) succeeded
```

---

## ❓ ЕСЛИ ВСЁ ЕЩЁ КРАШ

Отправьте:
1. Содержимое `Sources/TorApp-Bridging-Header.h`
2. Полный вывод Console с логами 🔵
3. На каком именно логе происходит краш

---

**С `-framework Tor` должно заработать!** 🎯










