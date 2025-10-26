# 🚀 Быстрый старт

Tor исходники уже скачаны. Все скрипты готовы к запуску.

## ⚡ Три команды для полной сборки

```bash
# 1. Сборка всех компонентов (1-2 часа)
bash scripts/build_all.sh

# 2. Создание XCFramework (5 минут)
bash scripts/create_xcframework.sh

# 3. Деплой в TorApp (мгновенно)
bash scripts/deploy.sh
```

Готово! 🎉

## 📋 Что будет собрано

- OpenSSL 3.4.0
- libevent 2.1.12-stable
- xz 5.6.3
- Tor 0.4.8.19
- **Tor.xcframework** (готовый к использованию)

## 📚 Подробная документация

- `BUILD_INSTRUCTIONS.md` - полная инструкция
- `STATUS.md` - текущий статус проекта
- `PLAN.md` - план выполнения

## 💡 Одна команда для всего

```bash
bash scripts/build_all.sh && \
bash scripts/create_xcframework.sh && \
bash scripts/deploy.sh
```

---

🎯 **Начните прямо сейчас**: `bash scripts/build_all.sh`

