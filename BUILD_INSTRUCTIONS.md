# Инструкция по сборке Tor Framework для iOS

## 📋 Что уже создано

Все необходимые скрипты и wrapper'ы уже созданы и готовы к использованию:

### Скрипты сборки (scripts/)
- ✅ `download_tor.sh` - скачивание Tor (уже скачан)
- ✅ `build_openssl.sh` - сборка OpenSSL 3.4.0
- ✅ `build_libevent.sh` - сборка libevent 2.1.12
- ✅ `build_xz.sh` - сборка xz 5.6.3
- ✅ `build_tor.sh` - сборка Tor 0.4.8.19
- ✅ `build_all.sh` - мастер-скрипт для полной сборки
- ✅ `create_xcframework.sh` - создание XCFramework
- ✅ `deploy.sh` - деплой в TorApp

### Wrapper файлы (wrapper/)
- ✅ `TorWrapper.h` - Objective-C интерфейс
- ✅ `TorWrapper.m` - Objective-C реализация
- ✅ `Tor.h` - Umbrella header
- ✅ `module.modulemap` - Module map

## 🚀 Быстрый старт

### Шаг 1: Полная сборка

Запустите мастер-скрипт, который соберет все компоненты:

```bash
bash scripts/build_all.sh
```

Этот скрипт последовательно:
1. Соберет OpenSSL 3.4.0 для iOS arm64
2. Соберет libevent 2.1.12 для iOS arm64
3. Соберет xz 5.6.3 для iOS arm64
4. Соберет Tor 0.4.8.19 для iOS arm64

⏱️ **Время сборки**: ~1-2 часа (в зависимости от машины)

### Шаг 2: Создание XCFramework

После успешной сборки создайте XCFramework:

```bash
bash scripts/create_xcframework.sh
```

Это объединит все статические библиотеки в один `Tor.xcframework`

### Шаг 3: Деплой в TorApp

Скопируйте готовый framework в ваш проект:

```bash
bash scripts/deploy.sh
```

## 📦 Результаты сборки

После выполнения всех шагов у вас будут:

```
output/
├── openssl/          # OpenSSL библиотеки и headers
├── libevent/         # libevent библиотеки и headers
├── xz/               # xz библиотеки и headers
├── tor/              # Tor бинарники
└── Tor.xcframework/  # Готовый XCFramework
```

## 🛠️ Требования

### Необходимые инструменты (должны быть установлены):
- ✅ Xcode (с командными инструментами)
- ✅ Homebrew
- ✅ autoconf, automake, libtool
- ✅ pkg-config
- ✅ wget
- ✅ cmake

Проверьте установку:
```bash
xcodebuild -version
brew --version
autoconf --version
automake --version
libtool --version
pkg-config --version
wget --version
cmake --version
```

## 🔧 Ручная сборка (если нужно)

Если хотите собрать компоненты по отдельности:

```bash
# 1. OpenSSL
bash scripts/build_openssl.sh

# 2. libevent
bash scripts/build_libevent.sh

# 3. xz
bash scripts/build_xz.sh

# 4. Tor
bash scripts/build_tor.sh

# 5. XCFramework
bash scripts/create_xcframework.sh

# 6. Деплой
bash scripts/deploy.sh
```

## 📝 Интеграция в TorApp

После деплоя добавьте в ваш Swift код:

```swift
import Tor

// Запуск Tor
let tor = TorWrapper.shared()
tor.start { success, error in
    if success {
        print("✅ Tor запущен!")
        print("🌐 SOCKS proxy: \(tor.socksProxyURL())")
    } else {
        print("❌ Ошибка: \(error?.localizedDescription ?? "Unknown")")
    }
}

// Настройка URLSession для использования Tor
let config = URLSessionConfiguration.default
config.connectionProxyDictionary = [
    kCFNetworkProxiesSOCKSEnable: true,
    kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
    kCFNetworkProxiesSOCKSPort: tor.socksPort
]
let session = URLSession(configuration: config)
```

## 🐛 Устранение неполадок

### Ошибка: SDK не найден
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Ошибка: command not found (autoconf, etc.)
```bash
brew install autoconf automake libtool pkg-config wget cmake
```

### Ошибка при сборке OpenSSL
Убедитесь, что используется правильная версия Xcode:
```bash
xcode-select -p
```

### Ошибка при линковке
Проверьте, что все библиотеки собраны:
```bash
ls -la output/*/lib/*.a
```

## 📊 Размеры

Примерные размеры результатов:

- OpenSSL: ~5 MB (libssl.a + libcrypto.a)
- libevent: ~1 MB
- xz: ~500 KB
- Tor: ~2 MB
- **Итого XCFramework**: ~8-10 MB

## 🔄 Пересборка

Для полной пересборки:

```bash
# Очистка
rm -rf build/ output/ sources/

# Полная сборка с нуля
bash scripts/build_all.sh
bash scripts/create_xcframework.sh
```

## 📚 Версии компонентов

- **Tor**: 0.4.8.19 (stable)
- **OpenSSL**: 3.4.0
- **libevent**: 2.1.12-stable
- **xz**: 5.6.3
- **Target**: iOS 16.0+, arm64

## 🎯 Следующие шаги

1. ✅ Запустить сборку: `bash scripts/build_all.sh`
2. ✅ Создать XCFramework: `bash scripts/create_xcframework.sh`
3. ✅ Деплой: `bash scripts/deploy.sh`
4. ⏳ Интегрировать в TorApp
5. ⏳ Протестировать

## 📖 Дополнительные ресурсы

- [Tor Project](https://www.torproject.org/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [libevent Documentation](https://libevent.org/)
- [iOS Framework Development](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/)

## 💡 Полезные команды

```bash
# Проверить архитектуру библиотеки
lipo -info output/openssl/lib/libssl.a

# Посмотреть символы в библиотеке
nm output/openssl/lib/libssl.a | grep SSL_new

# Размер framework
du -sh output/Tor.xcframework

# Список всех заголовочных файлов
find output/Tor.xcframework -name "*.h"
```

---

✅ **Готово!** Теперь вы можете собрать Tor Framework для iOS!

