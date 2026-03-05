# Langu

A language pronunciation learning app with AI-powered speech assessment and content generation.

## Architecture

```
langu/
├── ios/          # iOS app (SwiftUI, iOS 17+)
├── api/          # Backend API (Cloudflare Workers, TypeScript)
├── tools/        # Content generation CLI
│   └── content-generator/  # Anthropic API-powered content generator
└── docs/         # Technical documentation
```

## Features

- Pronunciation practice with real-time speech assessment (Azure Speech Services)
- Free-talk conversation practice with AI evaluation (Anthropic Claude)
- Story reading exercises with sentence-by-sentence scoring
- Achievement system and progress tracking
- AI-powered content generation for any language pair

## Quick Start

### iOS App

1. Open `ios/langu.xcodeproj` in Xcode
2. Copy `ios/langu/Secrets.swift.example` to `ios/langu/Secrets.swift` and add your Azure credentials
3. Build and run on iOS Simulator

### API

```bash
cd api
npm install
# Set secrets via wrangler
wrangler secret put AZURE_SPEECH_KEY
wrangler secret put GOOGLE_TTS_API_KEY
wrangler secret put ANTHROPIC_API_KEY
npm run dev
```

### Content Generator

Generate learning content for any language pair:

```bash
cd tools/content-generator
npm install && npm run build
ANTHROPIC_API_KEY=your-key npx langu-generate generate \
  --native English \
  --target Korean \
  --output ./output
```

**Supported language examples:**

| Native | Target | Command |
|--------|--------|---------|
| English | Korean | `--native English --target Korean` |
| Japanese | Korean | `--native Japanese --target Korean` |
| English | Japanese | `--native English --target Japanese` |
| Chinese | English | `--native Chinese --target English` |
| Spanish | English | `--native Spanish --target English` |
| English | French | `--native English --target French` |
| English | Thai | `--native English --target Thai` |

Any language pair can be specified — the CLI uses AI to generate appropriate content including romanization, pronunciation hints, and difficulty-graded lessons.

Generated JSON files can be placed in `ios/langu/Resources/Content/` to update app content.

## Environment Variables

| Variable | Required For | Description |
|----------|-------------|-------------|
| `ANTHROPIC_API_KEY` | API, CLI | Anthropic API key for AI evaluation and content generation |
| `AZURE_SPEECH_KEY` | API | Azure Speech Services key for pronunciation assessment |
| `AZURE_SPEECH_REGION` | API | Azure region (e.g., `japaneast`) |
| `GOOGLE_TTS_API_KEY` | API | Google Cloud TTS key for reference audio |

## Tech Stack

- **iOS**: SwiftUI, SwiftData, AVFoundation
- **Backend**: Cloudflare Workers, TypeScript
- **APIs**: Azure Speech Services, Google Cloud TTS, Anthropic Claude
- **Infrastructure**: Terraform

## License

[MIT](LICENSE)
