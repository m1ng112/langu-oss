# API Reference

Full API documentation is maintained in the [langu-api repository](https://github.com/m1ng112/langu-api).

## Quick Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/assess` | POST | Pronunciation assessment |
| `/api/v1/tts` | POST | Text-to-speech |
| `/api/v1/health` | GET | Health check |

## Base URL

```
Production: https://langu-api.ko-with-ja.workers.dev
```

## iOS Integration

```swift
let baseURL = "https://langu-api.ko-with-ja.workers.dev"

// Assessment
let body: [String: Any] = [
    "audio": audioData.base64EncodedString(),
    "referenceText": "안녕하세요"
]

var request = URLRequest(url: URL(string: "\(baseURL)/api/v1/assess")!)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: body)

let (data, _) = try await URLSession.shared.data(for: request)
```

See [langu-api README](https://github.com/m1ng112/langu-api) for full documentation.
