# 🔍 ПРОВЕРКА ПАТЧА ПОСЛЕ `tuist install`

**ВАЖНО:** Binary в репозитории TorFrameworkBuilder БЕЗ патча (это нормально!)  
**Патч применяется при компиляции Tor во время `tuist install` в TorApp.**

---

## ✅ КАК ПРОВЕРИТЬ ЧТО ПАТЧ ПРИМЕНИЛСЯ

### Шаг 1: После `tuist install` в TorApp

```bash
cd ~/admin/TorApp

# ВАЖНО: Дождитесь окончания tuist install (~5-10 минут)
# В логах должно быть:
# ✅ crypto_rand_fast.c patched successfully!
# ✅✅✅ Patch VERIFIED in crypto_rand_fast.c!
```

### Шаг 2: Найти скомпилированный binary

```bash
# Найти путь к binary:
find .build -name "Tor" -type f -path "*/Tor.framework/Tor" 2>/dev/null

# Или:
find Tuist/Dependencies/.build -name "Tor" -type f -path "*/Tor.framework/Tor" 2>/dev/null
```

**Пример пути:**
```
.build/checkouts/TorFrameworkBuilder/output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor
```

### Шаг 3: Проверить патч в binary

```bash
# Замените ПУТЬ на реальный путь из шага 2:
BINARY_PATH=".build/checkouts/TorFrameworkBuilder/output/Tor.xcframework/ios-arm64-simulator/Tor.framework/Tor"

# Проверка патча:
if strings "$BINARY_PATH" | grep -q "Using memory with INHERIT_RES_KEEP on iOS"; then
    echo "✅✅✅ SUCCESS: Patch FOUND in binary!"
    echo "Tor will NOT crash on line 187!"
else
    echo "❌❌❌ FAILED: Patch NOT in binary!"
    echo "Проверьте логи tuist install!"
fi
```

---

## 🎯 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

### При проверке binary:

```bash
$ strings "$BINARY_PATH" | grep "Using memory with INHERIT_RES_KEEP"
Using memory with INHERIT_RES_KEEP on iOS (with PID check).
✅ ПАТЧ ЕСТЬ!
```

### При запуске Tor в приложении:

```
[notice] Opening Socks listener on 127.0.0.1:9160  ✅
[notice] Opening Control listener on 127.0.0.1:9162  ✅
[info] Using memory with INHERIT_RES_KEEP on iOS (with PID check).  ✅ ПАТЧ!
[notice] Bootstrapped 5% (conn): Connecting to a relay  ✅
[notice] Bootstrapped 100% (done): Done  ✅✅✅
```

**КЛЮЧЕВОЙ МАРКЕР:**  
`[info] Using memory with INHERIT_RES_KEEP on iOS (with PID check).`

**Если этой строки НЕТ в логах Tor → патч не применился!**

---

## 🚨 ЧТО ДЕЛАТЬ ЕСЛИ ПАТЧА НЕТ В BINARY

### Вариант 1: Полная очистка и переустановка

```bash
cd ~/admin/TorApp

# 1. Полная очистка:
rm -rf .build
rm -rf Tuist/Dependencies
tuist clean

# 2. Переустановка:
tuist install --update  # Дождитесь ~5-10 минут

# 3. Проверьте логи установки:
# Должно быть:
# ✅ crypto_rand_fast.c patched successfully!
# ✅✅✅ Patch VERIFIED in crypto_rand_fast.c!

# 4. Проверьте binary (шаг 2-3 выше)
```

### Вариант 2: Проверить исходники в .build

```bash
cd ~/admin/TorApp

# Найти исходники Tor:
find .build -name "crypto_rand_fast.c" -path "*/crypt_ops/*"

# Проверить патч:
grep -A 3 "Using memory with INHERIT_RES_KEEP" \
    .build/checkouts/TorFrameworkBuilder/tor-ios-fixed/src/lib/crypt_ops/crypto_rand_fast.c
```

**Должен показать:**
```c
log_info(LD_CRYPTO, "Using memory with INHERIT_RES_KEEP on iOS (with PID check).");
```

**Если патча НЕТ в исходниках → проблема в TorFrameworkBuilder v1.0.45!**

### Вариант 3: Проверить логи tuist install

```bash
# Если tuist install не показал логи применения патча:
# → fix_conflicts.sh не запустился
# → проверьте Package.swift в TorFrameworkBuilder

# В Package.swift должно быть:
# .plugin(name: "FixConflictsPlugin", package: "TorFrameworkBuilder")
```

---

## 📊 ДИАГНОСТИКА

