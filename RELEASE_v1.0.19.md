# 🔧 Release v1.0.19 - Swift Package Manager Compatibility Fix

**Дата:** 28 октября 2025  
**Тэг:** `1.0.19`

---

## 🐛 ЧТО ИСПРАВЛЕНО

### Swift Package Manager не мог загрузить v1.0.18

**Проблема:**  
При попытке загрузить версию `1.0.18` через `tuist install --update`, Swift Package Manager выдавал ошибку:

```
error: the package at '/' cannot be accessed (malformedResponse("unexpected tree entry..."))
```

**Причина:**  
В репозитории были файлы с **кириллическими именами**:
- `ДОБРОЕ_УТРО_БРАТИК.md`
- `КАК_ДОБАВИТЬ_LZ.md`
- `ПОСЛЕДНИЕ_4_SYMBOLS.md`

Swift Package Manager не может правильно парсить Git tree entries с кириллическими символами, что приводило к `malformedResponse` ошибке.

**Решение:**  
✅ Удалены все файлы с кириллическими именами  
✅ Вся информация из этих файлов уже присутствует в:
- `RELEASE_v1.0.18.md` (детальные release notes)
- `README.md` (инструкции по использованию)

---

## 📦 ЧТО В v1.0.19

Это **идентичная версия v1.0.18**, но без кириллических имен файлов:

✅ **Все 4 undefined symbols исправлены:**
- `_alert_sockets_create`
- `_curved25519_scalarmult_basepoint_donna`
- `_dos_options_fmt`
- `_switch_id`

✅ **100% покрытие символов**  
✅ **Device + Simulator support**  
✅ **Swift Package Manager совместимость**

---

## 🚀 КАК ОБНОВИТЬСЯ

### Из TorApp:

```bash
cd ~/admin/TorApp

# Очистите кэш
rm -rf .build
tuist clean

# Обновите версию на 1.0.19 в Dependencies.swift или Package.swift:
# from: "1.0.19"

# Установите
tuist install --update
tuist generate
```

### Изменения в коде:

Никаких изменений в коде не требуется! Просто обновите версию с `1.0.18` → `1.0.19`.

---

## 📊 COMPARISON: v1.0.18 vs v1.0.19

| Параметр | v1.0.18 | v1.0.19 |
|----------|---------|---------|
| Функциональность | ✅ Идентичная | ✅ Идентичная |
| Symbols coverage | ✅ 100% | ✅ 100% |
| Device support | ✅ Yes | ✅ Yes |
| Simulator support | ✅ Yes | ✅ Yes |
| Кириллические файлы | ❌ 3 файла | ✅ 0 файлов |
| SPM compatibility | ❌ Broken | ✅ Fixed |

---

## 📝 ИЗМЕНЕНИЯ В ФАЙЛАХ

### Удалены:
- `ДОБРОЕ_УТРО_БРАТИК.md`
- `КАК_ДОБАВИТЬ_LZ.md`
- `ПОСЛЕДНИЕ_4_SYMBOLS.md`

### Обновлены:
- `README.md` - версия обновлена на `1.0.19`

### Без изменений:
- Все исходники Tor
- Все build скрипты
- `Tor.xcframework` (идентичен v1.0.18)
- `Package.swift`
- `Project.swift`

---

## ✅ РЕЗУЛЬТАТ

```
╔═══════════════════════════════════════╗
║  TorFrameworkBuilder v1.0.19         ║
╠═══════════════════════════════════════╣
║  ✅ Swift Package Manager compatible  ║
║  ✅ No Cyrillic filenames             ║
║  ✅ 100% symbol coverage              ║
║  ✅ Device + Simulator support        ║
║  ✅ Ready to use in TorApp            ║
╚═══════════════════════════════════════╝
```

**Теперь `tuist install --update` работает без ошибок!** 🎉

---

## 🔗 ССЫЛКИ

- **Подробные release notes v1.0.18:** `RELEASE_v1.0.18.md`
- **README:** `README.md`
- **GitHub:** https://github.com/Alexandr-Ivantsov/TorFrameworkBuilder

---

## 💡 ПРИМЕЧАНИЕ

Если вы столкнулись с ошибкой при использовании v1.0.18:
- ✅ Просто обновите на v1.0.19
- ✅ Очистите кэш: `rm -rf .build && tuist clean`
- ✅ Переустановите: `tuist install --update`

**Всё будет работать!** ✨

