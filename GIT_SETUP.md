# 🚀 Быстрая настройка Git для приватного репозитория

## Шаг 1: Подготовка к коммиту

```bash
cd ~/admin/TorFrameworkBuilder

# Проверка статуса
git status

# Добавление всех файлов
git add .

# Проверка что будет закоммичено
git status
```

## Шаг 2: Создание коммита

```bash
git commit -m "🎉 Tor Framework для iOS готов к использованию

✅ Что включено:
- Tor 0.4.8.19 (123 модуля скомпилированы)
- OpenSSL 3.4.0
- libevent 2.1.12-stable
- xz/lzma 5.6.3
- Swift Package Manager ready
- Objective-C wrapper с TorWrapper
- Swift wrapper с TorService
- Полная документация и руководства

📦 Структура:
- output/Tor.xcframework - готовый framework
- Package.swift - SPM манифест
- Sources/Tor - Swift интерфейс
- wrapper/ - Objective-C wrapper
- Скрипты для сборки и обновления

📚 Документация:
- README_PACKAGE.md - использование
- INTEGRATION_GUIDE.md - интеграция с Tuist
- SUCCESS.md - процесс сборки
- GIT_SETUP.md - этот файл

🎯 Готов к использованию через Tuist в приватном репозитории!"
```

## Шаг 3: Создание приватного репозитория на GitHub

### 3.1 Через веб-интерфейс:

1. Перейти: https://github.com/new
2. Repository name: `TorFrameworkBuilder` (или свое название)
3. Description: `Tor Framework для iOS (arm64) - Private`
4. **Visibility: Private** ⭐ ВАЖНО!
5. **НЕ добавляйте**: README, .gitignore, license (уже есть)
6. Click "Create repository"

### 3.2 Или через GitHub CLI:

```bash
# Установка gh (если нет)
brew install gh

# Авторизация
gh auth login

# Создание приватного репозитория
gh repo create TorFrameworkBuilder --private --source=. --remote=origin
```

## Шаг 4: Настройка Git LFS

```bash
# Установка Git LFS
brew install git-lfs

# Инициализация
git lfs install

# Проверка tracked файлов
git lfs track

# Должно показать:
# Listing tracked patterns
#     output/Tor.xcframework/** (.gitattributes)
#     *.tar.gz (.gitattributes)
```

## Шаг 5: Push в репозиторий

```bash
# Добавление remote (если создавали вручную на GitHub)
git remote add origin https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git

# Или если использовали gh:
# remote уже добавлен автоматически

# Проверка remote
git remote -v

# Push
git branch -M main
git push -u origin main
```

## Шаг 6: Проверка

```bash
# Проверить что все залилось
gh repo view --web

# Или откройте в браузере:
# https://github.com/YOUR_USERNAME/TorFrameworkBuilder
```

## ⚠️ Важно для больших файлов

XCFramework (~28MB) будет загружен через Git LFS.

Проверка:
```bash
# После push проверьте размер репозитория
gh repo view --json diskUsage

# LFS файлы
git lfs ls-files
```

## 🔐 Personal Access Token для Tuist

Для использования приватного репозитория в Tuist нужен PAT:

### Создание PAT:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. "Generate new token (classic)"
3. Scopes: `repo` (полный доступ к приватным репозиториям)
4. Скопируйте токен

### Настройка в Tuist:

```bash
# Экспортировать переменную окружения
export TUIST_CONFIG_GITHUB_TOKEN="ghp_YOUR_TOKEN_HERE"

# Или добавить в ~/.zshrc
echo 'export TUIST_CONFIG_GITHUB_TOKEN="ghp_YOUR_TOKEN_HERE"' >> ~/.zshrc
source ~/.zshrc
```

## 🎉 Готово!

Теперь ваш TorFramework доступен как приватный Swift Package для Tuist!

### Использование в TorApp:

```swift
// Tuist/Dependencies.swift
let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(
            url: "https://github.com/YOUR_USERNAME/TorFrameworkBuilder.git",
            requirement: .branch("main")
        )
    ]
)
```

### Команды:

```bash
cd ~/admin/TorApp
tuist fetch
tuist generate
open TorApp.xcworkspace
```

## 🔄 Обновление в будущем

```bash
cd ~/admin/TorFrameworkBuilder

# После изменений
git add .
git commit -m "Update: описание изменений"
git push

# В TorApp
cd ~/admin/TorApp
tuist fetch --update
tuist generate
```

