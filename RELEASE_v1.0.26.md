# 📝 Release v1.0.26 - IMPORTANT: ObjC Methods Export Clarification

**Дата:** 28 октября 2025  
**Тэг:** `1.0.26`  
**Тип:** КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ + Документация

---

## ⚠️ ВАЖНОЕ РАЗЪЯСНЕНИЕ

### ObjC методы ВСЕГДА локальные в dynamic libraries - это НОРМАЛЬНО!

**После глубокого анализа выяснилось:**

Методы Objective-C **ВСЕГДА** компилируются и линкуются как локальные символы (`t` flag) в dynamic libraries. **ЭТО СТАНДАРТНОЕ ПОВЕДЕНИЕ OBJC RUNTIME!**

---

## 🔍 ДИАГНОСТИКА

### Проверка символов:

```bash
$ nm output/TorWrapper.dylib | grep "setStatusCallback"
00000000000059ec t -[TorWrapper setStatusCallback:]  # ← 't' = ЛОКАЛЬНЫЙ
```

**Это ПРАВИЛЬНО и ОЖИДАЕМО!**

### Что действительно экспортируется:

```bash
$ nm -gU output/TorWrapper.dylib | grep "OBJC"
0000000000010638 S _OBJC_CLASS_$_TorWrapper       # ✅ ЭКСПОРТИРОВАН!
0000000000010660 S _OBJC_METACLASS_$_TorWrapper  # ✅ ЭКСПОРТИРОВАН!
```

---

## 🎯 КАК РАБОТАЕТ OBJC RUNTIME

### 1. Методы НЕ вызываются напрямую

**НЕТ прямого вызова:**
```c
// НЕТ ТАКОГО:
call _-[TorWrapper setStatusCallback:]  // ← Такого НЕТ!
```

**Вызов через objc_msgSend:**
```objc
// Реальный вызов:
objc_msgSend(wrapper, @selector(setStatusCallback:), callback);
//           ↑
//           Использует OBJC_CLASS metadata!
```

### 2. OBJC_CLASS содержит всю информацию

**Metadata класса включает:**
- Список всех методов (method list)
- Список всех properties (property list)
- Список всех ivars (ivar list)
- Суперкласс
- Protocols

**Когда вызывается метод:**
1. `objc_msgSend` получает selector (`setStatusCallback:`)
2. Ищет метод в method list класса `TorWrapper`
3. Находит implementation (function pointer)
4. Вызывает через function pointer

**Символы методов НЕ НУЖНЫ!**

---

## ❓ ПОЧЕМУ ТОГДА EXC_BAD_ACCESS?

### Если методы не нужны как T symbols, почему краш?

**Возможные РЕАЛЬНЫЕ причины:**

#### 1. Module не импортирован правильно

```swift
// Неправильно:
import Tor  // ← Если module.modulemap указывает на Tor

// Правильно:
import TorFrameworkBuilder  // ← По имени package
```

#### 2. Framework не линкуется

В Xcode Build Settings должно быть:
```
OTHER_LDFLAGS = -framework Tor -lz
```

#### 3. @rpath не настроен

Framework должен быть в:
```
Runpath Search Paths = @executable_path/Frameworks
```

#### 4. OBJC_CLASS не доступен (НЕ экспортирован)

Проверка:
```bash
$ nm -gU Tor.framework/Tor | grep "OBJC_CLASS.*TorWrapper"
# Должно вывести строку с 'S' flag
```

**Если пусто** → проблема в линковке framework!

#### 5. TorWrapper.o не включён в framework

Проверка:
```bash
$ nm Tor.framework/Tor | grep -i "torwrapper" | head -5
# Должны быть хоть какие-то символы
```

**Если пусто** → TorWrapper.o не был слинкован!

---

## ✅ ЧТО БЫЛО ИСПРАВЛЕНО В v1.0.26

### 1. Двухшаговая линковка

