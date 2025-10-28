# 🎉 Как использовать TorFrameworkBuilder v1.0.30 в TorApp

**Статус:** ✅ **VERIFIED - NO RECURSION!**  
**Проверено:** `nm` подтвердил отсутствие рекурсии  
**Дата:** 28 октября 2025

---

## 🚀 QUICK START

### Шаг 1: Обновить Dependencies.swift

```swift
// Tuist/Dependencies.swift
import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies([
        .remote(
            url: "https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git",
            requirement: .upToNextMajor(from: "1.0.30")  // ← Обновить на 1.0.30
        )
    ])
)
```

### Шаг 2: Очистить и установить

```bash
cd ~/admin/TorApp

# Полная очистка:
rm -rf .build Tuist/Dependencies

# Установить заново:
tuist clean
tuist install --update
tuist generate
```

### Шаг 3: Проверить OTHER_LDFLAGS

В `Project.swift` убедитесь что есть:

```swift
settings: .settings(
    base: [
        "OTHER_LDFLAGS": [
            "-framework", "Tor",
            "-lz",
            "-Wl,-ObjC"
        ]
    ]
)
```

### Шаг 4: Собрать и запустить

```bash
tuist build

# Или открыть в Xcode:
tuist generate
open TorApp.xcworkspace
```

---

## 🧪 ОЖИДАЕМЫЕ РЕЗУЛЬТАТЫ

### Диагностические тесты должны показать:

```
📝 ТЕСТ 1: Инициализация TorWrapper
[TorWrapper] Shared instance initialized successfully
✅ TorWrapper loaded successfully

📝 ТЕСТ 2: Доступ к TorWrapper.shared
✅ TorWrapper.shared accessible: <TorWrapper: 0x...>

📝 ТЕСТ 3: Чтение свойств
[TorWrapper] socksPort: 9050
✅ socksPort: 9050

📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
[TorWrapper] Setting status callback
[TorWrapper] Status callback set successfully
✅ setStatusCallback(nil) succeeded  ← БЕЗ КРАША!

📝 ТЕСТ 5: Установка реального callback
[TorWrapper] Setting status callback
[TorWrapper] Status callback set successfully
✅ setStatusCallback with real block succeeded

📝 ТЕСТ 6: Другие методы
✅ socksProxyURL() succeeded: socks5://127.0.0.1:9050
✅ isTorConfigured() succeeded: false

🎉🎉🎉 ВСЕ 6 ТЕСТОВ ПРОШЛИ! 🎉🎉🎉
```

---

## 🔍 ВЕРИФИКАЦИЯ В TORAPP

### Проверить что framework корректный:

```bash
cd ~/admin/TorApp

# После tuist install проверить:
nm .build/checkouts/TorFrameworkBuilder/output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor | grep "U.*setStatusCallback"

# Должно быть ПУСТО! Если видите:
#                  U _objc_msgSend$setStatusCallback:
# ← Значит старая версия framework в кеше, нужно очистить .build
```

### Если видите рекурсию - очистить кеш:

```bash
rm -rf .build
rm -rf Tuist/Dependencies
tuist clean
tuist install --update --force
```

---

## 📊 ЧТО ИСПРАВЛЕНО В v1.0.30

### ✅ Убрана рекурсия из callback setters:

**Было (v1.0.29 - НЕ работало):**
```objc
- (void)setStatusCallback:(TorStatusCallback)callback {
    dispatch_async(self.callbackQueue, ^{
        _statusCallback = [callback copy];  // ← Компилятор генерировал self.statusCallback!
    });
}
```

**Стало (v1.0.30 - РАБОТАЕТ):**
```objc
- (void)setStatusCallback:(TorStatusCallback)callback {
    @synchronized(self) {
        _statusCallback = [callback copy];  // ← Прямой доступ вне блока!
    }
}
```

### ✅ Исправлено чтение callbacks:

**Было:**
```objc
- (void)notifyStatus:(TorStatus)status message:(NSString *)message {
    dispatch_async(self.callbackQueue, ^{
        TorStatusCallback callback = _statusCallback;  // ← В блоке!
        // ...
    });
}
```

