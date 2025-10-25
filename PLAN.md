# План компиляции Tor для iOS

## Статус выполнения

### Фаза 1: Подготовка ✅
- [x] Установка brew tools
- [x] Создание структуры проекта
- [x] Инициализация git

### Фаза 2: Создание скриптов сборки
- [ ] download_tor.sh - скачивание исходников
- [ ] build_openssl.sh - сборка OpenSSL 3.4.0
- [ ] build_libevent.sh - сборка libevent 2.1.12
- [ ] build_xz.sh - сборка xz 5.6.3
- [ ] build_tor.sh - сборка Tor 0.4.8.19
- [ ] build_all.sh - мастер-скрипт

### Фаза 3: Сборка зависимостей
- [ ] OpenSSL скомпилирован
- [ ] libevent скомпилирован
- [ ] xz скомпилирован
- [ ] Tor скомпилирован

### Фаза 4: Создание XCFramework
- [ ] create_xcframework.sh - объединение библиотек
- [ ] Создание framework структуры
- [ ] Копирование headers

### Фаза 5: Objective-C Wrapper
- [ ] TorWrapper.h - интерфейс
- [ ] TorWrapper.m - реализация
- [ ] Tor.h - umbrella header
- [ ] module.modulemap

### Фаза 6: Интеграция
- [ ] deploy.sh - копирование в TorApp
- [ ] Обновление Project.swift
- [ ] Обновление TorService.swift
- [ ] Тестирование

## Временные затраты

- Создание скриптов: 1-2 часа
- Первая сборка: 1-2 часа
- Создание XCFramework: 30 минут
- Wrapper: 2-3 часа
- Интеграция и тесты: 2-3 часа

**Итого: 1-2 дня активной работы**

## Версии компонентов

- Tor: 0.4.8.19 (stable)
- OpenSSL: 3.4.0
- libevent: 2.1.12-stable
- xz: 5.6.3
- Target: iOS 16.0+, arm64

## Ссылки

- Tor: https://dist.torproject.org/
- OpenSSL: https://www.openssl.org/source/
- libevent: https://libevent.org/
- xz: https://github.com/tukaani-project/xz
