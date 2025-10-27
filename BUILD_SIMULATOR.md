# 🔧 Сборка для iOS Simulator

## Проблема

Текущий Tor.xcframework работает только на **реальных устройствах** (ios-arm64).

При попытке собрать на **симуляторе** появляется ошибка:
```
While building for iOS Simulator, no library for this platform was found in '/path/to/Tor.xcframework'
```

## Решение

Создать **универсальный XCFramework** с поддержкой обеих платформ:
- `ios-arm64` - для реальных устройств
- `ios-arm64-simulator` - для iOS Simulator

---

## 🚀 Быстрая сборка (3 шага)

```bash
cd ~/admin/TorFrameworkBuilder

# 1. Собрать зависимости для симулятора (~30 минут)
bash scripts/build_all_simulator.sh

# 2. Собрать Tor для симулятора (~5 минут)
bash scripts/build_tor_simulator.sh

# 3. Создать универсальный XCFramework (~1 минута)
bash scripts/create_xcframework_universal.sh
```

**Итого**: ~40 минут

**Результат**: `output/Tor.xcframework` с поддержкой device + simulator!

---

## 📊 Что произойдет

### До:
```
Tor.xcframework/
└── ios-arm64/           ← Только устройства
    └── Tor.framework/
```

### После:
```
Tor.xcframework/
├── ios-arm64/                  ← Устройства
│   └── Tor.framework/
└── ios-arm64-simulator/        ← Симулятор ✅
    └── Tor.framework/
```

---

## ⚙️ Пошаговая сборка

### Шаг 1: Зависимости для симулятора

```bash
# OpenSSL
bash scripts/build_openssl_simulator.sh

# libevent
bash scripts/build_libevent_simulator.sh

# xz
bash scripts/build_xz_simulator.sh
```

Или все сразу:
```bash
bash scripts/build_all_simulator.sh
```

⏱️ **Время**: ~30 минут

### Шаг 2: Tor для симулятора

```bash
bash scripts/build_tor_simulator.sh
```

⏱️ **Время**: ~5 минут

### Шаг 3: Универсальный XCFramework

```bash
bash scripts/create_xcframework_universal.sh
```

⏱️ **Время**: ~1 минута

---

## ✅ Проверка результата

```bash
# Структура
ls -la output/Tor.xcframework/
# Должно быть: ios-arm64/ и ios-arm64-simulator/

# Архитектуры устройства
lipo -info output/Tor.xcframework/ios-arm64/Tor.framework/Tor
# Ожидается: arm64

# Архитектуры симулятора
lipo -info output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor
# Ожидается: arm64

# Проверка в Info.plist
cat output/Tor.xcframework/Info.plist | grep -A2 "LibraryIdentifier"
# Должно быть два: ios-arm64 и ios-arm64-simulator
```

---

## 🔄 Обновление в TorApp

После создания универсального XCFramework:

```bash
# 1. Коммит в TorFrameworkBuilder
git add output/Tor.xcframework
git commit -m "Add iOS Simulator support"
git tag v1.0.3
git push --tags
git push

# 2. Обновление в TorApp
cd ~/admin/TorApp
tuist clean
tuist fetch --update
tuist generate

# 3. Тест на симуляторе
# Выбрать iPhone Simulator в Xcode
# Cmd+B - должна пройти компиляция ✅
```

---

## 📱 Размеры

### До (только устройства):
```
Tor.xcframework:  28 MB
```

### После (device + simulator):
```
Tor.xcframework:  ~55 MB (28 MB device + 27 MB simulator)
```

**Важно**: При загрузке в App Store Xcode **автоматически исключит** симулятор.

Финальный IPA: **~28 MB** (без изменений!)

---

## 🎯 Зачем это нужно?

- ✅ Тестирование на симуляторе (быстрее чем на устройстве)
- ✅ CI/CD на GitHub Actions (нет реальных устройств)
- ✅ Разработка без физического iPhone
- ✅ Debugging в Xcode на симуляторе

---

## ⚠️ Важно

После создания универсального XCFramework:
- Git размер: увеличится с ~30 MB до ~60 MB
- TorApp на устройстве: без изменений (~28 MB)
- TorApp в Git LFS: ~55 MB

**Это стандартная практика** - все Apple frameworks работают так же.

---

## 🚀 Готово!

После выполнения сборки запустите:
```bash
tuist fetch --update
tuist generate
```

И сможете тестировать на симуляторе! ✅

