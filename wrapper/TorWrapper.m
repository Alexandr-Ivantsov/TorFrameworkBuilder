//
//  TorWrapper.m
//  Tor Framework
//
//  Objective-C wrapper для Tor daemon
//

#import "TorWrapper.h"
#import <pthread.h>

// Прототипы функций Tor (будут линковаться из статической библиотеки)
extern int tor_main(int argc, char *argv[]);
extern void tor_cleanup(void);

@interface TorWrapper ()

@property (nonatomic, readwrite) TorStatus status;
@property (nonatomic, readwrite) NSInteger socksPort;
@property (nonatomic, readwrite) NSInteger controlPort;
@property (nonatomic, readwrite, copy) NSString *dataDirectory;
@property (nonatomic, readwrite, getter=isRunning) BOOL running;

@property (nonatomic, strong) NSFileHandle *controlFileHandle;
@property (nonatomic, strong) dispatch_queue_t torQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;  // Thread-safe queue for callbacks
// statusCallback и logCallback: НЕТ @property! Только ivars + методы (old-school ObjC)
@property (nonatomic, strong) NSString *torrcPath;
@property (nonatomic, assign) pthread_t torThread;
@property (nonatomic, assign) BOOL directoriesSetup;

@end

// Экспортируем все методы класса как внешние символы
__attribute__((visibility("default")))
@implementation TorWrapper {
    // Явные ivars для callbacks (old-school ObjC - без @property!)
    TorStatusCallback _statusCallback;
    TorLogCallback _logCallback;
}

// НЕТ @dynamic - он не нужен если нет @property!
// Только ivars + методы = никаких автогенераций = никаких symbol conflicts!

#pragma mark - Singleton

+ (instancetype)shared {
    static TorWrapper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[TorWrapper] Creating shared instance...");
        sharedInstance = [[self alloc] initPrivate];
        NSLog(@"[TorWrapper] Shared instance created successfully!");
    });
    return sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        NSLog(@"[TorWrapper] ✅ Step 1: super init done");
        
        _status = TorStatusStopped;
        NSLog(@"[TorWrapper] ✅ Step 2: status set to TorStatusStopped");
        
        _socksPort = 9050;
        _controlPort = 9051;
        _running = NO;
        _directoriesSetup = NO;
        NSLog(@"[TorWrapper] ✅ Step 3: ports configured (SOCKS: %ld, Control: %ld)", (long)_socksPort, (long)_controlPort);
        
        _torQueue = dispatch_queue_create("org.torproject.TorWrapper", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("org.torproject.TorWrapper.callbacks", DISPATCH_QUEUE_SERIAL);
        NSLog(@"[TorWrapper] ✅ Step 4: dispatch queues created (torQueue + callbackQueue)");
        
        // Используем Application Support по умолчанию
        NSString *appSupport = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
        NSLog(@"[TorWrapper] ✅ Step 5: appSupport found: %@", appSupport);
        
        _dataDirectory = [appSupport stringByAppendingPathComponent:@"Tor"];
        NSLog(@"[TorWrapper] ✅ Step 6: dataDirectory set: %@", _dataDirectory);
        
        // НЕ ВЫЗЫВАЕМ setupDirectories здесь - отложим до первого start()
        NSLog(@"[TorWrapper] ✅ Initialization complete (directories will be created on first start)");
    }
    return self;
}

#pragma mark - Configuration

- (void)configureWithSocksPort:(NSInteger)socksPort
                   controlPort:(NSInteger)controlPort
                 dataDirectory:(NSString *)dataDir {
    if (self.running) {
        NSLog(@"[Tor] Нельзя изменить конфигурацию пока Tor работает");
        return;
    }
    
    self.socksPort = socksPort;
    self.controlPort = controlPort;
    self.dataDirectory = dataDir;
    
    // Помечаем что директории нужно пересоздать при следующем запуске
    self.directoriesSetup = NO;
    NSLog(@"[TorWrapper] Configuration updated, directories will be recreated on next start");
}

