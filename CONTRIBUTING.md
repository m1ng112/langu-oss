# Contributing to Langu

Thank you for your interest in contributing to Langu!

## Getting Started

### Prerequisites
- Xcode 16+ (for iOS app)
- Node.js 20+ (for API and content generator)
- Azure Speech Services account (for pronunciation assessment)
- Anthropic API key (for content generation)

### iOS App Setup

1. Open `ios/langu.xcodeproj` in Xcode
2. Copy `ios/langu/Secrets.swift.example` to `ios/langu/Secrets.swift`
3. Fill in your Azure Speech API credentials
4. Set your development team in Xcode signing settings
5. Build and run on simulator

### API Setup

```bash
cd api
npm install
cp .env.example .dev.vars  # Fill in API keys
npm run dev                 # Start local dev server
```

### Content Generator Setup

```bash
cd tools/content-generator
npm install
npm run build
ANTHROPIC_API_KEY=your-key npx langu-generate generate -n English -t Korean
```

## Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test your changes
5. Commit with a descriptive message
6. Push to your fork
7. Open a Pull Request

## Code Style

- **Swift**: Follow the patterns in the existing codebase (SwiftUI, @Observable, MARK sections)
- **TypeScript**: Strict mode, ESM modules

## Reporting Issues

Please use GitHub Issues to report bugs or request features.
