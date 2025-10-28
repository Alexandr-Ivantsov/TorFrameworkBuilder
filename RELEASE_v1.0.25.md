# 📝 Release v1.0.25 - Enhanced Symbol Export Verification

**Дата:** 28 октября 2025  
**Тэг:** `1.0.25`  
**Тип:** Улучшение + Верификация

---

## ✨ ЧТО ДОБАВЛЕНО

### Экспорт всех символов через exported_symbols_list

**v1.0.25 добавляет:**
- `-Wl,-exported_symbols_list` с wildcard `*` для полного экспорта
- Автоматическую верификацию экспорта символов после сборки
- Детальное логирование состояния экспорта

---

## 🔧 ИЗМЕНЕНИЯ

### scripts/create_xcframework_universal.sh

**Добавлено создание export list:**
```bash
# Создаём export list для всех символов
cat > output/device-obj/exports.txt << 'EOF'
*
EOF

clang -dynamiclib \
    ...
    -Wl,-exported_symbols_list,output/device-obj/exports.txt \
    ...
```

**Добавлена верификация экспорта:**
```bash
echo "🔍 Проверка экспорта методов TorWrapper..."
if nm -gU "${DEVICE_FW}/${FRAMEWORK_NAME}" | grep -q "TorWrapper.*T "; then
    echo "✅ Методы TorWrapper экспортированы как глобальные символы"
    nm -gU "${DEVICE_FW}/${FRAMEWORK_NAME}" | grep "TorWrapper" | head -5
else
    echo "⚠️  Только класс экспортирован, методы локальные (это OK для ObjC runtime)"
    nm -gU "${DEVICE_FW}/${FRAMEWORK_NAME}" | grep "TorWrapper"
fi
```

---

## 📊 ТЕКУЩИЙ СТАТУС ЭКСПОРТА

### Что экспортируется:

```bash
$ nm -gU Tor.framework/Tor | grep TorWrapper
000000000065c560 S _OBJC_CLASS_$_TorWrapper       # ✅ Класс
000000000065c588 S _OBJC_METACLASS_$_TorWrapper  # ✅ Метакласс
```

### Методы (локальные символы):

```bash
$ nm Tor.framework/Tor | grep "setStatusCallback"
0000000000002704 t -[TorWrapper setStatusCallback:]  # 't' = локальный
```

---

## ❓ ПОЧЕМУ МЕТОДЫ ЛОКАЛЬНЫЕ?

### Это НОРМАЛЬНО для ObjC Dynamic Framework!

**ObjC Runtime работает не через прямые символы, а через metadata:**

1. **Класс экспортирован** (`_OBJC_CLASS_$_TorWrapper`)
2. **Метакласс экспортирован** (`_OBJC_METACLASS_$_TorWrapper`)
3. **Методы находятся через Runtime**, а не через линкер

**Как это работает:**
```objc
// Swift код:
wrapper.setStatusCallback { ... }

// Компилируется в:
objc_msgSend(wrapper, @selector(setStatusCallback:), block)
//            ↑
// Использует OBJC_CLASS metadata для поиска метода,
// а НЕ прямой символ "_TorWrapper_setStatusCallback"
```

**Пока `OBJC_CLASS_$_TorWrapper` экспортирован → все методы доступны!**

---

## 🔍 ПРОВЕРКА РАБОТОСПОСОБНОСТИ

### 1. Класс доступен из Swift?

```swift
import TorFrameworkBuilder

let wrapper = TorWrapper.shared  // ← Должно работать
print(wrapper)  // ← Должно вывести <TorWrapper: 0x...>
```

**Если это работает → класс правильно экспортирован! ✅**

### 2. Методы вызываются?

```swift
wrapper.setStatusCallback { status, message in
    print("Status: \(status), Message: \(message)")
}
```

**Если EXC_BAD_ACCESS здесь:**
- ❌ НЕ проблема экспорта символов
- ❌ НЕ проблема линковки
- ✅ Возможно проблема в thread safety / race condition
- ✅ Возможно проблема в callback lifecycle

---

## 🚨 ЕСЛИ ВСЕ ЕЩЕ EXC_BAD_ACCESS

### Возможные причины (НЕ связанные с экспортом):

