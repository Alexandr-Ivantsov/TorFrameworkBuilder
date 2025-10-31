# План реализации CI/CD подхода для Tor.xcframework

## Цель
Автоматизировать сборку правильного `Tor.xcframework` через GitHub Actions, который:
- Не содержит OpenSSL/Libevent headers в публичных Headers/
- Не имеет module.modulemap с `export *`
- Содержит iOS патч в бинарнике
- Работает в TorApp без ошибок `dns_sd.h`

---

## Разделение задач

### ЧАСТЬ 1: Подготовка и проверка (ВЫ делаете)

#### Шаг 1.1: Проверка наличия iOS патча
**Действие:**
```bash
cd /Users/aleksandrivancov/admin/TorFrameworkBuilder
grep -n "iOS PATCH" Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c
```

**Ожидаемый результат:**
Должны увидеть строки 183-197 с комментарием `/* iOS PATCH: Platform doesn't support non-inheritable memory (iOS). */`

**Если патча нет:**
```bash
./scripts/apply_patches.sh
```

**Файл для проверки:**
- `Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c` (строки 183-197)

---

#### Шаг 1.2: Проверка GitHub репозитория
**Действие:**
1. Открыть https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder
2. Проверить что Git LFS включен:
   - Settings → Git LFS
   - Должно быть видно что `.gitattributes` уже настроен для `output/Tor.xcframework/**`

**Текущий `.gitattributes`:**
```
output/Tor.xcframework/** filter=lfs diff=lfs merge=lfs -text
```

**Если LFS не настроен:**
```bash
git lfs install
git lfs track "output/Tor.xcframework/**"
git add .gitattributes
git commit -m "Add Git LFS tracking for XCFramework"
git push
```

---

#### Шаг 1.3: Проверка зависимостей в output/
**Действие:**
Проверить что существуют собранные зависимости:
```bash
ls -la output/openssl/lib/libssl.a
ls -la output/openssl/lib/libcrypto.a
ls -la output/libevent/lib/libevent.a
ls -la output/xz/lib/liblzma.a
```

**Если их нет (для device):**
- Можно использовать существующие скрипты: `scripts/build_openssl.sh`, `scripts/build_libevent.sh`, `scripts/build_xz.sh`
- Или они будут собраны в CI/CD (см. шаг 2.3)

**Если их нет (для simulator):**
- Скрипты: `scripts/build_openssl_simulator.sh`, `scripts/build_libevent_simulator.sh`, `scripts/build_xz_simulator.sh`

---

### ЧАСТЬ 2: Создание правильного скрипта сборки (Я делаю)

#### Шаг 2.1: Создать скрипт проверки патча перед сборкой
**Файл:** `scripts/verify_patch_before_build.sh`

**Содержимое:**
```bash
#!/bin/bash
set -e

PATCH_FILE="Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c"
PATCH_MARKER="iOS PATCH"

if ! grep -q "$PATCH_MARKER" "$PATCH_FILE"; then
    echo "❌ ERROR: iOS patch not found in $PATCH_FILE"
    echo "   Run: ./scripts/apply_patches.sh"
    exit 1
fi

echo "✅ iOS patch verified in $PATCH_FILE"
```

**Что делает:**
- Проверяет наличие патча перед началом сборки
- Останавливает CI/CD если патча нет

---

#### Шаг 2.2: Создать правильный скрипт сборки XCFramework
**Файл:** `scripts/build_correct_xcframework.sh`

**Основные отличия от `create_xcframework_universal.sh`:**
1. **НЕ копировать** OpenSSL headers в `Headers/`
2. **НЕ копировать** Libevent headers в `Headers/`
3. **НЕ создавать** `module.modulemap` или создать минимальный БЕЗ `export *`
4. Использовать только `wrapper/Tor.h` и `wrapper/TorWrapper.h` в публичных headers