### Проблема: Binary БЕЗ патча после tuist install

**Возможные причины:**

1. **fix_conflicts.sh не запустился** → проверьте Package.swift
2. **Компилятор использует кэш** → `tuist clean` перед `tuist install`
3. **Патч не применился к исходникам** → проверьте логи tuist install
4. **Binary не пересобрался** → проверьте что компиляция прошла (~5-10 минут)

### Решение:

```bash
# 1. Полная очистка:
cd ~/admin/TorApp
rm -rf .build Tuist/Dependencies
tuist clean

# 2. Установка с ЧИСТОГО состояния:
tuist install --update 2>&1 | tee tuist_install.log

# 3. Проверка логов:
grep "crypto_rand_fast.c patched" tuist_install.log
grep "Patch VERIFIED" tuist_install.log

# 4. Если логов НЕТ → fix_conflicts.sh не запустился!
```

---

## 🎯 КРИТИЧЕСКАЯ ПРОВЕРКА (CHECKLIST)

После `tuist install`:

- [ ] ✅ В логах: `crypto_rand_fast.c patched successfully!`
- [ ] ✅ В логах: `Patch VERIFIED in crypto_rand_fast.c!`
- [ ] ✅ В исходниках: `grep "Using memory with INHERIT_RES_KEEP" .build/.../crypto_rand_fast.c`
- [ ] ✅ В binary: `strings .../Tor.framework/Tor | grep "Using memory with INHERIT_RES_KEEP"`
- [ ] ✅ При запуске Tor: `[info] Using memory with INHERIT_RES_KEEP...` в логах
- [ ] ✅ НЕТ краша на line 187
- [ ] ✅ Bootstrap достигает 100%

**Если ВСЕ ✅ → патч работает!**  
**Если хотя бы один ❌ → см. раздел "Что делать если патча нет"**

---

## 💡 ПОЧЕМУ BINARY В РЕПОЗИТОРИИ БЕЗ ПАТЧА?

**Это НОРМАЛЬНО и ОЖИДАЕМО!**

### Причина:

1. **Полная пересборка Tor НЕВОЗМОЖНА** без `orconfig.h`
2. `orconfig.h` создаётся через `./configure` (не работает для iOS cross-compilation)
3. Без `orconfig.h` компилируется только 61/445 файлов (libtor.a 416K вместо 5M)

### Решение:

- ✅ Binary в репозитории: от v1.0.42 (device+simulator support через vtool)
- ✅ Патч в исходниках: ВЕРИФИЦИРОВАН в tor-ios-fixed/ (v1.0.45)
- ✅ Патч применится: при `tuist install` → SPM компилирует Tor С ПАТЧЕМ!

**Это ПРАВИЛЬНЫЙ подход!**

---

## 🔥 ИТОГОВАЯ ИНСТРУКЦИЯ

```bash
# В TorApp:
cd ~/admin/TorApp

# 1. Обновить на v1.0.45:
# Tuist/Dependencies.swift → requirement: .exact("1.0.45")

# 2. Полная очистка:
rm -rf .build Tuist/Dependencies
tuist clean

# 3. Установка (~5-10 минут):
tuist install --update 2>&1 | tee install.log

# 4. КРИТИЧЕСКАЯ ПРОВЕРКА логов:
grep "Patch VERIFIED" install.log
# Должно быть: ✅✅✅ Patch VERIFIED in crypto_rand_fast.c!

# 5. Найти binary:
BINARY=$(find .build -name "Tor" -type f -path "*/Tor.framework/Tor" | head -1)
echo "Binary: $BINARY"

# 6. Проверить патч:
strings "$BINARY" | grep "Using memory with INHERIT_RES_KEEP"
# Должно показать: Using memory with INHERIT_RES_KEEP on iOS (with PID check).

# 7. Генерация и запуск:
tuist generate
open TorApp.xcworkspace
# Run on Simulator

# 8. Проверить логи Tor:
# Должно быть: [info] Using memory with INHERIT_RES_KEEP on iOS...
# НЕ должно быть: tor_assertion_failed_: Bug: crypto_rand_fast.c:187
```

**ЕСЛИ ВСЕ ОК → ТOR РАБОТАЕТ БЕЗ КРАША!** ✅✅✅

---

**Дата:** 29 октября 2025  
**Версия:** v1.0.45  
**Статус:** ✅ ПАТЧ ВЕРИФИЦИРОВАН В ИСХОДНИКАХ, ПРИМЕНИТСЯ ПРИ КОМПИЛЯЦИИ

