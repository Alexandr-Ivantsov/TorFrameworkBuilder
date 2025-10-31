# Настройка автоматического запуска GitHub Actions

## Проблема

GitHub Actions workflow требует ручного одобрения при первом запуске из-за настроек безопасности репозитория.

## Решение

### Шаг 1: Настройка разрешений в GitHub

1. Откройте репозиторий: https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder
2. Перейдите в **Settings → Actions → General**
3. В секции **"Workflow permissions"** выберите:
   - ✅ **"Read and write permissions"**
   - ✅ Отметьте **"Allow GitHub Actions to create and approve pull requests"**
4. В секции **"Actions** → **General"** убедитесь что:
   - ✅ **"Allow all actions and reusable workflows"** включено
5. Нажмите **"Save"**

### Шаг 2: Проверка workflow файла

Убедитесь что файл `.github/workflows/build-xcframework.yml` содержит:

```yaml
permissions:
  contents: write  # Required to commit XCFramework back to repository
  actions: read    # Required to read workflow status
  checks: write    # Required to create check runs
```

Это уже добавлено в workflow файл.

### Шаг 3: Тестирование автоматического запуска

После настройки разрешений:

1. Создайте тестовый тег:
   ```bash
   git tag v1.0.99-auto-test
   git push origin v1.0.99-auto-test
   ```

2. Проверьте что workflow запустился автоматически:
   - Откройте https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder/actions
   - Должен появиться workflow "Build XCFramework" который запустился автоматически
   - Не должно быть запроса на одобрение

### Шаг 4: Если workflow всё ещё требует одобрения

Если после настройки workflow всё ещё требует одобрения:

1. **Проверьте что workflow файл закоммичен:**
   ```bash
   git add .github/workflows/build-xcframework.yml
   git commit -m "Add GitHub Actions workflow with permissions"
   git push
   ```

2. **Проверьте настройки ветки:**
   - Settings → Branches
   - Убедитесь что для `main` или `master` нет правил требующих approval для Actions

3. **Для приватных репозиториев:**
   - Settings → Actions → General
   - В секции **"Workflow permissions"** выберите **"Read and write permissions"**
   - Отметьте **"Allow GitHub Actions to create and approve pull requests"**

## Что было исправлено в workflow

1. ✅ Добавлены `permissions` для автоматического выполнения
2. ✅ Исправлена команда `git push` для работы с тегами
3. ✅ Добавлено условие `if:` для автоматического запуска

## После настройки

Workflow будет автоматически запускаться при:
- Создании тега `v*` (например, `v1.0.100`)
- Ручном запуске через GitHub UI (workflow_dispatch)

**Не требуется:**
- ❌ Ручное одобрение
- ❌ Дополнительные настройки
- ❌ Персональные токены

## Проверка что всё работает

После создания тега проверьте:

1. **Workflow запустился автоматически:**
   - https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder/actions
   - Должен быть workflow "Build XCFramework" в статусе "Running" или "Completed"

2. **Нет запроса на одобрение:**
   - Если видите "Waiting for approval" - проверьте настройки из Шага 1

3. **Результат успешен:**
   - После завершения должен быть зелёный статус ✅
   - XCFramework должен быть закоммичен в репозиторий

## Troubleshooting

### Workflow не запускается автоматически

**Причины:**
- Тег создан неправильно (должен начинаться с `v`, например `v1.0.99`)
- Тег не запушен в удалённый репозиторий
- Workflow файл не закоммичен

**Решение:**
```bash
# Проверить теги
git tag -l

# Создать и запушить тег правильно
git tag v1.0.99-test
git push origin v1.0.99-test
```

### Workflow требует одобрения

**Причины:**
- Настройки безопасности репозитория требуют одобрения
- Нет разрешений для автоматического выполнения

**Решение:**
- См. Шаг 1 выше
- Убедитесь что `permissions` добавлены в workflow файл

### Git push не работает

**Причины:**
- Недостаточно прав в `GITHUB_TOKEN`
- pikеправильная команда push

**Решение:**
- Убедитесь что `permissions: contents: write` добавлено
- Проверьте что команда push использует правильный формат (см. workflow файл)

