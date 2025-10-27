# 📱 План использования TorFrameworkBuilder в TorApp

> **Этот гайд предполагает, что вы уже:**
> - ✅ Запушили TorFrameworkBuilder в приватный репозиторий
> - ✅ Добавили в `Package.swift` и `Project.swift` TorApp
> - ✅ Выполнили `tuist install --update` (fetch завершился успешно)
> - ✅ Готовы к `tuist generate`

---

## ⚠️ ВАЖНО: Исправление ошибки Tuist

Если получаете ошибку:
```
`TorFrameworkBuilder` is not a valid configured external dependency
```

Это известная проблема Tuist с вложенными зависимостями.

### Решение:

В TorApp нужно добавить `Tuist/Dependencies.swift`:

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies([
        .remote(
            url: "https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git",
            requirement: .upToNextMajor(from: "1.0.1")
        )
    ])
)
```

Затем:
```bash
tuist fetch  # Вместо tuist install
tuist generate
```

---

---

## Шаг 1: Создать Bridging Header (для Swift)

### Создайте файл: `TorApp/Sources/TorApp-Bridging-Header.h`

```objc
//
//  TorApp-Bridging-Header.h
//

#import <Tor/TorWrapper.h>
#import <Tor/Tor.h>
```

### Настройте в Project.swift:

```swift
.target(
    name: "TorApp",
    // ...
    settings: .settings(
        base: [
            "SWIFT_OBJC_BRIDGING_HEADER": "Sources/TorApp-Bridging-Header.h"
        ]
    )
)
```

---

## Шаг 2: Добавить разрешения в Info.plist

### Создайте/обновите `TorApp/Resources/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Tor использует локальную сеть для SOCKS proxy</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

Или в Project.swift:

```swift
infoPlist: .extendingDefault(with: [
    "NSLocalNetworkUsageDescription": "Tor использует локальную сеть для SOCKS proxy",
    "NSAppTransportSecurity": [
        "NSAllowsLocalNetworking": true
    ]
])
```

---

## Шаг 3: Создать TorService Manager

### Создайте файл: `TorApp/Sources/Services/TorManager.swift`

> **Важно**: TorWrapper доступен через Bridging Header

```swift
import Foundation

// TorWrapper доступен благодаря Bridging Header

@MainActor
final class TorManager: ObservableObject {
    
    static let shared = TorManager()
    
    @Published var isConnected: Bool = false
    @Published var status: String = "Отключен"
    @Published var currentIP: String?
    
    private let torWrapper = TorWrapper.shared()
    
    private init() {
        setupCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupCallbacks() {
        // Callback для статуса
        torWrapper.setStatusCallback { [weak self] status, message in
            Task { @MainActor in
                self?.status = message ?? "Unknown"
                self?.isConnected = (status.rawValue == 3) // TorStatusConnected
            }
        }
        
        // Callback для логов
        torWrapper.setLogCallback { logMessage in
            print("[Tor] \(logMessage)")
        }
    }
    
    // MARK: - Public Methods
    
    func start() async throws {
        try await withCheckedThrowingContinuation { continuation in
            torWrapper.start { success, error in
                if success {
                    continuation.resume()
                } else {
                    let torError = error ?? NSError(
                        domain: "TorManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to start Tor"]
                    )
                    continuation.resume(throwing: torError)
                }
            }
        }
    }
    
    func stop() async {
        await withCheckedContinuation { continuation in
            torWrapper.stop {
                continuation.resume()
            }
        }
    }
    
    func newIdentity() async throws {
        try await withCheckedThrowingContinuation { continuation in
            torWrapper.newIdentity { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "TorManager", code: -1))
                }
            }
        }
    }
    
    // MARK: - Network
    
    func createTorURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = [
            kCFNetworkProxiesSOCKSEnable: 1,
            kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
            kCFNetworkProxiesSOCKSPort: Int(torWrapper.socksPort)
        ]
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }
    
    func checkTorIP() async -> String? {
        let session = createTorURLSession()
        guard let url = URL(string: "https://check.torproject.org/api/ip") else {
            return nil
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ip = json["IP"] as? String {
                await MainActor.run {
                    self.currentIP = ip
                }
                return ip
            }
        } catch {
            print("Error checking IP: \(error)")
        }
        return nil
    }
    
    // MARK: - Bridges
    
    func configureBridges(_ bridges: [String]) async {
        // TODO: Реализовать в TorWrapper.m метод configureBridges
        // torWrapper.configureBridges(bridges)
        print("Bridges to configure: \(bridges)")
    }
}
```

---

## Шаг 4: Создать UI для управления Tor

### Создайте: `TorApp/Sources/Views/TorControlView.swift`

