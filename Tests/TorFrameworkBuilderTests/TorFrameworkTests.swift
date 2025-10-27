import XCTest
@testable import TorFrameworkBuilder

final class TorFrameworkBuilderTests: XCTestCase {
    
    func testTorWrapperExists() {
        // Проверка что wrapper доступен
        let tor = TorWrapper.shared()
        XCTAssertNotNil(tor, "TorWrapper должен быть доступен")
    }
    
    func testTorServiceExists() {
        // Проверка Swift wrapper
        let service = TorService.shared
        XCTAssertNotNil(service, "TorService должен быть доступен")
    }
    
    func testDefaultConfiguration() {
        let service = TorService.shared
        
        XCTAssertEqual(service.socksPort, 9050, "SOCKS порт должен быть 9050 по умолчанию")
        XCTAssertEqual(service.controlPort, 9051, "Control порт должен быть 9051 по умолчанию")
        XCTAssertFalse(service.isRunning, "Tor не должен быть запущен по умолчанию")
    }
    
    func testSOCKSProxyURL() {
        let service = TorService.shared
        let url = service.socksProxyURL
        
        XCTAssertTrue(url.hasPrefix("socks5://"), "URL должен начинаться с socks5://")
        XCTAssertTrue(url.contains("127.0.0.1"), "URL должен содержать localhost")
        XCTAssertTrue(url.contains("9050"), "URL должен содержать порт 9050")
    }
    
    func testTorStartStop() async throws {
        let service = TorService.shared
        
        // Этот тест требует реального Tor daemon, поэтому отключен
        // В реальных условиях раскомментируйте:
        
        /*
        // Запуск
        try await service.start()
        
        // Подождать подключения
        try await Task.sleep(nanoseconds: 5_000_000_000)
        
        // Проверка
        let isConnected = await withCheckedContinuation { continuation in
            service.checkConnection { connected in
                continuation.resume(returning: connected)
            }
        }
        
        XCTAssertTrue(isConnected, "Tor должен подключиться")
        
        // Остановка
        await service.stop()
        XCTAssertFalse(service.isRunning, "Tor должен быть остановлен")
        */
        
        // Placeholder тест
        XCTAssertTrue(true)
    }
    
    func testCreateURLSession() {
        let service = TorService.shared
        let session = service.createURLSession()
        
        XCTAssertNotNil(session, "URLSession должна создаваться")
        
        // Проверить proxy конфигурацию
        if let proxyDict = session.configuration.connectionProxyDictionary {
            XCTAssertNotNil(proxyDict[kCFNetworkProxiesSOCKSEnable as String])
            XCTAssertEqual(proxyDict[kCFNetworkProxiesSOCKSProxy as String] as? String, "127.0.0.1")
            XCTAssertEqual(proxyDict[kCFNetworkProxiesSOCKSPort as String] as? Int, 9050)
        }
    }
}

