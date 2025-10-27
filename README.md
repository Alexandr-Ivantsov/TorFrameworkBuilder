# 🧅 TorFrameworkBuilder для iOS

Полнофункциональный Tor daemon для iOS приложений (arm64, iOS 16.0+)

**Размер**: 42 MB (28 MB device + 14 MB simulator) | **Версия Tor**: 0.4.8.19 | **Включено**: OpenSSL 3.4.0, libevent 2.1.12, xz 5.6.3

**✅ Поддерживается iOS Simulator!** (arm64 для Apple Silicon)

---

## 🚀 Установка через Tuist

### Вариант A: Через Tuist/Dependencies.swift (рекомендуется)

#### 1. В TorApp создайте `Tuist/Dependencies.swift`:

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies([
        .remote(
            url: "https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git",
            requirement: .upToNextMajor(from: "1.0.3")
        )
    ])
)
```

#### 2. В `Project.swift`:

```swift
dependencies: [
    .external(name: "TorFrameworkBuilder")
]
```

#### 3. Установите:

```bash
cd ~/admin/TorApp
tuist fetch
tuist generate
```

### Вариант B: Через Package.swift (если уже используете)

Если вы добавили в `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOU/TorFrameworkBuilder.git", from: "1.0.3")
],
targets: [
    .target(dependencies: ["TorFrameworkBuilder"])
]
```

**Также создайте** `Tuist/Dependencies.swift` (см. Вариант A), иначе будет ошибка:
```
`TorFrameworkBuilder` is not a valid configured external dependency
```

Это известная особенность Tuist - внешние зависимости нужно декларировать в `Dependencies.swift`.

---

## 🧪 iOS Simulator Support

**Теперь полностью поддерживается iOS Simulator!** 🎉

### XCFramework содержит обе платформы:

```
Tor.xcframework/
├── ios-arm64/              ← Реальные устройства (28 MB)
│   └── Tor.framework/
└── ios-arm64-simulator/    ← iOS Simulator (14 MB)
    └── Tor.framework/
```

### Сборка для симулятора

Если вы клонировали репозиторий и хотите пересобрать с поддержкой симулятора:

```bash
# 1. Собрать зависимости для симулятора (~30 минут)
bash scripts/build_all_simulator.sh

# 2. Собрать Tor для симулятора (~5 минут)
bash scripts/build_tor_simulator.sh

# 3. Создать универсальный XCFramework (~1 минута)
bash scripts/create_xcframework_universal.sh
```

**Итого**: ~40 минут

Подробнее: [BUILD_SIMULATOR.md](BUILD_SIMULATOR.md)

### ⚠️ App Store

- При архивировании для App Store Xcode **автоматически исключает** симулятор
- Финальный IPA содержит **только** ios-arm64 (28 MB)
- **Размер без изменений!** Simulator не влияет на размер публикуемого приложения

---

## 💻 Использование

### Objective-C API

```objc
#import <TorFramework/TorWrapper.h>

// Запуск Tor
[[TorWrapper shared] startWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ Tor запущен!");
        NSLog(@"SOCKS: %@", [[TorWrapper shared] socksProxyURL]);
    }
}];

// URLSession через Tor
NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
config.connectionProxyDictionary = @{
    (__bridge NSString *)kCFNetworkProxiesSOCKSEnable: @1,
    (__bridge NSString *)kCFNetworkProxiesSOCKSProxy: @"127.0.0.1",
    (__bridge NSString *)kCFNetworkProxiesSOCKSPort: @9050
};
NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

// Новая идентичность
[[TorWrapper shared] newIdentityWithCompletion:^(BOOL success, NSError *error) {
    NSLog(@"Новый IP получен!");
}];

// Остановка
[[TorWrapper shared] stopWithCompletion:^{
    NSLog(@"Tor остановлен");
}];
```

### Swift (через bridging header)

```swift
// Убедитесь что у вас есть Bridging Header с:
// #import <Tor/TorWrapper.h>

// Запуск
TorWrapper.shared().start { success, error in
    if success {
        print("✅ Tor запущен!")
        print("SOCKS: \(TorWrapper.shared().socksProxyURL())")
    }
}

// URLSession через Tor
let config = URLSessionConfiguration.default
config.connectionProxyDictionary = [
    kCFNetworkProxiesSOCKSEnable: 1,
    kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
    kCFNetworkProxiesSOCKSPort: 9050
]
let session = URLSession(configuration: config)
```

---

## 🌉 Bridges (опционально)

**Мосты НЕ обязательны!** Tor работает без них в большинстве стран.

### Когда нужны bridges:

- Tor заблокирован в вашей стране (Китай, Иран)
- ISP блокирует Tor
- Корпоративная сеть

### Статические bridges (работают сразу)

```objc
// Добавить в TorWrapper.m метод configureBridges:

- (void)configureBridges:(NSArray<NSString *> *)bridges {
    NSMutableString *torrc = [NSMutableString stringWithFormat:
        @"SocksPort %ld\n"
        @"ControlPort %ld\n"
        @"DataDirectory %@\n"
        @"UseBridges 1\n",
        (long)self.socksPort, (long)self.controlPort, self.dataDirectory
    ];
    
    for (NSString *bridge in bridges) {
        [torrc appendFormat:@"Bridge %@\n", bridge];
    }
    
    [torrc writeToFile:self.torrcPath atomically:YES 
              encoding:NSUTF8StringEncoding error:nil];
    
    [self restartWithCompletion:nil];
}

