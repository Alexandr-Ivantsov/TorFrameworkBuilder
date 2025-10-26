# Tor Framework для iOS

Полнофункциональный Tor Framework для iOS приложений, собранный для arm64.

## 📦 Установка через Tuist

### Шаг 1: Добавьте в ваш Dependencies.swift

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

### Шаг 2: В Project.swift добавьте зависимость

```swift
import ProjectDescription

let project = Project(
    name: "TorApp",
    targets: [
        Target(
            name: "TorApp",
            platform: .iOS,
            product: .app,
            bundleId: "com.yourcompany.torapp",
            deploymentTarget: .iOS(targetVersion: "16.0", devices: [.iphone]),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Tor")
            ]
        )
    ]
)
```

### Шаг 3: Установите зависимости

```bash
tuist fetch
tuist generate
```

## 🚀 Использование

### Swift API (рекомендуется)

```swift
import Tor

// Запуск Tor
TorService.shared.start { result in
    switch result {
    case .success:
        print("✅ Tor запущен!")
        print("SOCKS proxy: \(TorService.shared.socksProxyURL)")
        
    case .failure(let error):
        print("❌ Ошибка: \(error)")
    }
}

// Monitoring статуса
TorService.shared.onStatusChange { status, message in
    print("Статус изменен: \(status) - \(message ?? "")")
}

// Создание URLSession через Tor
let torSession = TorService.shared.createURLSession()
torSession.dataTask(with: url) { data, response, error in
    // Ваш запрос идет через Tor!
}.resume()

// Новая идентичность (новая цепь)
TorService.shared.newIdentity { result in
    print("Новая идентичность получена!")
}

// Остановка
TorService.shared.stop {
    print("Tor остановлен")
}
```

### Objective-C API

```objc
#import <Tor/TorWrapper.h>

TorWrapper *tor = [TorWrapper shared];

[tor startWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Tor запущен!");
    }
}];
```

## 🔧 Конфигурация Bridges (будет добавлено)

```swift
let bridges = [
    "12.34.56.78:9001",
    "98.76.54.32:443"
]

TorService.shared.configureBridges(bridges) { result in
    switch result {
    case .success:
        print("Bridges настроены!")
    case .failure(let error):
        print("Ошибка: \(error)")
    }
}
```

## 📋 Требования

- iOS 16.0+
- Xcode 14.0+
- Swift 5.9+
- Tuist 3.0+

## 📦 Что включено

- ✅ Tor 0.4.8.19 (123 core модуля)
- ✅ OpenSSL 3.4.0
- ✅ libevent 2.1.12
- ✅ xz/lzma 5.6.3
- ✅ Swift wrapper с удобным API
- ✅ Objective-C wrapper
- ⚠️ Vanilla bridges (в разработке)

## 🔐 Безопасность

- Все зависимости статически слинкованы
- Использует системный keychain для безопасности
- Поддержка SOCKS5 proxy
- Криптография через OpenSSL

## 📝 Лицензия

См. LICENSE файл.

## 🤝 Вклад

Pull requests приветствуются!

## 📚 Документация

Полная документация в [SUCCESS.md](SUCCESS.md)