- (void)setupDirectories {
    NSLog(@"[TorWrapper] ⏳ setupDirectories: Started");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSLog(@"[TorWrapper] ⏳ setupDirectories: Checking if directory exists at: %@", self.dataDirectory);
    // Создаём директорию для данных
    if (![fm fileExistsAtPath:self.dataDirectory]) {
        NSLog(@"[TorWrapper] ⏳ setupDirectories: Creating directory...");
        [fm createDirectoryAtPath:self.dataDirectory
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
        if (error) {
            NSLog(@"[Tor] ❌ Ошибка создания директории: %@", error);
        } else {
            NSLog(@"[TorWrapper] ✅ Directory created successfully");
        }
    } else {
        NSLog(@"[TorWrapper] ✅ Directory already exists");
    }
    
    NSLog(@"[TorWrapper] ⏳ setupDirectories: About to create torrc file...");
    // Создаём torrc файл
    [self createTorrcFile];
    
    self.directoriesSetup = YES;
    NSLog(@"[TorWrapper] ✅ setupDirectories: Complete");
}

- (void)createTorrcFile {
    NSLog(@"[TorWrapper] ⏳ createTorrcFile: Started");
    
    self.torrcPath = [self.dataDirectory stringByAppendingPathComponent:@"torrc"];
    NSLog(@"[TorWrapper] ⏳ createTorrcFile: torrcPath = %@", self.torrcPath);
    
    NSString *torrcContent = [NSString stringWithFormat:
        @"# Tor Configuration\n"
        @"SocksPort %ld\n"
        @"ControlPort %ld\n"
        @"DataDirectory %@\n"
        @"AvoidDiskWrites 1\n"
        @"Log notice stdout\n"
        @"RunAsDaemon 0\n"
        @"SafeLogging 0\n",
        (long)self.socksPort,
        (long)self.controlPort,
        self.dataDirectory
    ];
    
    NSLog(@"[TorWrapper] ⏳ createTorrcFile: About to write file...");
    NSError *error = nil;
    [torrcContent writeToFile:self.torrcPath
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:&error];
    
    if (error) {
        NSLog(@"[Tor] ❌ Ошибка создания torrc: %@", error);
    } else {
        NSLog(@"[TorWrapper] ✅ torrc file created successfully");
    }
    
    NSLog(@"[TorWrapper] ✅ createTorrcFile: Complete");
}

#pragma mark - Lifecycle

- (void)startWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (self.running) {
        NSLog(@"[Tor] Уже запущен");
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    [self logMessage:@"Запуск Tor daemon..."];
    self.status = TorStatusStarting;
    [self notifyStatus:TorStatusStarting message:@"Запуск Tor..."];
    
    dispatch_async(self.torQueue, ^{
        // Создаём директории на фоновом потоке (если ещё не создали)
        if (!self.directoriesSetup) {
            NSLog(@"[TorWrapper] Setting up directories on background thread...");
            [self setupDirectories];
            NSLog(@"[TorWrapper] Directories setup complete");
        } else {
            NSLog(@"[TorWrapper] Directories already setup, skipping");
        }
        
        // Запуск Tor в отдельном потоке
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        
        int result = pthread_create(&self->_torThread, &attr, torThreadMain, (__bridge void *)self);
        pthread_attr_destroy(&attr);
        
        if (result == 0) {
            self.running = YES;
            self.status = TorStatusConnecting;
            [self notifyStatus:TorStatusConnecting message:@"Подключение к сети Tor..."];
            
            // Даем время на запуск
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self checkConnectionWithCompletion:^(BOOL connected) {
                    if (connected) {
                        self.status = TorStatusConnected;
                        [self notifyStatus:TorStatusConnected message:@"Подключен к сети Tor"];
                        if (completion) {
                            completion(YES, nil);
                        }
                    } else {
                        // Даем еще времени
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self checkConnectionWithCompletion:^(BOOL connected) {
                                if (connected) {
                                    self.status = TorStatusConnected;
                                    [self notifyStatus:TorStatusConnected message:@"Подключен к сети Tor"];
                                    if (completion) {
                                        completion(YES, nil);
                                    }
                                } else {
                                    self.status = TorStatusError;
                                    NSError *error = [NSError errorWithDomain:@"org.torproject.TorWrapper"
                                                                         code:1
                                                                     userInfo:@{NSLocalizedDescriptionKey: @"Не удалось подключиться к сети Tor"}];
                                    [self notifyStatus:TorStatusError message:@"Ошибка подключения"];
                                    if (completion) {
                                        completion(NO, error);
                                    }
                                }
                            }];
                        });
                    }
                }];
            });
        } else {
            self.status = TorStatusError;
            NSError *error = [NSError errorWithDomain:@"org.torproject.TorWrapper"
                                                 code:2
                                             userInfo:@{NSLocalizedDescriptionKey: @"Не удалось запустить Tor поток"}];
            [self notifyStatus:TorStatusError message:@"Ошибка запуска"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO, error);
                }
            });
        }
    });
}

void *torThreadMain(void *context) {
    @autoreleasepool {
        TorWrapper *wrapper = (__bridge TorWrapper *)context;
        
        const char *argv[] = {
            "tor",
            "-f",
            [wrapper.torrcPath UTF8String],
            NULL
        };
        
        int argc = 3;
        
        NSLog(@"[Tor] Запуск tor_main()");
        int result = tor_main(argc, (char **)argv);
        NSLog(@"[Tor] tor_main() завершен с кодом: %d", result);
        
        wrapper.running = NO;
        wrapper.status = TorStatusStopped;
    }
    
    return NULL;
}

- (void)stopWithCompletion:(void (^)(void))completion {
    if (!self.running) {
        NSLog(@"[Tor] Уже остановлен");
        if (completion) {
            completion();
        }
        return;
    }
    
    [self logMessage:@"Остановка Tor daemon..."];
    
    // Отправляем команду SHUTDOWN через control port
    [self sendControlCommand:@"SIGNAL SHUTDOWN" completion:^(NSString * _Nullable response, NSError * _Nullable error) {
        self.running = NO;
        self.status = TorStatusStopped;
        [self notifyStatus:TorStatusStopped message:@"Tor остановлен"];
        
        if (completion) {
            completion();
        }
    }];
}

