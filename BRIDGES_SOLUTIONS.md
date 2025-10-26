# 🌉 Решения для получения Tor Bridges через Email

## Проблема

Пользователь хочет получать vanilla bridges от Tor Project через email:
1. Отправить письмо на `bridges@torproject.org` с текстом "get vanilla"
2. Получить ответ с bridge адресами
3. Извлечь bridges из письма
4. Настроить Tor для использования этих bridges

---

## Решение 1: Gmail API (рекомендуется) ⭐

### Преимущества:
- ✅ Официальный API от Google
- ✅ Надежный и безопасный
- ✅ Не нужен пароль приложения
- ✅ OAuth 2.0 авторизация
- ✅ Можно делать все операции (отправка, чтение)

### Недостатки:
- ⚠️ Требует настройки Google Cloud Project
- ⚠️ Нужна OAuth авторизация пользователя
- ⚠️ Больше кода для реализации

### Архитектура:

```
TorApp (iOS)
    ↓ OAuth 2.0
Gmail API
    ↓ Отправка письма
bridges@torproject.org
    ↓ Ответ
Gmail Inbox
    ↓ Чтение через API
TorApp (парсинг bridges)
    ↓ Настройка
Tor daemon
```

### Реализация:

```swift
import GoogleSignIn
import GoogleAPIClientForREST

class BridgeRequestService {
    
    private let service = GTLRGmailService()
    
    // 1. Авторизация
    func authorize(completion: @escaping (Result<Void, Error>) -> Void) {
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "Gmail", code: -1)))
                return
            }
            
            self.service.authorizer = user.fetcherAuthorizer
            completion(.success(()))
        }
    }
    
    // 2. Отправка запроса на bridges
    func requestBridges(from email: String) async throws {
        let message = """
        To: bridges@torproject.org
        From: \(email)
        Subject: Tor Bridges Request
        
        get vanilla
        """
        
        let emailData = message.data(using: .utf8)!
        let base64Email = emailData.base64EncodedString()
        
        let gmailMessage = GTLRGmail_Message()
        gmailMessage.raw = base64Email
        
        let query = GTLRGmailQuery_UserMessagesSend.query(withObject: gmailMessage, userId: "me")
        
        try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // 3. Проверка новых писем от bridges@torproject.org
    func checkForBridgeResponse() async throws -> [String] {
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: "me")
        query.q = "from:bridges@torproject.org is:unread"
        
        let result = try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
        
        guard let messages = (result as? GTLRGmail_ListMessagesResponse)?.messages else {
            return []
        }
        
        // Получить полное содержимое первого письма
        guard let firstMessageId = messages.first?.identifier else {
            return []
        }
        
        let msgQuery = GTLRGmailQuery_UsersMessagesGet.query(withUserId: "me", identifier: firstMessageId)
        msgQuery.format = "full"
        
        let message = try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(msgQuery) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result as? GTLRGmail_Message)
                }
            }
        }
        
        // Парсинг bridges из письма
        let bridges = parseBridges(from: message)
        return bridges
    }
    
    private func parseBridges(from message: GTLRGmail_Message?) -> [String] {
        // Извлечь body
        guard let body = message?.payload?.body?.data else { return [] }
        
        // Декодировать base64
        guard let bodyData = Data(base64Encoded: body),
              let bodyText = String(data: bodyData, encoding: .utf8) else {
            return []
        }
        
        // Парсинг bridges (формат: "IP:PORT" или "IP:PORT fingerprint")
        let pattern = #"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: bodyText, range: NSRange(bodyText.startIndex..., in: bodyText))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range(at: 1), in: bodyText) else { return nil }
            return String(bodyText[range])
        } ?? []
    }
}
```

---

## Решение 2: Backend Proxy (средняя сложность) 🔄

### Преимущества:
- ✅ Не нужна OAuth в приложении
- ✅ Централизованная логика
- ✅ Можно кешировать bridges
- ✅ Проще для пользователя