**Структура правильного XCFramework:**
```
output/Tor.xcframework/
├── Info.plist
├── ios-arm64/
│   └── Tor.framework/
│       ├── Headers/
│       │   ├── Tor.h              ← ТОЛЬКО этот
│       │   └── TorWrapper.h       ← И этот
│       ├── Modules/                ← ПУСТО или минимальный modulemap
│       ├── Info.plist
│       └── Tor                    ← Binary с патчем
└── ios-arm64-simulator/
    └── Tor.framework/
        ├── Headers/
        │   ├── Tor.h
        │   └── TorWrapper.h
        ├── Modules/
        ├── Info.plist
        └── Tor
```

**Ключевые команды в скрипте:**
```bash
# Копировать ТОЛЬКО wrapper headers
cp wrapper/Tor.h "${DEVICE_FW}/Headers/"
cp wrapper/TorWrapper.h "${DEVICE_FW}/Headers/"

# НЕ копировать OpenSSL/Libevent headers:
# ❌ cp -R output/openssl/include/openssl/* Headers/
# ❌ cp -R output/libevent/include/* Headers/

# НЕ создавать module.modulemap с export *:
# ❌ echo "framework module Tor { export * }" > Modules/module.modulemap
```

---

#### Шаг 2.3: Создать скрипт сборки зависимостей (если нужен)
**Файл:** `scripts/build_dependencies.sh`

**Что делает:**
- Проверяет наличие `output/openssl/lib/libssl.a`
- Если нет - запускает `scripts/build_openssl.sh`
- Аналогично для libevent и xz

**Альтернатива:**
- Можно хранить предсобранные зависимости в репозитории
- Или собирать их в CI/CD при каждом запуске

---

### ЧАСТЬ 3: GitHub Actions workflow (Я создаю, ВЫ настраиваете)

#### Шаг 3.1: Создать файл GitHub Actions workflow
**Файл:** `.github/workflows/build-xcframework.yml`

**Триггеры:**
```yaml
on:
  push:
    tags:
      - 'v*'  # Запуск при создании тега v1.0.XX
  workflow_dispatch:  # Ручной запуск из GitHub UI
```

**Основные шаги:**
1. Checkout с LFS
2. Setup Xcode
3. Запуск `verify_patch_before_build.sh`
4. Сборка зависимостей (если нужно)
5. Сборка Tor (device + simulator)
6. Создание XCFramework через `build_correct_xcframework.sh`
7. Проверка структуры XCFramework
8. Коммит XCFramework в репозиторий (или upload artifact)

**Пример структуры:**
```yaml
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v3
        with:
          lfs: true
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'
      
      - name: Verify iOS patch
        run: ./scripts/verify_patch_before_build.sh
      
      - name: Build dependencies (if needed)
        run: ./scripts/build_dependencies.sh
      
      - name: Build Tor for device
        run: ./scripts/direct_build.sh
      
      - name: Build Tor for simulator
        run: ./scripts/build_tor_simulator.sh
      
      - name: Create correct XCFramework
        run: ./scripts/build_correct_xcframework.sh
      
      - name: Verify XCFramework structure
        run: |
          # Проверка что нет OpenSSL headers
          if [ -d "output/Tor.xcframework/ios-arm64/Tor.framework/Headers/openssl" ]; then
            echo "❌ ERROR: OpenSSL headers found in public Headers/"
            exit 1
          fi
      
      - name: Commit XCFramework
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add output/Tor.xcframework
          git commit -m "Build XCFramework from tag ${{ github.ref_name }}" || exit 0
          git push
```

---

#### Шаг 3.2: Настройка GitHub репозитория (ВЫ делаете)
**Действие:**
1. Убедиться что workflow файл создан в `.github/workflows/build-xcframework.yml`
2. Создать тестовый тег для проверки:
   ```bash
   git tag v1.0.99-test
   git push origin v1.0.99-test
   ```
3. Проверить что workflow запустился:
   - Открыть https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder/actions
   - Должен появиться workflow "Build XCFramework"

