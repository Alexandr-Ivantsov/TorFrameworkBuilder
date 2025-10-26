# 🚀 Руководство по интеграции Tor Framework в TorApp через Tuist

## Шаг 1: Подготовка приватного репозитория

### 1.1 Инициализация Git (если еще не сделано)

```bash
cd ~/admin/TorFrameworkBuilder

# Инициализация
git init

# Добавление всех файлов
git add .

# Первый коммит
git commit -m "Initial commit: Tor Framework для iOS

- Tor 0.4.8.19 собран для iOS arm64
- OpenSSL 3.4.0, libevent 2.1.12, xz 5.6.3
- Swift Package Manager ready
- 123 модуля успешно скомпилированы"
```

### 1.2 Создание приватного репозитория на GitHub

1. Перейдите на https://github.com/new
2. Название: `TorFrameworkBuilder` (или любое другое)
3. **Важно**: Выберите **Private** ✅
4. НЕ добавляйте README, .gitignore, license (уже есть)
5. Создайте репозиторий

### 1.3 Настройка Git LFS (для больших файлов)

```bash
# Установка Git LFS (если еще не установлен)
brew install git-lfs

# Инициализация в репозитории
git lfs install

# LFS уже настроен в .gitattributes для:
# - output/Tor.xcframework/**
# - *.tar.gz

# Проверка
git lfs track
```

### 1.4 Push в приватный репозиторий

```bash
# Добавление remote
git remote add origin https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git

# Push
git branch -M main
git push -u origin main
```

## Шаг 2: Настройка Tuist в TorApp

### 2.1 Создание Dependencies.swift

В корне вашего TorApp проекта создайте `Tuist/Dependencies.swift`:

```swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies([
        .remote(
            url: "https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git",
            requirement: .branch("main")
        )
    ])
)
```

### 2.2 Обновление Project.swift

В `Project.swift` добавьте зависимость:

```swift
import ProjectDescription

let project = Project(
    name: "TorApp",
    organizationName: "YourCompany",
    targets: [
        Target(
            name: "TorApp",
            platform: .iOS,
            product: .app,
            bundleId: "com.yourcompany.torapp",
            deploymentTarget: .iOS(targetVersion: "16.0", devices: [.iphone]),
            infoPlist: .default,
            sources: ["TorApp/Sources/**"],
            resources: ["TorApp/Resources/**"],
            dependencies: [
                // Добавить Tor Framework
                .external(name: "Tor")
            ],
            settings: .settings(
                base: [
                    "ENABLE_BITCODE": "NO"  // Важно для статических библиотек
                ]
            )
        )
    ]
)
```

### 2.3 Установка зависимостей

```bash
cd ~/admin/TorApp

# Fetch зависимостей (скачает ваш framework)
tuist fetch

# Генерация Xcode проекта
tuist generate

# Открыть проект
open TorApp.xcworkspace
```

## Шаг 3: Использование в коде

### 3.1 Создание TorService Manager

`TorApp/Sources/Services/TorManager.swift`:

```swift
import Foundation
import Tor
import Combine

@MainActor
final class TorManager: ObservableObject {
    
    static let shared = TorManager()
    
    @Published var isConnected: Bool = false
    @Published var status: String = "Disconnected"
    @Published var currentIP: String? = nil
    
    private let torService = TorService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupTor()
    }
    
    private func setupTor() {
        // Мониторинг статуса
        torService.onStatusChange { [weak self] status, message in
            Task { @MainActor in
                self?.status = message ?? "Unknown"
                self?.isConnected = (status == .connected)
            }
        }
        
        // Логирование
        torService.onLog { log in
            print("[Tor] \(log)")
        }
    }
    
    func start() async throws {
        try await withCheckedThrowingContinuation { continuation in
            torService.start { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func stop() async {
        await withCheckedContinuation { continuation in
            torService.stop {
                continuation.resume()
            }
        }
    }
    
    func newIdentity() async throws {
        try await withCheckedThrowingContinuation { continuation in
            torService.newIdentity { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func checkIP() async -> String? {
        let session = torService.createURLSession()
        guard let url = URL(string: "https://check.torproject.org/api/ip") else {
            return nil
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["IP"] as? String
        } catch {
            print("Error checking IP: \(error)")
            return nil
        }
    }
}
```

### 3.2 SwiftUI View

`TorApp/Sources/Views/TorControlView.swift`:

```swift
import SwiftUI

struct TorControlView: View {
    @StateObject private var torManager = TorManager.shared
    @State private var isStarting = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Статус
            StatusView(
                isConnected: torManager.isConnected,
                status: torManager.status
            )
            
            // IP адрес
            if let ip = torManager.currentIP {
                Text("Exit IP: \(ip)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Кнопки управления
            HStack(spacing: 16) {
                Button(action: startTor) {
                    Label("Connect", systemImage: "power")
                }
                .disabled(torManager.isConnected || isStarting)
                
                Button(action: stopTor) {
                    Label("Disconnect", systemImage: "power.circle")
                }
                .disabled(!torManager.isConnected)
                
                Button(action: newIdentity) {
                    Label("New Identity", systemImage: "arrow.clockwise")
                }
                .disabled(!torManager.isConnected)
            }
        }
        .padding()
    }
    
    private func startTor() {
        isStarting = true
        Task {
            do {
                try await torManager.start()
                // Проверить IP после подключения
                if let ip = await torManager.checkIP() {
                    await MainActor.run {
                        torManager.currentIP = ip
                    }
                }
            } catch {
                print("Error starting Tor: \(error)")
            }
            isStarting = false
        }
    }
    
    private func stopTor() {
        Task {
            await torManager.stop()
            await MainActor.run {
                torManager.currentIP = nil
            }
        }
    }
    
    private func newIdentity() {
        Task {
            try? await torManager.newIdentity()
            // Обновить IP
            if let ip = await torManager.checkIP() {
                await MainActor.run {
                    torManager.currentIP = ip
                }
            }
        }
    }
}
```

## Шаг 4: Обновление Info.plist

Добавьте разрешения для локальной сети:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Tor needs to access local network for SOCKS proxy</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Шаг 5: Сборка и тестирование

```bash
# Генерация проекта
tuist generate

# Открыть в Xcode
open TorApp.xcworkspace

# Build (Cmd+B)
# Run (Cmd+R)
```

## ⚠️ Важные моменты

1. **Git LFS**: Убедитесь что настроен для XCFramework
2. **Private repo**: Нужен Personal Access Token для Tuist
3. **Bitcode**: Отключите (`ENABLE_BITCODE = NO`)
4. **Минимальная iOS**: 16.0+

## 🔄 Обновление Framework

Когда вы обновите framework:

```bash
# В TorFrameworkBuilder
git add .
git commit -m "Update Tor framework"
git push

# В TorApp
tuist fetch --update
tuist generate
```

## 🎉 Готово!

Теперь ваш TorApp использует приватный Tor Framework через Tuist!

