# 🧅 Tor Framework для iOS

> Полнофункциональный Tor daemon для iOS приложений, собранный для arm64

[![Platform](https://img.shields.io/badge/platform-iOS%2016.0+-blue.svg)](https://developer.apple.com/ios/)
[![Architecture](https://img.shields.io/badge/architecture-arm64-green.svg)](https://developer.apple.com/)
[![Swift](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-BSD-lightgrey.svg)](LICENSE)

## ✨ Особенности

- ✅ **Tor 0.4.8.19** - стабильная версия
- ✅ **Статическая линковка** - все зависимости включены
- ✅ **Swift Package Manager** - готов для Tuist
- ✅ **Удобный API** - Swift и Objective-C wrappers
- ✅ **iOS 16.0+** - современные устройства
- ✅ **arm64** - оптимизировано для iPhone

## 📦 Что включено

- **Tor daemon** (123 core модуля)
- **OpenSSL 3.4.0** (криптография)
- **libevent 2.1.12** (event loop)
- **xz/lzma 5.6.3** (сжатие)
- **Swift wrapper** (TorService) - удобный API
- **Objective-C wrapper** (TorWrapper) - основа

**Общий размер**: 28 MB (все зависимости включены)

## 🚀 Быстрый старт

### Установка через Tuist

#### 1. Добавьте в `Tuist/Dependencies.swift`:

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

#### 2. В `Project.swift`:

```swift
dependencies: [
    .external(name: "Tor")
]
```

#### 3. Установите:

```bash
tuist fetch
tuist generate
```

### Использование

```swift
import Tor

// Запуск Tor
TorService.shared.start { result in
    switch result {
    case .success:
        print("✅ Tor запущен!")
        print("SOCKS: \(TorService.shared.socksProxyURL)")
        
    case .failure(let error):
        print("❌ Ошибка: \(error)")
    }
}

// Создание URLSession через Tor
let torSession = TorService.shared.createURLSession()

// Ваши запросы теперь через Tor!
torSession.dataTask(with: url) { data, response, error in
    // Анонимный запрос
}.resume()

// Новая идентичность
TorService.shared.newIdentity { _ in
    print("Получен новый IP!")
}

// Остановка
TorService.shared.stop()
```

## 📚 Полная документация

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Шпаргалка
- **[INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)** - Интеграция с Tuist
- **[BRIDGES_IMPLEMENTATION.md](BRIDGES_IMPLEMENTATION.md)** - 4 решения для bridges
- **[FINAL_ANSWERS.md](FINAL_ANSWERS.md)** - FAQ
- **[SUCCESS.md](SUCCESS.md)** - Как это было сделано

## 🌉 Bridges поддержка

Vanilla bridges поддерживаются:

```swift
let bridges = [
    "85.31.186.98:443",
    "209.148.46.65:443"
]

TorService.shared.configureBridges(bridges) { result in
    // Bridges настроены
}
```

См. **[BRIDGES_IMPLEMENTATION.md](BRIDGES_IMPLEMENTATION.md)** для автоматического получения bridges.

## 🔧 Требования

- iOS 16.0+
- Xcode 14.0+
- Swift 5.9+
- Tuist 3.0+

## 📊 Технические детали

### Компоненты:

- **Tor**: 0.4.8.19 (123 модуля скомпилированы)
- **OpenSSL**: 3.4.0 (18MB + 4MB)
- **libevent**: 2.1.12-stable (2.7MB)
- **xz/lzma**: 5.6.3 (1MB)

### Возможности:

- ✅ SOCKS5 proxy
- ✅ .onion сайты
- ✅ Circuit building
- ✅ Смена идентичности
- ✅ Control protocol
- ✅ Vanilla bridges
- ⚠️ obfs4 bridges (требует дополнительную компиляцию)

### Архитектура:

```
TorService (Swift)
    ↓
TorWrapper (Objective-C)
    ↓
libtor.a (C)
    ↓
OpenSSL + libevent + xz
```

## 🔄 Обновление версии Tor

См. **[FINAL_ANSWERS.md](FINAL_ANSWERS.md)** → Вопрос 1

```bash
# Скачать новую версию
wget https://dist.torproject.org/tor-0.5.x.x.tar.gz

# Применить исправления
bash fix_conflicts.sh

# Пересобрать
bash direct_build.sh
bash create_framework_final.sh

# Коммит
git add .
git commit -m "Update Tor to 0.5.x.x"
git push
```

## 🛡️ Безопасность

- Все зависимости статически слинкованы (контролируемые версии)
- OpenSSL 3.4.0 (последняя стабильная)
- Криптография через проверенную OpenSSL
- SOCKS5 proxy локально (127.0.0.1)

## 🤝 Вклад

Pull requests приветствуются!

## 📄 Лицензия

BSD License (совместимо с Tor Project)

## 🙏 Благодарности

- [Tor Project](https://www.torproject.org/) - за Tor
- [OpenSSL](https://www.openssl.org/) - за криптографию
- [libevent](https://libevent.org/) - за event loop

---

**Создано вручную без Docker, configure и Rust** 💪

**Готово к использованию через Tuist!** 🎉