**Если workflow не запустился:**
- Проверить что файл находится в правильной ветке (main/master)
- Проверить синтаксис YAML

---

### ЧАСТЬ 4: Обновление Package.swift (Я делаю)

#### Шаг 4.1: Добавить binaryTarget в Package.swift
**Файл:** `Package.swift`

**Изменения:**
1. Добавить `.binaryTarget` после существующих targets:
```swift
.binaryTarget(
    name: "TorBinary",
    path: "output/Tor.xcframework"
)
```

2. Изменить product `TorFrameworkBuilder` чтобы использовать binary:
```swift
products: [
    .library(
        name: "TorFrameworkBuilder",
        type: .static,
        targets: ["TorBinary"]  // ← Изменить с "Tor" на "TorBinary"
    )
]
```

3. Либо создать два продукта (source для разработки, binary для использования):
```swift
products: [
    .library(
        name: "TorFrameworkBuilder",
        type: .static,
        targets: ["TorBinary"]
    ),
    .library(
        name: "TorFrameworkBuilderSource",
        type: .static,
        targets: ["Tor"]
    )
]
```

**Важно:**
- `.binaryTarget` требует что `output/Tor.xcframework` существует в репозитории
- После первого успешного CI/CD билда XCFramework будет закоммичен

---

#### Шаг 4.2: Обновить .gitignore (если нужно)
**Файл:** `.gitignore`

**Проверить что:**
- `output/Tor.xcframework` НЕ в `.gitignore` (должен быть в Git LFS)
- Временные файлы сборки в `.gitignore`:
  ```
  build/
  output/device/
  output/simulator/
  output/device-obj/
  ```

---

### ЧАСТЬ 5: Тестирование (ВЫ делаете)

#### Шаг 5.1: Тест CI/CD сборки
**Действие:**
1. После создания workflow файла создать тестовый тег:
   ```bash
   git tag v1.0.99-test
   git push origin v1.0.99-test
   ```

2. Отследить выполнение:
   - https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder/actions
   - Дождаться завершения workflow

3. Проверить результат:
   ```bash
   git pull
   ls -la output/Tor.xcframework/
   ```

**Ожидаемый результат:**
- Workflow завершился успешно
- `output/Tor.xcframework` обновлён
- В `Headers/` только `Tor.h` и `TorWrapper.h`
- Нет `openssl/` и `event2/` директорий в `Headers/`

---

#### Шаг 5.2: Тест интеграции в TorApp
**Действие:**
1. В проекте TorApp обновить версию в `Tuist/Dependencies.swift`:
   ```swift
   .remote(
       url: "https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder.git",
       requirement: .exact("1.0.99-test")  // Или .upToNextMajor(from: "1.0.99")
   )
   ```

2. Обновить зависимости:
   ```bash
   cd /Users/aleksandrivancov/admin/TorApp
   tuist fetch --update
   ```

3. Сгенерировать проект:
   ```bash
   tuist generate
   ```

4. Собрать проект:
   ```bash
   tuist build
   ```

**Ожидаемый результат:**
- ✅ `tuist fetch` успешно загрузил пакет
- ✅ `tuist build` завершился БЕЗ ошибок `dns_sd.h`
- ✅ Проект компилируется успешно

**Если есть ошибки:**
- Сообщить мне - я исправлю workflow или скрипты

---

### ЧАСТЬ 6: Документация (Я делаю)

#### Шаг 6.1: Обновить README.md
**Файл:** `README.md`

**Добавить секцию:**
```markdown
## CI/CD Build Process

Tor.xcframework автоматически собирается через GitHub Actions при создании тега.

### Как создать новый релиз:

1. Убедитесь что все изменения закоммичены
2. Создайте тег:
   ```bash
   git tag v1.0.XX
   git push origin v1.0.XX
   ```
3. GitHub Actions автоматически соберёт XCFramework
4. Проверьте результат в https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder/actions

### Структура XCFramework:

Правильный XCFramework содержит только необходимые headers:
- `Tor.h` - umbrella header
- `TorWrapper.h` - Objective-C API

OpenSSL и Libevent headers НЕ включены в публичные Headers/ для предотвращения header pollution.
```

