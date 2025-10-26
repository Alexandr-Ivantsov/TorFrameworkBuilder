# 🌉 Варианты реализации получения Bridges

## Ваши требования:

1. Пользователь вводит свой Gmail адрес
2. Приложение отправляет письмо на `bridges@torproject.org` с текстом "get vanilla"
3. Получает ответ с bridges
4. Извлекает bridges из письма
5. Настраивает Tor

---

## 🎯 Решение 1: CloudFlare Workers + Gmail API (⭐ РЕКОМЕНДУЮ)

### Архитектура:
```
iOS App → CloudFlare Worker (бесплатно)
              ↓
         Gmail API
              ↓
    bridges@torproject.org
              ↓
         Gmail Inbox
              ↓
    CloudFlare Worker (парсинг)
              ↓
         iOS App (JSON)
```

### Преимущества:
- ✅ **Бесплатно** (100,000 запросов/день)
- ✅ **Не нужен свой сервер**
- ✅ **OAuth только на Worker** (не в приложении)
- ✅ **Быстро** (~2 секунды)
- ✅ **Безопасно** (credentials на сервере)

### Реализация:

#### CloudFlare Worker (JavaScript):

```javascript
// worker.js
export default {
  async fetch(request) {
    const url = new URL(request.url);
    
    // Эндпоинт для запроса bridges
    if (url.pathname === '/request-bridges' && request.method === 'POST') {
      return await requestBridges(request);
    }
    
    // Эндпоинт для получения bridges
    if (url.pathname === '/get-bridges') {
      return await getBridges(request);
    }
    
    return new Response('TorBridge Service', { status: 200 });
  }
};

async function requestBridges(request) {
  const { userEmail } = await request.json();
  
  // Gmail API: отправка письма
  const accessToken = await getGmailAccessToken();
  
  const message = createRFC2822Message(
    env.SERVICE_EMAIL,
    'bridges@torproject.org',
    'Tor Bridges Request',
    'get vanilla'
  );
  
  const response = await fetch(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        raw: btoa(message)
      })
    }
  );
  
  return Response.json({ success: true, message: 'Request sent' });
}

async function getBridges(request) {
  const accessToken = await getGmailAccessToken();
  
  // Поиск писем от bridges@torproject.org
  const searchResponse = await fetch(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages?q=from:bridges@torproject.org+is:unread',
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    }
  );
  
  const { messages } = await searchResponse.json();
  
  if (!messages || messages.length === 0) {
    return Response.json({ bridges: [], pending: true });
  }
  
  // Получить первое письмо
  const messageId = messages[0].id;
  const msgResponse = await fetch(
    `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}`,
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    }
  );
  
  const message = await msgResponse.json();
  
  // Парсинг bridges
  const body = decodeEmailBody(message);
  const bridges = extractBridges(body);
  
  // Пометить как прочитанное
  await markAsRead(accessToken, messageId);
  
  return Response.json({ bridges });
}

function extractBridges(text) {
  // Паттерн для vanilla bridges: "IP:PORT"
  const pattern = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)/g;
  return text.match(pattern) || [];
}

async function getGmailAccessToken() {
  // Service Account OAuth
  // Используйте Cloudflare Secrets для хранения credentials
  const serviceAccount = JSON.parse(env.GMAIL_SERVICE_ACCOUNT);
  
  // Создать JWT token
  const jwtToken = await createJWT(serviceAccount);
  
  // Обменять на access token
  const tokenResponse = await fetch(
    'https://oauth2.googleapis.com/token',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwtToken
      })
    }
  );
  
  const { access_token } = await tokenResponse.json();
  return access_token;
}
```

#### iOS App:

```swift
class BridgeService {
    let workerURL = "https://your-worker.workers.dev"
    
    func requestBridges(userEmail: String) async throws {
        let url = URL(string: "\(workerURL)/request-bridges")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userEmail": userEmail]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BridgeError.requestFailed
        }
    }
    
    func fetchBridges() async throws -> [String] {
        let url = URL(string: "\(workerURL)/get-bridges")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let bridges: [String]
            let pending: Bool?
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.bridges
    }
}
```

**Настройка:**
1. Создать CloudFlare Workers аккаунт (бесплатно)
2. Создать Google Service Account
3. Дать доступ к Gmail API
4. Деплой worker
5. Использовать в приложении

---

## 🎯 Решение 2: Backend с Nodemailer (проще) 💻

### Преимущества:
- ✅ **Проще чем Worker**
- ✅ **Полный контроль**
- ✅ **Node.js** (знакомая экосистема)

### Недостатки:
- ⚠️ Нужен сервер (~$5-10/мес)
- ⚠️ Настройка Gmail App Password

### Реализация:

#### Backend (Node.js + Express):

```javascript
const express = require('express');
const nodemailer = require('nodemailer');
const Imap = require('imap');
const { simpleParser } = require('mailparser');

const app = express();
app.use(express.json());

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD // App Password!
  }
});

// Запрос bridges
app.post('/api/request-bridges', async (req, res) => {
  try {
    await transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: 'bridges@torproject.org',
      subject: 'Tor Bridges Request',
      text: 'get vanilla'
    });
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Получение bridges
app.get('/api/get-bridges', async (req, res) => {
  const imap = new Imap({
    user: process.env.GMAIL_USER,
    password: process.env.GMAIL_APP_PASSWORD,
    host: 'imap.gmail.com',
    port: 993,
    tls: true
  });
  
  imap.once('ready', () => {
    imap.openBox('INBOX', false, () => {
      // Поиск писем от bridges@torproject.org
      imap.search(['UNSEEN', ['FROM', 'bridges@torproject.org']], (err, results) => {
        if (results.length === 0) {
          return res.json({ bridges: [], pending: true });
        }
        
        const fetch = imap.fetch(results[0], { bodies: '' });
        
        fetch.on('message', msg => {
          msg.on('body', stream => {
            simpleParser(stream, async (err, parsed) => {
              const bridges = extractBridges(parsed.text);
              
              // Пометить как прочитанное
              imap.addFlags(results[0], '\\Seen', () => {
                imap.end();
              });
              
              res.json({ bridges });
            });
          });
        });
      });
    });
  });
  
  imap.connect();
});

function extractBridges(text) {
  const pattern = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)/g;
  return text.match(pattern) || [];
}

app.listen(3000);
```