- (void)restartWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self stopWithCompletion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startWithCompletion:completion];
        });
    }];
}

#pragma mark - Status & Monitoring

- (void)setStatusCallback:(TorStatusCallback)callback {
    NSLog(@"[TorWrapper] Setting status callback");
    @synchronized(self) {
        _statusCallback = callback;  // ARC управляет lifetime автоматически!
    }
    NSLog(@"[TorWrapper] Status callback set successfully");
}

- (void)setLogCallback:(TorLogCallback)callback {
    NSLog(@"[TorWrapper] Setting log callback");
    @synchronized(self) {
        _logCallback = callback;  // ARC управляет lifetime автоматически!
    }
    NSLog(@"[TorWrapper] Log callback set successfully");
}

- (void)notifyStatus:(TorStatus)status message:(NSString *)message {
    NSLog(@"[TorWrapper] notifyStatus called: %ld - %@", (long)status, message);
    
    // Читаем callback thread-safe
    TorStatusCallback callback;
    @synchronized(self) {
        callback = _statusCallback;  // Прямой доступ к ivar, БЕЗ self.!
    }
    
    if (callback) {
        NSLog(@"[TorWrapper] Dispatching status callback to main queue");
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                callback(status, message);
                NSLog(@"[TorWrapper] Status callback executed successfully");
            } @catch (NSException *exception) {
                NSLog(@"[TorWrapper] ❌ Exception in statusCallback: %@", exception);
            }
        });
    } else {
        NSLog(@"[TorWrapper] ⚠️ Status callback is nil, skipping");
    }
}

- (void)logMessage:(NSString *)message {
    NSLog(@"[Tor] %@", message);
    
    // Читаем callback thread-safe
    TorLogCallback callback;
    @synchronized(self) {
        callback = _logCallback;  // Прямой доступ к ivar, БЕЗ self.!
    }
    
    if (callback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                callback(message);
            } @catch (NSException *exception) {
                NSLog(@"[TorWrapper] ❌ Exception in logCallback: %@", exception);
            }
        });
    }
}

- (void)checkConnectionWithCompletion:(void (^)(BOOL))completion {
    // Простая проверка: пытаемся подключиться к control порту
    dispatch_async(self.torQueue, ^{
        NSString *host = @"127.0.0.1";
        
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, (UInt32)self.controlPort, &readStream, &writeStream);
        
        if (readStream && writeStream) {
            NSInputStream *inputStream = (__bridge_transfer NSInputStream *)readStream;
            NSOutputStream *outputStream = (__bridge_transfer NSOutputStream *)writeStream;
            
            [inputStream open];
            [outputStream open];
            
            BOOL connected = (inputStream.streamStatus == NSStreamStatusOpen && outputStream.streamStatus == NSStreamStatusOpen);
            
            [inputStream close];
            [outputStream close];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(connected);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO);
                }
            });
        }
    });
}

#pragma mark - Control

- (void)sendControlCommand:(NSString *)command completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    dispatch_async(self.torQueue, ^{
        // TODO: Реализовать отправку команд через control port
        // Требуется реализация control protocol
        NSLog(@"[Tor] Команда: %@", command);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@"250 OK", nil);
            }
        });
    });
}

- (void)newIdentityWithCompletion:(void (^)(BOOL, NSError * _Nullable))completion {
    [self sendControlCommand:@"SIGNAL NEWNYM" completion:^(NSString * _Nullable response, NSError * _Nullable error) {
        BOOL success = (error == nil && [response containsString:@"250"]);
        if (completion) {
            completion(success, error);
        }
    }];
}

#pragma mark - Circuit Info

- (void)getCircuitInfoWithCompletion:(void (^)(NSArray<NSDictionary *> * _Nullable, NSError * _Nullable))completion {
    [self sendControlCommand:@"GETINFO circuit-status" completion:^(NSString * _Nullable response, NSError * _Nullable error) {
        if (error || !response) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        // TODO: Парсинг circuit-status
        if (completion) {
            completion(@[], nil);
        }
    }];
}

- (void)getExitIPWithCompletion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // TODO: Реализовать получение IP через Tor
    // Можно использовать https://check.torproject.org/api/ip
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"org.torproject.TorWrapper"
                                                code:3
                                            userInfo:@{NSLocalizedDescriptionKey: @"Не реализовано"}]);
        }
    });
}

#pragma mark - Helper Methods

- (NSString *)socksProxyURL {
    return [NSString stringWithFormat:@"socks5://127.0.0.1:%ld", (long)self.socksPort];
}

- (BOOL)isTorConfigured {
    return (self.torrcPath && [[NSFileManager defaultManager] fileExistsAtPath:self.torrcPath]);
}

@end