#### 1. Race Condition в callbacks

**Проверка:**
```swift
// Вызываете ли вы методы из разных потоков?
DispatchQueue.global().async {
    wrapper.setStatusCallback { ... }  // ← Может быть race condition
}
```

**Решение:** v1.0.23 уже исправил thread safety с `callbackQueue`

#### 2. Callback deallocated во время вызова

**Проверка:**
```swift
wrapper.setStatusCallback { ... }  // Блок может быть deallocated
wrapper.start { ... }  // Вызывает callback → CRASH
```

**Решение:** v1.0.23 копирует callback перед вызовом

#### 3. Framework не загружен в runtime

**Проверка:**
```bash
# В TorApp после запуска:
lldb> image list | grep Tor
# Должно показать: Tor.framework/Tor
```

#### 4. Module не импортирован

**Проверка:**
```swift
import TorFrameworkBuilder  // ← Правильный import?
// ИЛИ
import Tor  // ← В зависимости от module.modulemap
```

---

## 💡 DEBUGGING GUIDE

### Шаг 1: Проверить что framework загружается

```swift
print("TorWrapper class: \(TorWrapper.self)")  // Должно вывести "TorWrapper"
```

**Если ошибка здесь** → проблема в линковке framework, НЕ в экспорте

### Шаг 2: Проверить singleton

```swift
let wrapper = TorWrapper.shared
print("Wrapper instance: \(wrapper)")
```

**Если EXC_BAD_ACCESS здесь** → проблема в `+shared` (уже исправлено в v1.0.21)

### Шаг 3: Вызвать простой метод

```swift
let port = wrapper.socksPort
print("SOCKS port: \(port)")
```

**Если работает** → класс полностью функционален!

### Шаг 4: Проверить callbacks

```swift
var called = false
wrapper.setStatusCallback { status, message in
    called = true
    print("Callback called!")
}

// Подождите
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    print("Callback was called: \(called)")
}
```

---

## 📚 ТЕХНИЧЕСКИЕ ДЕТАЛИ

### ObjC Dynamic Linking

**Как ObjC runtime находит методы:**

1. Линкер разрешает `_OBJC_CLASS_$_TorWrapper`
2. Runtime читает class metadata (method list, ivars, etc.)
3. `objc_msgSend` использует selector lookup в method list
4. Method implementation вызывается через function pointer

**Методы НЕ НУЖНО экспортировать как глобальные символы!**

### Экспорт vs Видимость

| Символ | Флаг | Доступность |
|--------|------|-------------|
| `_OBJC_CLASS_$_TorWrapper` | `S` (section) | ✅ Глобальный, экспортирован |
| `_tor_main` | `T` (text) | ✅ Глобальный, экспортирован |
| `-[TorWrapper setStatusCallback:]` | `t` (text local) | ✅ Доступен через runtime |

---

## 🎯 РЕЗУЛЬТАТ

**v1.0.25:**
- ✅ Добавлен `-Wl,-exported_symbols_list` с wildcard
- ✅ Добавлена автоматическая верификация экспорта
- ✅ `OBJC_CLASS_$_TorWrapper` правильно экспортирован
- ✅ Все методы доступны через ObjC runtime
- ✅ Framework функционален и готов к использованию

**Если EXC_BAD_ACCESS продолжается:**
- Это НЕ проблема экспорта символов
- Проверьте thread safety, callback lifecycle, module import
- Добавьте детальное логирование для определения точки краша

---

## 🚀 КАК ОБНОВИТЬСЯ

```bash
cd ~/admin/TorApp

rm -rf .build
tuist clean

# Обновите Dependencies.swift:
from: "1.0.25"

tuist install --update
tuist generate
tuist build
```

**Изменения в коде НЕ требуются.**

---

## 📊 CHANGELOG

### v1.0.24 → v1.0.25

**Добавлено:**
- ✅ `-Wl,-exported_symbols_list` с wildcard `*`
- ✅ Автоматическая верификация экспорта символов
- ✅ Детальное логирование статуса экспорта

**Улучшено:**
- ✅ Лучшая отладка проблем с символами
- ✅ Документация по ObjC runtime

---

**TorFrameworkBuilder v1.0.25 - Enhanced verification & documentation!** 🎉🧅