**Деплой на Railway/Render/Heroku** (бесплатный tier).

---

## 🎯 Решение 3: In-App Email (НЕ рекомендую) ⚠️

### Использование MessageUI для отправки

```swift
import MessageUI

class BridgeRequestVC: UIViewController, MFMailComposeViewControllerDelegate {
    
    func requestBridges() {
        guard MFMailComposeViewController.canSendMail() else {
            print("Не настроен Mail на устройстве")
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["bridges@torproject.org"])
        composer.setSubject("Tor Bridges Request")
        composer.setMessageBody("get vanilla", isHTML: false)
        
        present(composer, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, 
                             didFinishWith result: MFMailComposeResult, 
                             error: Error?) {
        controller.dismiss(animated: true)
        
        if result == .sent {
            // Начать polling для получения ответа
            startPollingForBridges()
        }
    }
    
    func startPollingForBridges() {
        // ПРОБЛЕМА: нет API для чтения входящих в MessageUI!
        // Нужен другой метод
    }
}
```

### Проблема: 
❌ **MessageUI не позволяет читать входящие письма**

---

## 🎯 Решение 4: Статические Bridges (самое простое) ✨

### Идея:
Не запрашивать bridges через email, а использовать:
- Публичные lists bridges
- Hardcoded bridges
- Bridges из конфиг файла

### Реализация:

```swift
class StaticBridgeProvider {
    
    // Публичные vanilla bridges (обновлять вручную)
    static let defaultBridges = [
        "85.31.186.98:443",
        "85.31.186.26:443",
        "209.148.46.65:443",
        "193.11.166.194:27015"
    ]
    
    // Или загрузка из удаленного JSON
    func fetchBridgesList() async throws -> [String] {
        let url = URL(string: "https://your-cdn.com/bridges.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct BridgesList: Codable {
            let vanilla: [String]
            let obfs4: [String]
        }
        
        let list = try JSONDecoder().decode(BridgesList.self, from: data)
        return list.vanilla
    }
}
```

### Преимущества:
- ✅ **Работает мгновенно**
- ✅ **Не нужен email**
- ✅ **Простая реализация**

### Недостатки:
- ⚠️ Bridges могут устареть
- ⚠️ Нужно обновлять список вручную

---

## 📊 Сравнение решений

| Решение | Сложность | Стоимость | Автоматизация | Безопасность | UX |
|---------|-----------|-----------|---------------|--------------|-----|
| CloudFlare Worker | ⭐⭐⭐ | Бесплатно | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Backend (Node) | ⭐⭐⭐⭐ | $5-10/мес | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| In-App Email | ⭐⭐ | Бесплатно | ⭐ | ⭐⭐⭐ | ⭐⭐ |
| Статические | ⭐ | Бесплатно | ⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

---

## 🎯 Мои рекомендации по приоритету:

### 1. **CloudFlare Worker** (для production)
- Лучшее соотношение функциональности/стоимости
- Бесплатно до 100k запросов/день
- Профессиональное решение

### 2. **Статические Bridges** (для MVP)
- Начните с этого
- Можно быстро протестировать функциональность
- Потом добавить динамические

### 3. **Backend на Railway** (альтернатива Worker)
- Если не хотите CloudFlare
- Railway дает $5 бесплатно/месяц
- Проще чем Worker для backend разработчиков

### 4. **In-App Email** - не рекомендую
- Плохой UX (открывается Mail app)
- Нет способа автоматически прочитать ответ

---

## 💡 Гибридное решение (лучшее из двух миров)

```swift
class BridgeManager {
    
    // 1. Начать со статических
    private let staticBridges = [
        "85.31.186.98:443",
        "85.31.186.26:443"
    ]
    
    // 2. Попробовать получить свежие
    func getBridges() async -> [String] {
        do {
            // Попытка получить свежие через CloudFlare Worker
            let fresh = try await fetchFreshBridges()
            if !fresh.isEmpty {
                saveBridges(fresh) // Сохранить для offline
                return fresh
            }
        } catch {
            print("Не удалось получить свежие bridges: \(error)")
        }
        
        // Fallback на сохраненные или статические
        return loadSavedBridges() ?? staticBridges
    }
    
    private func fetchFreshBridges() async throws -> [String] {
        let url = URL(string: "https://your-worker.workers.dev/get-bridges")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let bridges: [String]
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.bridges
    }
}
```

---

## 🚀 Рекомендуемый workflow:

### Фаза 1 (сейчас):
1. Используйте **статические bridges** для тестирования
2. Реализуйте базовую функциональность Tor
3. Проверьте что всё работает

### Фаза 2 (потом):
1. Настройте **CloudFlare Worker**
2. Реализуйте автоматическое получение bridges
3. Добавьте fallback на статические

---

## 📝 Выберите решение:

Напишите номер, и я помогу реализовать:
1. CloudFlare Worker (сложнее, но лучше)
2. Node.js Backend (проще, но нужен сервер)
3. Статические Bridges (самое простое для старта)
4. Гибридное (статические + Worker)

Что выбираете?

