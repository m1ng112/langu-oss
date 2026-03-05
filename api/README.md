# langu-api

Cloudflare Workers API for [langu](https://github.com/m1ng112/langu) - Korean pronunciation learning app.

## Architecture

```
iOS App → Cloudflare Workers → Azure Speech API / Google TTS
```

This API acts as a secure proxy to Azure Speech Services and Google Cloud TTS, protecting API keys and enabling rate limiting.

## Base URL

```
Production:  https://langu-api.ko-with-ja.workers.dev
Development: http://localhost:8787
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/assess` | Pronunciation assessment |
| POST | `/api/v1/tts` | Text-to-speech |
| GET | `/api/v1/health` | Health check |

---

## POST /api/v1/assess

Evaluate Korean pronunciation using Azure Speech Services.

### Request

```json
{
    "audio": "<base64-encoded-wav>",
    "referenceText": "안녕하세요"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| audio | string | Yes | Base64 encoded WAV audio (16kHz, mono, PCM) |
| referenceText | string | Yes | Expected Korean text |

### Response (Success)

```json
{
    "success": true,
    "data": {
        "pronunciationScore": 87,
        "accuracyScore": 92,
        "fluencyScore": 78,
        "completenessScore": 95,
        "prosodyScore": 81,
        "recognizedText": "안녕하세요",
        "words": [
            {
                "word": "안녕하세요",
                "accuracyScore": 92,
                "errorType": "none"
            }
        ]
    },
    "meta": {
        "assessmentId": "550e8400-e29b-41d4-a716-446655440000",
        "processedAt": "2024-01-29T10:30:00Z"
    }
}
```

| Field | Type | Description |
|-------|------|-------------|
| pronunciationScore | number | Overall pronunciation score (0-100) |
| accuracyScore | number | Phoneme accuracy score (0-100) |
| fluencyScore | number | Speech flow score (0-100) |
| completenessScore | number | Completeness of utterance (0-100) |
| prosodyScore | number | Intonation/rhythm score (0-100) |
| recognizedText | string | What the API heard |
| words | array | Per-word assessment |
| words[].word | string | The word |
| words[].accuracyScore | number | Word accuracy (0-100) |
| words[].errorType | string | `none`, `mispronunciation`, `omission`, `insertion` |

### Response (Error)

```json
{
    "success": false,
    "error": "No speech detected"
}
```

### Error Codes

| Status | Error | Description |
|--------|-------|-------------|
| 400 | Invalid JSON body | Request body not valid JSON |
| 400 | Missing required fields | audio or referenceText missing |
| 400 | Audio file too large | Exceeds 5MB limit |
| 400 | Invalid base64 audio | Cannot decode audio |
| 400 | Recognition failed: NoMatch | No speech detected |
| 405 | Method not allowed | Not a POST request |
| 502 | Speech service error | Azure API error |

---

## POST /api/v1/tts

Convert Korean text to speech using Google Cloud TTS.

### Request

```json
{
    "text": "안녕하세요",
    "voiceName": "ko-KR-Wavenet-A",
    "speakingRate": 0.9
}
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| text | string | Yes | - | Korean text to speak |
| voiceName | string | No | ko-KR-Wavenet-A | Voice ID |
| speakingRate | number | No | 1.0 | Speed (0.25-4.0) |

### Available Voices

| Voice ID | Gender | Type |
|----------|--------|------|
| ko-KR-Wavenet-A | Female | WaveNet (high quality) |
| ko-KR-Wavenet-B | Female | WaveNet |
| ko-KR-Wavenet-C | Male | WaveNet |
| ko-KR-Wavenet-D | Male | WaveNet |
| ko-KR-Standard-A | Female | Standard |
| ko-KR-Standard-B | Female | Standard |
| ko-KR-Standard-C | Male | Standard |
| ko-KR-Standard-D | Male | Standard |

### Response (Success)

```json
{
    "success": true,
    "data": {
        "audioContent": "<base64-encoded-mp3>"
    },
    "meta": {
        "requestId": "550e8400-e29b-41d4-a716-446655440000",
        "voiceUsed": "ko-KR-Wavenet-A",
        "processedAt": "2024-01-29T10:30:00Z"
    }
}
```

### Error Codes

| Status | Error | Description |
|--------|-------|-------------|
| 400 | Missing text field | Text not provided |
| 400 | Text too long | Exceeds 500 characters |
| 400 | Invalid speaking rate | Outside 0.25-4.0 range |
| 405 | Method not allowed | Not a POST request |
| 502 | TTS service error | Google API error |

---

## GET /api/v1/health

Health check endpoint.

### Response

```json
{
    "status": "ok",
    "version": "1.0.1",
    "timestamp": "2024-01-29T10:30:00Z",
    "endpoints": [
        "/api/v1/assess",
        "/api/v1/tts",
        "/api/v1/health"
    ]
}
```

---

## CORS

All endpoints support CORS:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 86400
```

## Rate Limiting

| Environment | Limit | Period | Block Duration |
|-------------|-------|--------|----------------|
| Production | 100 requests | 24 hours | 1 hour |
| Development | 1000 requests | 24 hours | 1 hour |

Rate limiting applies to `/api/v1/assess` and `/api/v1/tts` endpoints only.

## Caching

| Endpoint | Cache Duration |
|----------|----------------|
| /api/v1/tts | 24 hours (Cache-Control header) |
| /api/v1/assess | No cache |
| /api/v1/health | No cache |

## Audio Specifications

### Input (Assessment)

| Property | Value |
|----------|-------|
| Format | WAV |
| Sample Rate | 16000 Hz |
| Channels | Mono |
| Bit Depth | 16-bit |
| Encoding | PCM |
| Max Size | 5 MB (base64) |

### Output (TTS)

| Property | Value |
|----------|-------|
| Format | MP3 |
| Encoding | Base64 |

---

## Development

### Prerequisites

- Node.js 18+
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)
- Cloudflare account
- Azure Speech Services subscription
- Google Cloud TTS API key

### Setup

```bash
# Install dependencies
npm install

# Set up secrets
npx wrangler secret put AZURE_SPEECH_KEY
npx wrangler secret put GOOGLE_TTS_API_KEY

# Run locally
npm run dev
```

### Deploy

```bash
# Deploy to dev
npm run deploy

# Deploy to production
npm run deploy:prod
```

## Infrastructure (Terraform)

### Prerequisites

- Terraform 1.0+
- Cloudflare API token with Workers permission

### Setup

```bash
cd terraform

# Initialize
terraform init

# Plan
terraform plan -var-file=environments/prod.tfvars

# Apply
terraform apply -var-file=environments/prod.tfvars
```

## License

Private - All rights reserved