// Использование:
NSArray *bridges = @[@"85.31.186.98:443", @"209.148.46.65:443"];
[[TorWrapper shared] configureBridges:bridges];
```

### Получение bridges от Tor Project

#### Вариант 1: MessageUI (без backend)

```swift
import MessageUI

// Отправка запроса
func requestBridges() {
    let composer = MFMailComposeViewController()
    composer.setToRecipients(["bridges@torproject.org"])
    composer.setSubject("Tor Bridges Request")
    composer.setMessageBody("get vanilla", isHTML: false)
    present(composer, animated: true)
}

// После получения ответа - пользователь копирует bridges вручную
// Парсинг:
func parseBridges(from text: String) -> [String] {
    let pattern = #"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    return matches.compactMap { match in
        guard let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
```

#### Вариант 2: Gmail API (полная автоматизация)

**Требует**: Google Cloud Console + OAuth

1. Регистрация в Google Cloud Console
2. Включить Gmail API
3. Добавить зависимости:

```swift
// Package или Tuist Dependencies:
.package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
.package(url: "https://github.com/google/google-api-objectivec-client-for-rest", from: "3.0.0")
```

4. Код для автоматического получения:

```swift
import GoogleSignIn
import GoogleAPIClientForREST_Gmail

class GmailBridgeService {
    private let gmailService = GTLRGmailService()
    
    // Авторизация
    func authorize() async throws {
        let config = GIDConfiguration(clientID: "YOUR_CLIENT_ID")
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        gmailService.authorizer = result.user.fetcherAuthorizer
    }
    
    // Автоматическое получение bridges
    func requestAndFetchBridges() async throws -> [String] {
        // 1. Отправить письмо
        try await sendEmail()
        
        // 2. Polling каждые 30 сек (макс 10 минут)
        for _ in 0..<20 {
            try await Task.sleep(nanoseconds: 30_000_000_000)
            let bridges = try await checkInbox()
            if !bridges.isEmpty { return bridges }
        }
        throw BridgeError.timeout
    }
    
    // Полный код см. в документации Gmail API
}
```

---

## 🔧 Настройка в TorApp

### Info.plist

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Tor использует локальную сеть для SOCKS proxy</string>
```

### Bridging Header (для Swift)

Создайте `TorApp-Bridging-Header.h`:

```objc
#import <TorFramework/TorWrapper.h>
#import <TorFramework/Tor.h>
```

---

## ✅ Проверка работы

```swift
// Тест подключения
TorWrapper.shared().start { success, _ in
    if success {
        // Проверка IP через Tor
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = [
            kCFNetworkProxiesSOCKSEnable: 1,
            kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
            kCFNetworkProxiesSOCKSPort: 9050
        ]
        let session = URLSession(configuration: config)
        
        let url = URL(string: "https://check.torproject.org/api/ip")!
        session.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Результат: \(json)")
                // {"IsTor": true} = ✅ Работает!
            }
        }.resume()
    }
}
```

---

## 📦 Что включено

- **Tor 0.4.8.19** (123 core модуля)
- **OpenSSL 3.4.0** (криптография)
- **libevent 2.1.12** (event loop)
- **xz/lzma 5.6.3** (сжатие)

**Итого (device)**: 28 MB, всё статически слинковано  
**Итого (simulator)**: 14 MB

---

## 📝 Обновление версии Tor

```bash
# Скачать новую версию
wget https://dist.torproject.org/tor-0.5.x.x.tar.gz
tar -xzf tor-0.5.x.x.tar.gz

# Применить исправления
bash fix_conflicts.sh

# Обновить direct_build.sh (изменить TOR_SRC)
# Пересобрать для устройства
rm -rf build/tor-direct output/tor-direct
bash direct_build.sh > build.log 2>&1 &

# Пересобрать для симулятора
bash scripts/build_tor_simulator.sh

# Создать универсальный XCFramework
bash scripts/create_xcframework_universal.sh

# Коммит
git add output/Tor.xcframework
git commit -m "Update Tor to 0.5.x.x"
git tag 1.0.4
git push --tags
git push
```

---

## 🛡️ Требования

- **iOS**: 16.0+
- **Xcode**: 14.0+
- **Tuist**: 3.0+
- **Архитектуры**: arm64 (device), arm64 (simulator)

---

## 📚 Документация

- [USAGE_GUIDE.md](USAGE_GUIDE.md) - Подробный гайд по интеграции в TorApp
- [BUILD_SIMULATOR.md](BUILD_SIMULATOR.md) - Инструкция по сборке для симулятора
- [RELEASE_NOTES.md](RELEASE_NOTES.md) - Release notes v1.0.3

---

## 📄 Лицензия

BSD License (совместимо с Tor Project)

- **Tor**: BSD-3-Clause
- **OpenSSL**: Apache 2.0
- **libevent**: BSD-3-Clause
- **xz**: Public Domain