### Недостатки:
- ⚠️ Требует свой сервер
- ⚠️ Дополнительные затраты на хостинг
- ⚠️ Нужен email на сервере

### Архитектура:

```
TorApp → Your Backend (Node.js/Python)
             ↓
        SMTP (отправка)
             ↓
     bridges@torproject.org
             ↓
        IMAP (чтение)
             ↓
        Your Backend
             ↓
         TorApp (JSON)
```

### Backend (Node.js + Express):

```javascript
// server.js
const express = require('express');
const nodemailer = require('nodemailer');
const Imap = require('node-imap');

const app = express();

// Отправка запроса
app.post('/request-bridges', async (req, res) => {
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: process.env.EMAIL,
            pass: process.env.EMAIL_PASSWORD
        }
    });
    
    await transporter.sendMail({
        from: process.env.EMAIL,
        to: 'bridges@torproject.org',
        subject: 'Tor Bridges Request',
        text: 'get vanilla'
    });
    
    res.json({ success: true });
});

// Получение bridges
app.get('/get-bridges', async (req, res) => {
    const imap = new Imap({
        user: process.env.EMAIL,
        password: process.env.EMAIL_PASSWORD,
        host: 'imap.gmail.com',
        port: 993,
        tls: true
    });
    
    const bridges = await readBridgesFromEmail(imap);
    res.json({ bridges });
});
```

---

## Решение 3: SMTP/IMAP напрямую (простое, но НЕ рекомендуется) ⚠️

### Преимущества:
- ✅ Самое простое
- ✅ Не нужен бэкенд
- ✅ Прямая отправка

### Недостатки:
- ❌ Нужен пароль приложения в коде (небезопасно!)
- ❌ Gmail блокирует "less secure apps"
- ❌ Сложно с OAuth
- ❌ Не рекомендуется Apple (rejection риск)

### ❗ НЕ РЕКОМЕНДУЮ из-за безопасности

---

## Решение 4: Tor BridgeDB API (если доступен) 🚀

### Преимущества:
- ✅ Официальный API
- ✅ Прямое получение bridges
- ✅ Не нужен email
- ✅ Простая интеграция

### Недостатки:
- ⚠️ Может требовать CAPTCHA
- ⚠️ API может быть недоступен

### Реализация:

```swift
class TorBridgeService {
    
    func fetchBridges() async throws -> [String] {
        // BridgeDB HTTPS endpoint
        let url = URL(string: "https://bridges.torproject.org/bridges?transport=vanilla")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Парсинг HTML ответа
        let html = String(data: data, encoding: .utf8) ?? ""
        return parseBridgesFromHTML(html)
    }
    
    private func parseBridgesFromHTML(_ html: String) -> [String] {
        // Извлечь bridges из HTML
        let pattern = #"bridge (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: html, range: NSRange(html.startIndex..., in: html))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[range])
        } ?? []
    }
}
```

---

## 📊 Сравнение решений

| Решение | Сложность | Безопасность | Надежность | Стоимость |
|---------|-----------|--------------|------------|-----------|
| Gmail API | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Бесплатно |
| Backend Proxy | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | $5-10/мес |
| SMTP/IMAP | ⭐⭐ | ⭐ | ⭐⭐ | Бесплатно |
| BridgeDB API | ⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Бесплатно |

---

## 🎯 Моя рекомендация

**Вариант 1 (Gmail API)** - если пользователь уже использует Gmail  
**Вариант 4 (BridgeDB API)** - если можно обойти CAPTCHA  
**Вариант 2 (Backend)** - если нужна максимальная простота для пользователя  

---

## 🔧 Что выбрать?

Ответьте на вопросы:

1. **У пользователя есть Gmail?** → Gmail API
2. **Хотите свой сервер?** → Backend Proxy
3. **Хотите без email вообще?** → BridgeDB API
4. **Нужна максимальная простота?** → Backend Proxy

Выберите решение, и я помогу реализовать!

