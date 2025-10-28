# 🚨 Release v1.0.21 - Critical UI Hang Fix

**Дата:** 28 октября 2025  
**Тэг:** `1.0.21`  
**Приоритет:** 🔴 **КРИТИЧЕСКОЕ ОБНОВЛЕНИЕ**

---

## 🐛 КРИТИЧЕСКАЯ ПРОБЛЕМА ИСПРАВЛЕНА

### App зависал при первом обращении к `TorWrapper.shared`

**Симптомы (v1.0.20 и ранее):**
```swift
// В TorApp при первом вызове:
let wrapper = TorWrapper.shared  // ← ЗАВИСАНИЕ! UI перестаёт отвечать
```

**Логи показывали:**
```
🔥 TorManager: Accessing TorWrapper.shared (first time)...
← ПОЛНОЕ ЗАВИСАНИЕ. Никаких дальнейших логов.
```

---

## 🔍 ПРИЧИНА ПРОБЛЕМЫ

### `TorWrapper.shared` блокировал main thread

**Что происходило в v1.0.20:**

```objc
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];  // ← на main thread
    });
    return sharedInstance;
}

- (instancetype)initPrivate {
    // ...
    [self setupDirectories];  // ← СИНХРОННАЯ I/O операция!
    return self;
}

- (void)setupDirectories {
    // Создание директории - БЛОКИРУЕТ ПОТОК!
    [fm createDirectoryAtPath:...];  
    
    // Запись файла - БЛОКИРУЕТ ПОТОК!
    [torrcContent writeToFile:...];
}
```

**Проблема:** File I/O операции на main thread → UI hang 💀

---

## ✅ РЕШЕНИЕ

### 1. Убрали I/O из `initPrivate`

**Было (v1.0.20):**
```objc
- (instancetype)initPrivate {
    // ...
    [self setupDirectories];  // ← блокировка!
    return self;
}
```

**Стало (v1.0.21):**
```objc
- (instancetype)initPrivate {
    // ...
    _directoriesSetup = NO;
    // setupDirectories НЕ вызывается!
    NSLog(@"[TorWrapper] ✅ Initialization complete (directories will be created on first start)");
    return self;
}
```

### 2. Перенесли I/O в фоновый поток

**Было (v1.0.20):**
```objc
- (void)startWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_async(self.torQueue, ^{
        // Запуск Tor
        pthread_create(&self->_torThread, ...);
    });
}
```

**Стало (v1.0.21):**
```objc
- (void)startWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_async(self.torQueue, ^{
        // СОЗДАЁМ ДИРЕКТОРИИ НА ФОНОВОМ ПОТОКЕ!
        if (!self.directoriesSetup) {
            NSLog(@"[TorWrapper] Setting up directories on background thread...");
            [self setupDirectories];
            NSLog(@"[TorWrapper] Directories setup complete");
        }
        
        // Запуск Tor
        pthread_create(&self->_torThread, ...);
    });
}
```

### 3. Добавили детальное логирование

**Каждая операция теперь логируется:**
```objc
NSLog(@"[TorWrapper] ✅ Step 1: super init done");
NSLog(@"[TorWrapper] ✅ Step 2: status set to TorStatusStopped");
// ...
NSLog(@"[TorWrapper] ⏳ setupDirectories: Creating directory...");
NSLog(@"[TorWrapper] ✅ Directory created successfully");
```

---

## 📊 ДО vs ПОСЛЕ

### v1.0.20 (BROKEN):
```
🔥 TorManager: Accessing TorWrapper.shared...
← ЗАВИСАНИЕ (setupDirectories блокирует main thread)
```

### v1.0.21 (FIXED):
```
🔥 TorManager: Accessing TorWrapper.shared...
[TorWrapper] Creating shared instance...
[TorWrapper] ✅ Step 1: super init done
[TorWrapper] ✅ Step 2: status set to TorStatusStopped
[TorWrapper] ✅ Step 3: ports configured (SOCKS: 9050, Control: 9051)
[TorWrapper] ✅ Step 4: dispatch queue created
[TorWrapper] ✅ Step 5: appSupport found: /path/to/...
[TorWrapper] ✅ Step 6: dataDirectory set: /path/to/.../Tor
[TorWrapper] ✅ Initialization complete (directories will be created on first start)
[TorWrapper] Shared instance created successfully!
🔥 TorManager: TorWrapper.shared accessed successfully!
✅ UI ОСТАЁТСЯ ОТЗЫВЧИВЫМ!
```