---

#### Шаг 6.2: Создать CI_CD_GUIDE.md
**Файл:** `CI_CD_GUIDE.md`

**Содержимое:**
- Подробное описание процесса CI/CD
- Troubleshooting секция
- Как проверить что сборка правильная
- Как исправить проблемы

---

## Последовательность выполнения

### Фаза 1: Подготовка (ВЫ)
1. ✅ Проверить патч в `Sources/Tor/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c`
2. ✅ Проверить Git LFS в GitHub репозитории
3. ✅ Проверить наличие зависимостей в `output/`

### Фаза 2: Создание скриптов (Я)
4. ✅ Создать `scripts/verify_patch_before_build.sh`
5. ✅ Создать `scripts/build_correct_xcframework.sh`
6. ✅ Создать `scripts/build_dependencies.sh` (опционально)

### Фаза 3: CI/CD (Я создаю, ВЫ настраиваете)
7. ✅ Создать `.github/workflows/build-xcframework.yml`
8. ✅ Вы: Создать тестовый тег `v1.0.99-test` и проверить запуск workflow

### Фаза 4: Обновление Package.swift (Я)
9. ✅ Добавить `.binaryTarget` в `Package.swift`
10. ✅ Изменить product зависимость на binary target

### Фаза 5: Тестирование (ВЫ)
11. ✅ Протестировать CI/CD сборку
12. ✅ Протестировать интеграцию в TorApp

### Фаза 6: Документация (Я)
13. ✅ Обновить `README.md`
14. ✅ Создать `CI_CD_GUIDE.md`

---

## Критические моменты

### Что ДОЛЖНО быть в правильном XCFramework:
- ✅ Binary с применённым iOS патчем
- ✅ Только `Tor.h` и `TorWrapper.h` в `Headers/`
- ✅ НЕТ `module.modulemap` или минимальный БЕЗ `export *`
- ✅ Правильная структура для iOS device + simulator

### Что НЕ ДОЛЖНО быть:
- ❌ `output/Tor.xcframework/ios-arm64/Tor.framework/Headers/openssl/`
- ❌ `output/Tor.xcframework/ios-arm64/Tor.framework/Headers/event2/`
- ❌ `module.modulemap` с `framework module Tor { export * }`
- ❌ Глобальные макросы из OpenSSL/Libevent в публичных headers

---

## Ожидаемый результат

После выполнения всех шагов:
1. При создании тега `v1.0.XX` автоматически запускается GitHub Actions
2. Создаётся правильный `Tor.xcframework` БЕЗ header pollution
3. XCFramework коммитится в репозиторий через Git LFS
4. В `Package.swift` есть `.binaryTarget` который используется по умолчанию
5. TorApp успешно компилируется БЕЗ ошибок `dns_sd.h`
6. Процесс полностью автоматизирован и воспроизводим

---

## Troubleshooting

### Проблема: Workflow не запускается
**Решение:**
- Проверить что файл в правильной ветке (main/master)
- Проверить синтаксис YAML (можно проверить онлайн валидатором)

### Проблема: Git LFS не работает в CI
**Решение:**
- Убедиться что `lfs: true` в checkout action
- Проверить что `.gitattributes` содержит правильные пути

### Проблема: XCFramework всё ещё содержит OpenSSL headers
**Решение:**
- Проверить скрипт `build_correct_xcframework.sh`
- Убедиться что команды копирования OpenSSL headers закомментированы/удалены

### Проблема: TorApp всё ещё получает ошибки dns_sd.h
**Решение:**
- Проверить что `module.modulemap` не содержит `export *`
- Проверить что в `Headers/` нет OpenSSL/Libevent headers
- Проверить что используется `.binaryTarget` а не source target


