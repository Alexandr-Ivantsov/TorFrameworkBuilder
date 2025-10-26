# ⚡ Шпаргалка - Быстрый старт

## 🚀 Для Git (прямо сейчас):

```bash
cd ~/admin/TorFrameworkBuilder

# Коммит
git add .
git commit -m "🎉 Tor Framework для iOS готов"

# Создать репозиторий на GitHub (private!)
# https://github.com/new

# Push
git remote add origin https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git
git push -u origin main
```

---

## 📱 Для TorApp (после push):

### 1. Создать `Tuist/Dependencies.swift`:

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(
            url: "https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git",
            requirement: .branch("main")
        )
    ]
)
```

### 2. В `Project.swift` добавить:

```swift
dependencies: [
    .external(name: "Tor")
]
```

### 3. Установить:

```bash
tuist fetch
tuist generate
```

---

## 💻 Использование в коде:

```swift
import Tor

// Запуск
TorService.shared.start { result in
    if case .success = result {
        print("✅ Tor работает!")
    }
}

// Запросы через Tor
let session = TorService.shared.createURLSession()
session.dataTask(with: url) { data, _, _ in
    // Запрос через Tor!
}.resume()

// Новая идентичность
TorService.shared.newIdentity { _ in
    print("Новый IP!")
}
```

---

## 🌉 Bridges (позже):

### Вариант 1: Статические (быстро)
```swift
let bridges = ["85.31.186.98:443", "209.148.46.65:443"]
TorService.shared.configureBridges(bridges) { _ in }
```

### Вариант 2: CloudFlare Worker (авто)
См. BRIDGES_IMPLEMENTATION.md → Решение 1

---

## 📖 Полная документация:

- `FINAL_ANSWERS.md` - ответы на все вопросы
- `INTEGRATION_GUIDE.md` - пошаговая интеграция
- `BRIDGES_IMPLEMENTATION.md` - 4 решения для bridges

---

## ✅ Готово!

Закоммитьте → Push → Используйте в TorApp!

