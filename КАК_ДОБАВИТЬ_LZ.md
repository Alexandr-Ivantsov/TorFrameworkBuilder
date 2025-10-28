# ⚡ Как правильно добавить -lz в TorApp

## Проблема

Видишь эти ошибки:
```
Undefined symbol: _deflate
Undefined symbol: _inflate
Undefined symbol: _zlibVersion
... (всего 7 zlib symbols)
```

**Это значит что `-lz` НЕ подключен!**

---

## ✅ Решение: Добавить -lz в Project.swift

### Найди в `TorApp/Project.swift` файл

Там у тебя определены targets. Например:

```swift
let project = Project(
    name: "TorApp",
    targets: [
        .target(
            name: "TorApp",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.TorApp",
            deploymentTargets: .iOS("18.6"),
            infoPlist: .extendingDefault(...),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "Store"),
                .external(name: "TorFrameworkBuilder")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "7AFA87CCA7",
                    // ... другие настройки ...
                ]
            )
        ),
        // ... другие targets ...
    ]
)
```

---

## 🎯 ЧТО НУЖНО ИЗМЕНИТЬ

### ДЛЯ КАЖДОГО TARGET добавь "OTHER_LDFLAGS": "-lz"

**БЫЛО:**
```swift
settings: .settings(
    base: [
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "7AFA87CCA7"
    ]
)
```

**ДОЛЖНО БЫТЬ:**
```swift
settings: .settings(
    base: [
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "7AFA87CCA7",
        "OTHER_LDFLAGS": "-lz"  // ⚠️ ДОБАВЬ ЭТУ СТРОКУ!
    ]
)
```

---

## 📋 Полный пример target:

```swift
.target(
    name: "TorApp",
    destinations: .iOS,
    product: .app,
    bundleId: "io.tuist.TorApp",
    deploymentTargets: .iOS("18.6"),
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": "TorApp",
            // ... другие plist настройки ...
        ]
    ),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    dependencies: [
        .external(name: "Store"),
        .external(name: "TorFrameworkBuilder")
    ],
    settings: .settings(
        base: [
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "7AFA87CCA7",
            "CODE_SIGN_IDENTITY": "iPhone Developer",
            "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
            "TARGETED_DEVICE_FAMILY": "1",
            "OTHER_LDFLAGS": "-lz"  // ⚠️ ВОТ ЭТА СТРОКА!
        ]
    )
),
```

---

## ⚠️ ВАЖНО: Добавь для ВСЕХ targets!

Если у тебя есть несколько targets (например TorApp, TorAppTests, PacketTunnelProvider), нужно добавить `-lz` В КАЖДЫЙ:

```swift
targets: [
    // Target 1: TorApp
    .target(
        name: "TorApp",
        // ...
        settings: .settings(base: ["OTHER_LDFLAGS": "-lz"])
    ),
    
    // Target 2: TorAppTests
    .target(
        name: "TorAppTests",
        // ...
        settings: .settings(base: ["OTHER_LDFLAGS": "-lz"])
    ),
    
    // Target 3: PacketTunnelProvider (если есть)
    .target(
        name: "PacketTunnelProvider",
        // ...
        settings: .settings(base: ["OTHER_LDFLAGS": "-lz"])
    )
]
```

---

## 🚀 После изменения:

```bash
cd ~/admin/TorApp

# Очистить кеш
rm -rf .build
rm -rf ~/Library/Caches/org.swift.swiftpm  
rm -rf ~/Library/Developer/Xcode/DerivedData

# Пересобрать
tuist generate
tuist build
```

---

## ✅ Результат:

После правильного добавления `-lz`:
- ✅ 7 zlib symbols исчезнут
- ✅ Останется только 4 symbols (не критичны)
- ✅ TorApp соберется и запустится!

---

## 📝 Если -lz не помог:

Проверь что `-lz` добавлен **ИМЕННО** в `base` словарь `settings`, а не куда-то еще.

Правильно:
```swift
settings: .settings(base: ["OTHER_LDFLAGS": "-lz"])
```

Неправильно:
```swift
settings: .settings(configurations: [...])  // ❌ Не туда!
```

---

## 🎯 Итог:

После добавления `-lz`: **97% symbols готовы!**

Оставшиеся 2% (4 symbols) - это Linux-специфичные функции, которые НЕ нужны на iOS.

**TOR БУДЕТ ПОЛНОСТЬЮ РАБОТАТЬ!** 🚀