---

## 🚀 КАК ОБНОВИТЬСЯ

### В TorApp:

```bash
cd ~/admin/TorApp

# 1. Очистите кэш
rm -rf .build
tuist clean

# 2. Обновите Dependencies.swift или Package.swift:
from: "1.0.21"  # ← КРИТИЧЕСКОЕ ОБНОВЛЕНИЕ!

# 3. Установите
tuist install --update
tuist generate
```

### Изменения в коде:

**НЕ ТРЕБУЮТСЯ!** Просто обновите версию framework.

---

## 📝 ТЕХНИЧЕСКИЕ ДЕТАЛИ

### Изменённые файлы:

**`wrapper/TorWrapper.m`:**
- ✅ `initPrivate`: Убран вызов `setupDirectories`
- ✅ `setupDirectories`: Добавлено детальное логирование
- ✅ `createTorrcFile`: Добавлено детальное логирование
- ✅ `startWithCompletion`: Добавлен вызов `setupDirectories` на `torQueue`
- ✅ `configureWithSocksPort`: Теперь только устанавливает `directoriesSetup = NO`
- ✅ Добавлено свойство `directoriesSetup` для отслеживания состояния

### Добавлено:

```objc
@property (nonatomic, assign) BOOL directoriesSetup;
```

### Новое поведение:

| Операция | v1.0.20 | v1.0.21 |
|----------|---------|---------|
| `TorWrapper.shared` | ❌ Блокирует main thread | ✅ Мгновенно возвращается |
| Создание директорий | ❌ На main thread | ✅ На torQueue |
| Запись torrc файла | ❌ На main thread | ✅ На torQueue |
| UI responsiveness | ❌ Зависает | ✅ Остаётся отзывчивым |
| Логирование | ⚠️ Минимальное | ✅ Детальное |

---

## ⚠️ ВАЖНО

### Это критическое обновление!

**v1.0.20 и ранее:** App зависает при первом запуске  
**v1.0.21:** App работает нормально

**Обновитесь немедленно если используете v1.0.20!**

---

## 🎯 РЕЗУЛЬТАТ

```
╔═══════════════════════════════════════════╗
║  TorFrameworkBuilder v1.0.21              ║
╠═══════════════════════════════════════════╣
║  ✅ 100% symbol resolution                ║
║  ✅ UI hang FIXED                         ║
║  ✅ Non-blocking initialization           ║
║  ✅ Detailed diagnostic logging           ║
║  ✅ Background I/O operations             ║
║  ✅ READY FOR PRODUCTION USE! 🚀          ║
╚═══════════════════════════════════════════╝
```

---

## 🐞 DEBUGGING

Если у вас всё ещё проблемы, проверьте логи:

**Ожидаемые логи:**
```
[TorWrapper] Creating shared instance...
[TorWrapper] ✅ Step 1: super init done
[TorWrapper] ✅ Step 2: status set to TorStatusStopped
[TorWrapper] ✅ Step 3: ports configured (SOCKS: 9050, Control: 9051)
[TorWrapper] ✅ Step 4: dispatch queue created
[TorWrapper] ✅ Step 5: appSupport found: ...
[TorWrapper] ✅ Step 6: dataDirectory set: ...
[TorWrapper] ✅ Initialization complete (directories will be created on first start)
[TorWrapper] Shared instance created successfully!
```

Если логи обрываются на каком-то шаге - **сообщите мне!**

---

## 📚 CHANGELOG

### v1.0.20 → v1.0.21

**Исправлено:**
- ✅ UI hang при первом обращении к `TorWrapper.shared`
- ✅ Блокировка main thread синхронными I/O операциями

**Добавлено:**
- ✅ Детальное логирование инициализации
- ✅ Флаг `directoriesSetup` для отложенной инициализации
- ✅ Создание директорий на фоновом потоке

**Улучшено:**
- ✅ UX: приложение остаётся отзывчивым при запуске
- ✅ DX: детальные логи для отладки проблем

---

## 🙏 БЛАГОДАРНОСТИ

Спасибо за то что сообщили о проблеме с зависанием! 

**TorFrameworkBuilder v1.0.21 теперь готов к production!** 🎉🧅















