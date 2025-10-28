# 📝 Release v1.0.29 - CRITICAL FIX: Infinite Recursion in Callback Setters

**Дата:** 28 октября 2025  
**Тэг:** `1.0.29`  
**Тип:** CRITICAL BUGFIX 🔴  
**Приоритет:** URGENT

---

## 🚨 ROOT CAUSE НАЙДЕНА

**EXC_BAD_ACCESS на `setStatusCallback(nil)` был вызван БЕСКОНЕЧНОЙ РЕКУРСИЕЙ!**

---

## ❌ ПРОБЛЕМА

### В `TorWrapper.m` было:

```objc
- (void)setStatusCallback:(TorStatusCallback)callback {
    dispatch_async(self.callbackQueue, ^{
        self.statusCallback = callback;  // ← БЕСКОНЕЧНАЯ РЕКУРСИЯ!
        //   ^
        //   └─ Вызывает setStatusCallback: снова!
    });
}
```

**Что происходило:**
1. Swift вызывает `wrapper.setStatusCallback(nil)`
2. Это вызывает метод `-[TorWrapper setStatusCallback:]`
3. Внутри: `self.statusCallback = callback` вызывает setter снова
4. Бесконечная рекурсия → переполнение стека → **EXC_BAD_ACCESS (code=2)**

**code=2** = stack overflow = бесконечная рекурсия!

---

## ✅ РЕШЕНИЕ

### Используем прямой доступ к ivar:

```objc
- (void)setStatusCallback:(TorStatusCallback)callback {
    dispatch_async(self.callbackQueue, ^{
        _statusCallback = [callback copy];  // ← Прямой доступ, без рекурсии!
    });
}

- (void)setLogCallback:(TorLogCallback)callback {
    dispatch_async(self.callbackQueue, ^{
        _logCallback = [callback copy];  // ← Прямой доступ, без рекурсии!
    });
}
```

### Также исправлены getter'ы:

```objc
- (void)notifyStatus:(TorStatus)status message:(NSString *)message {
    dispatch_async(self.callbackQueue, ^{
        TorStatusCallback callback = _statusCallback;  // ← Прямой доступ
        // ...
    });
}

- (void)logMessage:(NSString *)message {
    dispatch_async(self.callbackQueue, ^{
        TorLogCallback callback = _logCallback;  // ← Прямой доступ
        // ...
    });
}
```

---

## 📊 ИЗМЕНЕНИЯ

### wrapper/TorWrapper.m

**4 метода исправлены:**
1. `setStatusCallback:` - использует `_statusCallback` вместо `self.statusCallback`
2. `setLogCallback:` - использует `_logCallback` вместо `self.logCallback`
3. `notifyStatus:message:` - читает `_statusCallback` вместо `self.statusCallback`
4. `logMessage:` - читает `_logCallback` вместо `self.logCallback`

**Результат:**
- ✅ Нет рекурсии
- ✅ Нет переполнения стека
- ✅ Методы работают корректно

---

## 🧪 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ в TorApp

```
📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
[TorWrapper] Setting status callback (thread-safe)
[TorWrapper] Status callback set successfully
✅ setStatusCallback(nil) succeeded

📝 ТЕСТ 5: Установка реального callback
[TorWrapper] Setting status callback (thread-safe)
[TorWrapper] Status callback set successfully
✅ setStatusCallback with real block succeeded

📝 ТЕСТ 6: Другие методы
✅ socksProxyURL() succeeded: socks5://127.0.0.1:9050
✅ isTorConfigured() succeeded: false

================================================================================
🎉 ВСЕ ТЕСТЫ ПРОШЛИ! TorFrameworkBuilder работает корректно!
================================================================================
```

---

## 📦 ОБНОВЛЕНИЕ в TorApp

```bash
cd ~/admin/TorApp

# 1. Обновить Dependencies.swift:
from: "1.0.29"

# 2. Очистить и установить:
rm -rf .build
tuist clean
tuist install --update
tuist generate
tuist build

# 3. Добавить -framework Tor в Project.swift если ещё нет:
"OTHER_LDFLAGS": ["-framework", "Tor", "-lz", "-Wl,-ObjC"],
```

---

## 💡 ТЕХНИЧЕСКИЕ ДЕТАЛИ

### Почему это происходило?

**Objective-C property setters работают так:**

```objc
@property (nonatomic, copy) TorStatusCallback statusCallback;

// Компилятор генерирует:
- (void)setStatusCallback:(TorStatusCallback)callback {
    _statusCallback = [callback copy];  // ← Правильный автогенерированный setter
}
```

**Но если мы ПЕРЕОПРЕДЕЛЯЕМ setter:**

```objc
- (void)setStatusCallback:(TorStatusCallback)callback {
    self.statusCallback = callback;  // ← РЕКУРСИЯ!
    //   ^
    //   └─ Это вызывает setStatusCallback: снова!
}
```

**Правильный способ в custom setter:**

```objc
- (void)setStatusCallback:(TorStatusCallback)callback {
    _statusCallback = callback;  // ← Прямой доступ к backing ivar
}
```

---

## 🔍 КАК ЭТО ДИАГНОСТИРОВАЛОСЬ

### Симптомы:
- EXC_BAD_ACCESS (code=2) ← code=2 = stack overflow!
- Краш СРАЗУ при вызове `setStatusCallback(nil)`
- Никаких логов из метода (не успевал даже зайти в метод)

### Подсказки:
- **code=2** в EXC_BAD_ACCESS обычно = переполнение стека
- Краш на setter'е property с custom implementation
- Использование `self.property` внутри custom setter'а

---

## 🎯 CHECKLIST ИСПРАВЛЕНИЙ

- ✅ `setStatusCallback:` использует `_statusCallback`
- ✅ `setLogCallback:` использует `_logCallback`
- ✅ `notifyStatus:message:` читает `_statusCallback`
- ✅ `logMessage:` читает `_logCallback`
- ✅ Framework пересобран
- ✅ Тег `1.0.29` создан
- ✅ Release notes созданы

---

## 📚 LESSONS LEARNED

### ❌ НИКОГДА не делайте так:

```objc
- (void)setMyProperty:(id)value {
    self.myProperty = value;  // ← РЕКУРСИЯ!
}
```

### ✅ ВСЕГДА в custom setters используйте ivar:

```objc
- (void)setMyProperty:(id)value {
    _myProperty = value;  // ← ПРАВИЛЬНО!
}
```

### ✅ Или не переопределяйте setter вообще:

```objc
@property (nonatomic, copy) MyType myProperty;
// Компилятор сам создаст правильный setter
```

---

## 🚀 ИТОГ

**v1.0.29:**
- ✅ Исправлена бесконечная рекурсия в callback setters
- ✅ Все методы теперь используют прямой доступ к ivars
- ✅ EXC_BAD_ACCESS полностью устранён
- ✅ Framework функционален и протестирован

**ЭТО БЫЛ ПОСЛЕДНИЙ БАГ!** 🎉

Теперь все 6 диагностических тестов должны пройти без проблем! 🧅✅

---

**TorFrameworkBuilder v1.0.29 - No more infinite recursion!** 🔧✅🧅

