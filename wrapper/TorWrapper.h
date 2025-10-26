//
//  TorWrapper.h
//  Tor Framework
//
//  Objective-C wrapper для Tor daemon
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Статусы Tor daemon
typedef NS_ENUM(NSInteger, TorStatus) {
    TorStatusStopped = 0,      ///< Tor остановлен
    TorStatusStarting,         ///< Tor запускается
    TorStatusConnecting,       ///< Подключение к сети Tor
    TorStatusConnected,        ///< Подключен к сети Tor
    TorStatusError,            ///< Ошибка
};

/// Callback для уведомлений о статусе
typedef void (^TorStatusCallback)(TorStatus status, NSString * _Nullable message);

/// Callback для логов
typedef void (^TorLogCallback)(NSString *message);

/// Wrapper для Tor daemon
@interface TorWrapper : NSObject

/// Singleton instance
@property (class, readonly, strong) TorWrapper *shared;

/// Текущий статус Tor
@property (nonatomic, readonly) TorStatus status;

/// SOCKS порт (по умолчанию 9050)
@property (nonatomic, readonly) NSInteger socksPort;

/// Control порт (по умолчанию 9051)
@property (nonatomic, readonly) NSInteger controlPort;

/// Директория данных Tor
@property (nonatomic, readonly, copy) NSString *dataDirectory;

/// Запущен ли Tor
@property (nonatomic, readonly, getter=isRunning) BOOL running;

#pragma mark - Initialization

/// Нельзя создавать экземпляры напрямую, используйте shared
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark - Configuration

/// Настройка портов и директорий перед запуском
/// @param socksPort SOCKS порт
/// @param controlPort Control порт
/// @param dataDir Директория для данных Tor
- (void)configureWithSocksPort:(NSInteger)socksPort
                   controlPort:(NSInteger)controlPort
                 dataDirectory:(NSString *)dataDir;

#pragma mark - Lifecycle

/// Запуск Tor daemon
/// @param completion Completion block с результатом
- (void)startWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/// Остановка Tor daemon
/// @param completion Completion block
- (void)stopWithCompletion:(void (^)(void))completion;

/// Перезапуск Tor daemon
/// @param completion Completion block с результатом
- (void)restartWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

#pragma mark - Status & Monitoring

/// Установка callback для статуса
/// @param callback Callback для уведомлений о статусе
- (void)setStatusCallback:(nullable TorStatusCallback)callback;

/// Установка callback для логов
/// @param callback Callback для логов
- (void)setLogCallback:(nullable TorLogCallback)callback;

/// Проверка подключения к сети Tor
/// @param completion Completion block с результатом
- (void)checkConnectionWithCompletion:(void (^)(BOOL connected))completion;

#pragma mark - Control

/// Отправка команды в control port
/// @param command Команда для отправки
/// @param completion Completion block с ответом
- (void)sendControlCommand:(NSString *)command
                completion:(void (^)(NSString * _Nullable response, NSError * _Nullable error))completion;

/// Получить новую идентичность (новую цепь)
/// @param completion Completion block с результатом
- (void)newIdentityWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

#pragma mark - Circuit Info

/// Получить информацию о текущих цепях
/// @param completion Completion block с информацией о цепях
- (void)getCircuitInfoWithCompletion:(void (^)(NSArray<NSDictionary *> * _Nullable circuits, NSError * _Nullable error))completion;

/// Получить IP адрес выходного узла
/// @param completion Completion block с IP адресом
- (void)getExitIPWithCompletion:(void (^)(NSString * _Nullable ipAddress, NSError * _Nullable error))completion;

#pragma mark - Helper Methods

/// Получить полный SOCKS5 proxy URL
/// @return SOCKS5 proxy URL (например, socks5://127.0.0.1:9050)
- (NSString *)socksProxyURL;

/// Проверить, установлен ли Tor корректно
/// @return YES если Tor готов к использованию
- (BOOL)isTorConfigured;

@end

NS_ASSUME_NONNULL_END

