# Langu - Korean Pronunciation Learning App

Langu is an iOS application for learning Korean pronunciation through gamification and AI-powered speech assessment.

## Overview

- **Platform**: iOS 17+
- **Framework**: SwiftUI + SwiftData
- **Backend**: Cloudflare Workers (langu-api)
- **Speech Assessment**: Azure Speech Services
- **Text-to-Speech**: Google Cloud TTS

## Features

### Core Learning

| Feature | Description |
|---------|-------------|
| **Lessons** | 30+ lessons across 6 units (Greetings, Daily Phrases, Shopping, Restaurant, Transportation, Self-Introduction) |
| **Speech Assessment** | Real-time pronunciation scoring with 5 axes (Pronunciation, Accuracy, Fluency, Prosody, Completeness) |
| **Word-level Feedback** | Per-word accuracy scores and error detection (mispronunciation, omission, insertion) |
| **TTS Reference Audio** | Native Korean pronunciation with multiple voice options |
| **Short Stories** | 5 multi-sentence stories for reading practice with Full/Sentence-by-sentence modes |

### Gamification

| Feature | Description |
|---------|-------------|
| **XP System** | Earn 10-50 XP per lesson based on score |
| **Streak Tracking** | Daily practice streak with fire badge |
| **Daily Goals** | Configurable 1-10 lessons per day |
| **Achievements** | 27+ badges across 6 categories (Milestones, Lessons, Streaks, XP, Mastery, Special) |
| **Progress Tracking** | Unit unlocking, lesson completion, score history |

### User Experience

| Feature | Description |
|---------|-------------|
| **Duolingo-style Design** | Rounded, playful UI with animations |
| **Dark Mode** | System/Light/Dark appearance modes |
| **Accessibility** | VoiceOver support, Dynamic Type, Haptic Feedback |
| **Push Notifications** | Daily reminder scheduling |
| **Offline Support** | Local data persistence with SwiftData |

## Tech Stack

### iOS App (langu)

```
SwiftUI          - Declarative UI framework
SwiftData        - Local data persistence
AVFoundation     - Audio recording/playback
Charts           - Statistics visualization
@Observable      - Reactive state management
```

### Backend API (langu-api)

```
Cloudflare Workers  - Serverless edge computing
TypeScript          - Type-safe development
Terraform           - Infrastructure as Code
Azure Speech API    - Pronunciation assessment
Google Cloud TTS    - Text-to-speech synthesis
```

## Project Structure

```
langu/
├── langu/
│   ├── Models/          # Data models
│   ├── Views/           # SwiftUI views
│   ├── Services/        # Business logic
│   ├── Theme/           # Design system
│   └── Navigation/      # App routing
├── doc/                 # Documentation
└── languTests/          # Unit tests

langu-api/
├── src/
│   ├── handlers/        # API endpoints
│   └── types/           # TypeScript types
└── terraform/           # Infrastructure
```

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ device or simulator
- Node.js 18+ (for API development)
- Cloudflare account (for API deployment)

### iOS App Setup

```bash
cd langu
open langu.xcodeproj
# Build and run in Xcode
```

### API Setup

```bash
cd langu-api
npm install
npm run dev          # Local development
npm run deploy:prod  # Production deployment
```

### API Keys Required

- `AZURE_SPEECH_KEY` - Azure Speech Services
- `GOOGLE_TTS_API_KEY` - Google Cloud TTS

## Documentation

- [Architecture](./ARCHITECTURE.md) - System design and patterns
- [API Reference](./API.md) - Backend API documentation
- [Features](./FEATURES.md) - Detailed feature list

## License

Private project - All rights reserved.