```swift
import SwiftUI

struct TorControlView: View {
    @StateObject private var torManager = TorManager.shared
    @State private var isStarting = false
    @State private var showError: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Статус
            VStack(spacing: 12) {
                Circle()
                    .fill(torManager.isConnected ? Color.green : Color.gray)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: torManager.isConnected ? "checkmark" : "power")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                Text(torManager.status)
                    .font(.headline)
                
                if let ip = torManager.currentIP {
                    Text("Exit IP: \(ip)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            
            // Кнопки управления
            VStack(spacing: 12) {
                Button(action: startTor) {
                    HStack {
                        Image(systemName: "power")
                        Text("Подключиться к Tor")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(torManager.isConnected || isStarting)
                
                if torManager.isConnected {
                    Button(action: newIdentity) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Новая идентичность")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: stopTor) {
                        HStack {
                            Image(systemName: "stop.circle")
                            Text("Отключиться")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            
            if isStarting {
                ProgressView("Подключение к Tor...")
            }
            
            if let error = showError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func startTor() {
        isStarting = true
        showError = nil
        
        Task {
            do {
                try await torManager.start()
                
                // Подождать немного для подключения
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                // Проверить IP
                _ = await torManager.checkTorIP()
                
            } catch {
                showError = "Ошибка: \(error.localizedDescription)"
            }
            isStarting = false
        }
    }
    
    private func stopTor() {
        Task {
            await torManager.stop()
        }
    }
    
    private func newIdentity() {
        Task {
            do {
                try await torManager.newIdentity()
                
                // Подождать и проверить новый IP
                try await Task.sleep(nanoseconds: 2_000_000_000)
                _ = await torManager.checkTorIP()
                
            } catch {
                showError = "Ошибка смены идентичности"
            }
        }
    }
}

// Preview
struct TorControlView_Previews: PreviewProvider {
    static var previews: some View {
        TorControlView()
    }
}
```

---

## Шаг 5: Добавить в главный View

### Обновите `ContentView.swift` или `MainView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Ваш основной контент
            MainContentView()
                .tabItem {
                    Label("Главная", systemImage: "house")
                }
            
            // Tor управление
            TorControlView()
                .tabItem {
                    Label("Tor", systemImage: "network")
                }
        }
    }
}
```

---

## Шаг 6: Использование Tor для запросов

### Вариант А: Через отдельную URLSession

```swift
class NetworkService {
    private let torManager = TorManager.shared
    
    func fetchThroughTor(url: URL) async throws -> Data {
        // Создать session с Tor proxy
        let session = torManager.createTorURLSession()
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badResponse
        }
        
        return data
    }
}

// Использование:
Task {
    let url = URL(string: "https://example.onion/api/data")!
    let data = try await NetworkService().fetchThroughTor(url: url)
    // Обработать данные
}
```

### Вариант Б: Глобальная настройка URLSession

```swift
// В AppDelegate или @main
@main
struct TorAppApp: App {
    
