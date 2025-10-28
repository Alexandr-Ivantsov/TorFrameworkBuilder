# 🔧 Инструкция по отладке EXC_BAD_ACCESS в setStatusCallback

**Версия:** 1.0.28 (debug build)  
**Проблема:** EXC_BAD_ACCESS на `wrapper.setStatusCallback(nil)`  
**Статус:** Добавлено детальное логирование для определения точной причины

---

## 🎯 ШАГ 1: Обновить TorFrameworkBuilder до v1.0.28

```bash
cd ~/admin/TorApp

# Обновить Dependencies.swift:
# from: "1.0.28"

rm -rf .build
tuist clean
tuist install --update
tuist generate
```

---

## 🎯 ШАГ 2: КРИТИЧЕСКИ ВАЖНО - Проверить Build Settings

### Открыть `Project.swift` и найти `settings`:

**ДОЛЖНО БЫТЬ:**

```swift
targets: [
    .target(
        name: "TorApp",
        // ...
        settings: .settings(
            base: [
                "OTHER_LDFLAGS": [
                    "-framework", "Tor",
                    "-lz",
                    "-Wl,-ObjC"  // ← КРИТИЧЕСКИ ВАЖНО!!!
                ],
                "LD_RUNPATH_SEARCH_PATHS": [
                    "@executable_path/Frameworks"
                ]
            ]
        )
    )
]
```

**ЕСЛИ `-Wl,-ObjC` ОТСУТСТВУЕТ - ДОБАВИТЬ!**

Этот флаг заставляет линкер загрузить ВСЕ Objective-C категории и методы из static libraries. Без него `dispatch_async` и другие методы могут не работать!

---

## 🎯 ШАГ 3: Запустить с новым логированием

```bash
tuist build
# Или запустить через Xcode
```

### В Console вы увидите:

```
📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
[TorWrapper] 🔵 setStatusCallback called
[TorWrapper] 🔵 self = 0x...
[TorWrapper] 🔵 callbackQueue = 0x...
[TorWrapper] 🔵 About to call dispatch_async...
```

**ОТПРАВЬТЕ МНЕ ВЕСЬ ВЫВОД ДО КРАША!**

---

## 🔍 ВОЗМОЖНЫЕ СЦЕНАРИИ

### Сценарий A: callbackQueue = 0x0 (NULL)

```
[TorWrapper] 🔵 callbackQueue = 0x0
[TorWrapper] ❌ ERROR: callbackQueue is NULL! Recreating...
```

**Причина:** callbackQueue не был создан в init  
**Решение:** Уже добавлен fallback - будет пересоздан

---

### Сценарий B: Краш на "About to call dispatch_async..."

```
[TorWrapper] 🔵 callbackQueue = 0x600001234000
[TorWrapper] 🔵 About to call dispatch_async...
❌ КРАШ здесь
```

**Причина:** `dispatch_async` не линкуется правильно  
**Решение:** Добавить `-Wl,-ObjC` в `OTHER_LDFLAGS`

---

### Сценарий C: Краш внутри dispatch_async block

```
[TorWrapper] 🔵 dispatch_async returned
[TorWrapper] 🔵 Inside dispatch_async block
❌ КРАШ здесь
```

**Причина:** Проблема с `self.statusCallback` setter  
**Решение:** Проверю property декларацию

---

### Сценарий D: Краш ДО первого лога

```
📝 ТЕСТ 4: Вызов метода setStatusCallback(nil)
❌ КРАШ сразу (нет логов TorWrapper)
```

**Причина:** Метод `setStatusCallback:` не найден в runtime  
**Решение:** Проблема в module.modulemap или headers  
**Действие:** Добавить `-Wl,-ObjC` и проверить что headers импортированы

---

## 🎯 ШАГ 4: Собрать информацию для отчёта

### Отправьте мне:

1. **Весь вывод Console до краша:**
```
📝 ТЕСТ 4: ...
[TorWrapper] 🔵 ...
... (всё что вывелось)
❌ КРАШ
```

2. **Project.swift - секция settings:**
```swift
settings: .settings(
    base: [
        "OTHER_LDFLAGS": [ ... ],  // ← что здесь?
    ]
)
```

3. **Crash Log (если доступен):**
```
Thread 1 crashed with ...
```

---

## 💡 БЫСТРОЕ РЕШЕНИЕ (попробуйте СНАЧАЛА)

### В `Project.swift` найдите target и добавьте:

```swift
.target(
    name: "TorApp",
    destinations: [.iPhone, .iPad],
    product: .app,
    bundleId: "...",
    sources: ["Sources/**"],
    dependencies: [
        // ...
    ],
    settings: .settings(
        base: [
            // ✅ ДОБАВИТЬ ЭТО:
            "OTHER_LDFLAGS": [
                "-framework", "Tor",
                "-lz",
                "-Wl,-ObjC"  // ← ЭТО КРИТИЧНО!
            ],
            "LD_RUNPATH_SEARCH_PATHS": [
                "@executable_path/Frameworks"
            ]
        ]
    )
)
```

### Затем:

```bash
tuist clean
tuist generate
tuist build
```

---

## 🔍 ДОПОЛНИТЕЛЬНАЯ ДИАГНОСТИКА

### Если краш продолжается, добавьте в diagnostic код:

```swift
// ПЕРЕД ТЕСТОМ 4:
print("\n📝 ТЕСТ 3.5: Проверка responds(to:)")
let respondsToSetStatusCallback = wrapper.responds(to: #selector(setter: TorWrapper.setStatusCallback(_:)))
print("   responds to setStatusCallback: \(respondsToSetStatusCallback)")

if !respondsToSetStatusCallback {
    print("❌ КРИТИЧЕСКАЯ ОШИБКА: метод не найден в runtime!")
    print("   Проверьте что добавлен -Wl,-ObjC в OTHER_LDFLAGS")
    return
}
```

---

## 📊 CHECKLIST

Перед запуском убедитесь:

- [ ] TorFrameworkBuilder обновлён до v1.0.28
- [ ] `.build` удалён (`rm -rf .build`)
- [ ] `tuist clean` выполнен
- [ ] `tuist generate` выполнен
- [ ] **`-Wl,-ObjC` добавлен в `OTHER_LDFLAGS`** ← САМОЕ ВАЖНОЕ!
- [ ] `LD_RUNPATH_SEARCH_PATHS` содержит `@executable_path/Frameworks`
- [ ] Console открыт для просмотра логов

---

## 🚨 ЕСЛИ ВСЁ ЕЩЁ НЕ РАБОТАЕТ

Отправьте мне:
1. Весь вывод Console с логами 🔵
2. Содержимое `Project.swift` (хотя бы секцию `settings`)
3. Результат команды:
   ```bash
   cd ~/admin/TorApp
   cat Tuist/Dependencies.swift | grep -A 5 "TorFrameworkBuilder"
   ```

**Я помогу вам решить эту проблему!** 💪

---

## 💡 ТЕОРИЯ: Почему `-Wl,-ObjC` так важен?

**Без `-Wl,-ObjC`:**
- Линкер загружает только прямо используемые символы из `.a` файлов
- Objective-C категории и некоторые методы могут не загрузиться
- `dispatch_async`, blocks, и другие runtime функции могут отсутствовать
- Результат: `EXC_BAD_ACCESS` при попытке их использовать

**С `-Wl,-ObjC`:**
- Линкер загружает ВСЕ Objective-C классы и категории
- Все runtime символы доступны
- Framework работает корректно

---

**TorFrameworkBuilder v1.0.28 - Debug build with extensive logging!** 🔍🔧