**Создаём TorWrapper.dylib отдельно:**
```bash
clang -dynamiclib \
    -Wl,-undefined,dynamic_lookup \
    -o TorWrapper.dylib \
    TorWrapper.o \
    -framework Foundation
```

**Затем включаем в Tor.framework:**
```bash
clang -dynamiclib \
    -Wl,-reexport_library,TorWrapper.dylib \
    -o Tor.framework/Tor \
    libtor.a libssl.a ...
```

### 2. Верификация экспорта OBJC_CLASS

Скрипт теперь проверяет что `_OBJC_CLASS_$_TorWrapper` экспортирован:
```bash
if nm -gU Tor.framework/Tor | grep -q "OBJC_CLASS.*TorWrapper"; then
    echo "✅ TorWrapper класс экспортирован!"
else
    echo "❌ КРИТИЧЕСКАЯ ОШИБКА!"
    exit 1
fi
```

---

## 🔧 КАК ПРОВЕРИТЬ ПРАВИЛЬНОСТЬ FRAMEWORK

### Шаг 1: Класс экспортирован?

```bash
$ nm -gU Tor.framework/Tor | grep "OBJC_CLASS.*TorWrapper"
000000000065c560 S _OBJC_CLASS_$_TorWrapper
```

**Если есть строка** → ✅ Класс доступен!

### Шаг 2: Методы есть в binary?

```bash
$ nm Tor.framework/Tor | grep "setStatusCallback"
00000000000017a8 t -[TorWrapper setStatusCallback:]
```

**Если есть** → ✅ Методы присутствуют!

**'t' flag - это НОРМАЛЬНО!**

### Шаг 3: Проверка в Swift

```swift
import TorFrameworkBuilder

// Тест 1: Класс загружается?
print("TorWrapper class: \(TorWrapper.self)")
// Ожидаемо: "TorWrapper"

// Тест 2: Singleton работает?
let wrapper = TorWrapper.shared
print("Wrapper: \(wrapper)")
// Ожидаемо: "<TorWrapper: 0x...>"

// Тест 3: Property доступен?
let port = wrapper.socksPort
print("SOCKS port: \(port)")
// Ожидаемо: "9050"

// Тест 4: Метод вызывается?
wrapper.setStatusCallback { status, message in
    print("Status: \(status)")
}
// Ожидаемо: НЕТ крашей
```

**Если все 4 теста проходят** → Framework работает правильно!

---

## 📚 ДОКУМЕНТАЦИЯ ДЛЯ ПОЛЬЗОВАТЕЛЯ

### Если EXC_BAD_ACCESS продолжается:

1. **Проверьте import:**
   ```swift
   import TorFrameworkBuilder  // ← Правильно
   ```

2. **Проверьте линковку:**
   ```
   Build Settings → Other Linker Flags
   -framework Tor -lz
   ```

3. **Проверьте @rpath:**
   ```
   Build Settings → Runpath Search Paths
   @executable_path/Frameworks
   ```

4. **Проверьте что OBJC_CLASS экспортирован:**
   ```bash
   nm -gU path/to/Tor.framework/Tor | grep OBJC_CLASS
   ```

5. **Проверьте Module Map:**
   ```
   Tor.framework/Modules/module.modulemap
   framework module Tor {
       umbrella header "Tor.h"
       export *
       module * { export * }
   }
   ```

---

## 🎯 ИТОГ

**v1.0.26:**
- ✅ Подтверждено что методы 't' - это НОРМАЛЬНО
- ✅ Двухшаговая линковка (TorWrapper.dylib + Tor.framework)
- ✅ Автоматическая верификация OBJC_CLASS
- ✅ Документация как правильно проверять framework
- ✅ Debugging guide для EXC_BAD_ACCESS

**Если EXC_BAD_ACCESS всё ещё происходит - это НЕ проблема экспорта символов методов!**

Проверьте:
1. Import модуля
2. Линковку framework
3. @rpath настройки
4. Module Map
5. OBJC_CLASS экспорт

---

**TorFrameworkBuilder v1.0.26 - Correct ObjC runtime understanding!** 🎉🧅