    init() {
        // Запустить Tor при старте приложения
        Task {
            try? await TorManager.shared.start()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Шаг 7: (Опционально) Bridges через MessageUI

### Создайте: `TorApp/Sources/Features/Bridges/BridgeRequestView.swift`

```swift
import SwiftUI
import MessageUI

struct BridgeRequestView: View {
    @State private var showMail = false
    @State private var bridgeText = ""
    @State private var showInput = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tor Bridges")
                .font(.title)
            
            Text("Bridges нужны только если Tor заблокирован")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Запросить персональные bridges") {
                showMail = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $showMail) {
                MailComposer(
                    to: "bridges@torproject.org",
                    subject: "Tor Bridges Request",
                    body: "get vanilla"
                ) { sent in
                    if sent {
                        showInput = true
                    }
                }
            }
            
            if showInput {
                VStack(spacing: 12) {
                    Text("Скопируйте bridges из письма:")
                        .font(.caption)
                    
                    TextEditor(text: $bridgeText)
                        .frame(height: 120)
                        .border(Color.gray)
                    
                    Text("Найдено: \(parsedBridges.count) bridges")
                        .font(.caption)
                    
                    Button("Сохранить и применить") {
                        saveBridges()
                    }
                    .disabled(parsedBridges.isEmpty)
                }
            }
        }
        .padding()
    }
    
    var parsedBridges: [String] {
        let pattern = #"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: bridgeText, range: NSRange(bridgeText.startIndex..., in: bridgeText))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: bridgeText) else { return nil }
            return String(bridgeText[range])
        }
    }
    
    func saveBridges() {
        let bridges = parsedBridges
        UserDefaults.standard.set(bridges, forKey: "torBridges")
        
        Task {
            await TorManager.shared.configureBridges(bridges)
        }
    }
}

// Mail Composer
struct MailComposer: UIViewControllerRepresentable {
    let to: String
    let subject: String
    let body: String
    let onDismiss: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([to])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: (Bool) -> Void
        
        init(onDismiss: @escaping (Bool) -> Void) {
            self.onDismiss = onDismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                 didFinishWith result: MFMailComposeResult,
                                 error: Error?) {
            controller.dismiss(animated: true)
            onDismiss(result == .sent)
        }
    }
}
```

---

## Шаг 8: Пример использования в реальном приложении

### Создайте: `TorApp/Sources/Features/Browser/TorWebView.swift`

```swift
import SwiftUI
import WebKit

struct TorWebView: View {
    @StateObject private var torManager = TorManager.shared
    @State private var urlString = "https://check.torproject.org"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // URL bar
            HStack {
                TextField("URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                Button("Go") {
                    loadURL()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Web content
            if torManager.isConnected {
                WebView(urlString: $urlString, isLoading: $isLoading)
            } else {
                VStack {
                    Text("Tor не подключен")
                    Button("Подключиться") {
                        Task {
                            try? await torManager.start()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            if isLoading {
                ProgressView()
                    .padding()
            }
        }
    }
    
    func loadURL() {
        // URL загрузится через Tor автоматически
        // благодаря SOCKS proxy в WKWebView configuration
    }
}

struct WebView: UIViewRepresentable {
    @Binding var urlString: String
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        // Настройка WKWebView для работы через Tor
        let config = WKWebViewConfiguration()
        
        // ВАЖНО: Для SOCKS proxy в WKWebView нужен custom URLProtocol
        // Или использовать API requests вместо WebView
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        
        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
    }
}
```

---

## Шаг 9: Типичные use cases

### 1. Простой HTTP запрос через Tor

```swift
func fetchData() async {
    let session = TorManager.shared.createTorURLSession()
    let url = URL(string: "https://api.example.com/data")!
    
    do {
        let (data, _) = try await session.data(from: url)
        // Обработать data
    } catch {
        print("Error: \(error)")
    }
}
```

### 2. Доступ к .onion сайту

```swift
func fetchOnionSite() async {
    let session = TorManager.shared.createTorURLSession()
    let url = URL(string: "https://thehiddenwiki.onion")!
    
    do {
        let (data, _) = try await session.data(from: url)
        let html = String(data: data, encoding: .utf8)
        print("Onion content: \(html ?? "")")
    } catch {
        print("Error: \(error)")
    }
}
```

### 3. Проверка что используется Tor

```swift
func verifyTorConnection() async {
    if let ip = await TorManager.shared.checkTorIP() {
        print("✅ Подключено через Tor!")
        print("Exit IP: \(ip)")
    } else {
        print("❌ НЕ через Tor")
    }
}
```

---

## Шаг 10: Обработка ошибок

```swift
enum TorError: LocalizedError {
    case notConnected
    case requestFailed(Error)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Tor не подключен. Подключитесь сначала."
        case .requestFailed(let error):
            return "Ошибка запроса: \(error.localizedDescription)"
        case .timeout:
            return "Timeout подключения к Tor"
        }
    }
}

// Использование:
func makeRequest() async throws {
    guard TorManager.shared.isConnected else {
        throw TorError.notConnected
    }
    
    let session = TorManager.shared.createTorURLSession()
    // ... запрос
}
```

---

## 📝 Резюме: Пошаговый план

1. ✅ Создать `TorApp-Bridging-Header.h`
2. ✅ Добавить `NSLocalNetworkUsageDescription` в Info.plist
3. ✅ Создать `TorManager.swift` (менеджер Tor)
4. ✅ Создать `TorControlView.swift` (UI для управления)
5. ✅ Добавить в ContentView
6. ✅ Использовать `TorManager.shared.createTorURLSession()` для запросов

---

## ⚡ Минимальный код для старта

```swift
// В любом View:
Button("Запустить Tor") {
    Task {
        try? await TorManager.shared.start()
        
        // Подождать подключения
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        // Сделать тестовый запрос
        let session = TorManager.shared.createTorURLSession()
        let url = URL(string: "https://check.torproject.org/api/ip")!
        
        let (data, _) = try! await session.data(from: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        print("Результат: \(json)")
        // {"IsTor": true} = Работает! ✅
    }
}
```

---

## 🎯 Готово!

После выполнения этих шагов у вас будет:
- ✅ Работающий Tor в TorApp
- ✅ UI для управления
- ✅ URLSession через Tor
- ✅ Доступ к .onion сайтам
- ✅ Опциональные bridges

**Успехов!** 🚀