**Стало:**
```objc
- (void)notifyStatus:(TorStatus)status message:(NSString *)message {
    TorStatusCallback callback;
    @synchronized(self) {
        callback = _statusCallback;  // ← Читаем вне блока!
    }
    
    if (callback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(status, message);  // ← Вызываем в main queue
        });
    }
}
```

---

## 💡 ПОЧЕМУ v1.0.29 НЕ РАБОТАЛА

### Проблема с `_ivarName` в блоках:

В Objective-C блоках, компилятор может интерпретировать `_ivarName` как:
1. Прямой доступ к ivar (правильно)
2. Доступ через property accessor `self.ivarName` (РЕКУРСИЯ!)

Это зависит от контекста, и в v1.0.29 компилятор выбрал вариант 2.

**Доказательство:**
```bash
$ nm Tor.framework/Tor | grep "U.*setStatusCallback"
                 U _objc_msgSend$setStatusCallback:
# ↑ Метод вызывает objc_msgSend с селектором setStatusCallback:
#   Это означает что внутри метода есть [self setStatusCallback:...]
#   или self.statusCallback = ...
```

### Решение - убрать блок из setter:

Используя `@synchronized` вместо `dispatch_async`, мы:
1. Избегаем проблемы с интерпретацией `_ivarName` в блоке
2. Сохраняем thread safety
3. Гарантируем прямой доступ к ivar

**Верификация v1.0.30:**
```bash
$ nm Tor.framework/Tor | grep "U.*setStatusCallback"
(пусто) ← ✅ НЕТ РЕКУРСИИ!
```

---

## 🚨 ЕСЛИ ТЕСТЫ ВСЁ ЕЩЁ НЕ ПРОХОДЯТ

### 1. Проверить версию в зависимостях:

```bash
cat Tuist/Dependencies.swift | grep "1.0.30"
# Должно быть: from: "1.0.30"
```

### 2. Полная очистка:

```bash
rm -rf .build
rm -rf Tuist/Dependencies
rm -rf DerivedData
tuist clean
```

### 3. Переустановить:

```bash
tuist install --update --force
tuist generate
```

### 4. Проверить framework в кеше:

```bash
# Найти где лежит framework:
find .build -name "Tor.framework" -type d

# Проверить каждый найденный:
nm <путь>/Tor | grep "U.*setStatusCallback"
# Если видите "U _objc_msgSend$setStatusCallback:" - это старая версия!
```

### 5. Если ничего не помогло - удалить весь кеш Tuist:

```bash
rm -rf ~/.tuist/Cache
rm -rf ~/Library/Caches/com.apple.dt.tuist
tuist clean
```

---

## 📞 КОНТАКТЫ

Если проблема сохраняется:
1. Проверьте что тег `1.0.30` есть в репозитории
2. Проверьте что `Dependencies.swift` указывает на правильную версию
3. Убедитесь что кеш полностью очищен
4. Запустите диагностические тесты из `DIAGNOSTIC_PROMPT_FOR_TORAPP.md`

---

## ✅ CHECKLIST

Перед запуском TorApp убедитесь:

- [ ] `Dependencies.swift` содержит `from: "1.0.30"`
- [ ] Кеш очищен (`rm -rf .build Tuist/Dependencies`)
- [ ] `tuist install --update` выполнен успешно
- [ ] `OTHER_LDFLAGS` содержит `-framework Tor -lz -Wl,-ObjC`
- [ ] `nm` показывает отсутствие рекурсии (пустой вывод для grep setStatusCallback)
- [ ] Framework существует в `.build/checkouts/TorFrameworkBuilder/output/`

---

## 🎉 ФИНАЛЬНАЯ ПРОВЕРКА

После выполнения всех шагов запустите:

```bash
tuist build

# Если успешно:
✅ Build succeeded!

# В логах должны быть:
[TorWrapper] Setting status callback
[TorWrapper] Status callback set successfully
✅ setStatusCallback(nil) succeeded

# БЕЗ:
❌ EXC_BAD_ACCESS
❌ Thread 1: signal SIGSEGV
❌ Crash
```

---

**TorFrameworkBuilder v1.0.30 - Ready to use! Verified with nm!** 🧅✅

**P.S.** Спасибо за терпение и детальную диагностику с `nm`! Теперь всё должно работать! 🙏

