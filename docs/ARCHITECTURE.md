# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App                               │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Views  │──│Services │──│ Models  │──│SwiftData│        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTPS
┌───────────────────────▼─────────────────────────────────────┐
│                  Cloudflare Workers                          │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  /api/v1/assess │  │  /api/v1/tts    │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
└───────────┼────────────────────┼────────────────────────────┘
            │                    │
┌───────────▼────────┐  ┌───────▼────────────┐
│  Azure Speech API  │  │  Google Cloud TTS  │
└────────────────────┘  └────────────────────┘
```

## iOS App Architecture

### Layer Structure

```
┌─────────────────────────────────────────┐
│                 Views                    │
│  (SwiftUI Views, Components, Modifiers) │
├─────────────────────────────────────────┤
│               Services                   │
│  (Business Logic, API Clients, State)   │
├─────────────────────────────────────────┤
│                Models                    │
│  (Data Structures, SwiftData Entities)  │
├─────────────────────────────────────────┤
│              Navigation                  │
│  (AppState, Tab/Screen Routing)         │
├─────────────────────────────────────────┤
│                Theme                     │
│  (Colors, Typography, Spacing, Shadows) │
└─────────────────────────────────────────┘
```

### State Management

**@Observable Pattern** (Swift 5.9+)

```swift
@Observable
final class SomeService {
    var isLoading = false
    var data: [Item] = []
}

// Usage in View
struct SomeView: View {
    @State private var service = SomeService()
}
```

**Environment Injection**

```swift
// Root
.environment(appState)
.environment(achievementService)
.environment(errorService)

// Child View
@Environment(AppState.self) private var appState
```

**Persistence Layers**

| Layer | Technology | Use Case |
|-------|------------|----------|
| SwiftData | @Model + @Query | PracticeRecord history |
| AppStorage | UserDefaults | User preferences |
| In-memory | Dictionary | TTS audio cache |
| JSON/UserDefaults | Codable | Achievement unlock data |

### Navigation

```swift
enum AppScreen: Hashable {
    case home
    case lesson(Lesson)
    case feedback(Lesson, LessonFeedback)
    case storyList
    case story(Story)
}

enum Tab: Int, CaseIterable {
    case home, achievements, stats, settings
}
```

**Navigation Flow**

```
ContentView
├── OnboardingView (first launch only)
└── Main Navigation
    ├── HomeView → LessonView → FeedbackView
    │           → StoryListView → StoryPracticeView
    ├── AchievementsView
    ├── StatsView
    └── SettingsView
```

## Models

### Core Entities

```swift
// Lesson content
struct Lesson: Identifiable, Hashable {
    let id: Int
    let unitId: Int
    let korean: String
    let romanization: String
    let translation: String
    let difficulty: Difficulty
    let hint: String
}

// Practice history (SwiftData)
@Model
class PracticeRecord {
    var lessonId: Int
    var score: Int      // 0-100
    var xpEarned: Int
    var date: Date
}

// Assessment result
struct LessonFeedback {
    let overallScore: Int
    let scores: [ScoreAxis]      // 5 axes
    let words: [WordFeedback]    // Per-word
    let recognizedText: String?
}
```

### Score Axes

| Axis | Korean | Weight | Icon |
|------|--------|--------|------|
| Pronunciation | 발음 | 30% | mic.fill |
| Accuracy | 정확도 | 30% | target |
| Fluency | 유창성 | 20% | waveform.path |
| Prosody | 억양 | 20% | music.note |
| Completeness | 완성도 | - | checkmark.circle.fill |

### Achievement System

```
Categories:
├── Milestones (first lesson, first perfect)
├── Lessons (10, 25, 50, 100 completed)
├── Streaks (7, 14, 30, 90 days)
├── XP (100, 500, 1000, 5000 earned)
├── Mastery (unit complete, all units)
└── Special (time-based achievements)

Rarities: Common → Uncommon → Rare → Epic → Legendary
```

## Services

### SpeechAssessmentService

```
Input: Audio (WAV) + Reference Text
Output: Scores + Word-level Feedback

Flow:
1. Record audio (16kHz, mono, PCM)
2. Encode to base64
3. POST to /api/v1/assess
4. Parse response into LessonFeedback
5. Save PracticeRecord to SwiftData
```

### TTSService

```
Input: Korean Text + Voice + Speed
Output: Audio playback

Flow:
1. Check in-memory cache
2. If miss: POST to /api/v1/tts
3. Decode base64 MP3
4. Cache audio data
5. Play via AVAudioPlayer
```

### AudioRecordingService

```
Recording: AVAudioRecorder → WAV file
Playback: AVAudioPlayer
Metering: 48 samples for waveform visualization
```

## API Architecture

### Cloudflare Workers

```typescript
// Router pattern
export default {
    async fetch(request: Request, env: Env): Promise<Response> {
        const url = new URL(request.url);

        switch (url.pathname) {
            case '/api/v1/assess':
                return handleAssess(request, env);
            case '/api/v1/tts':
                return handleTTS(request, env);
            case '/api/v1/health':
                return handleHealth();
        }
    }
}
```

### Security

- API keys stored as Cloudflare Secrets
- Rate limiting: 100 requests/IP/day (production)
- CORS enabled for all origins
- Audio size limit: 5MB

### Infrastructure (Terraform)

```hcl
resource "cloudflare_worker_script" "langu_api" {
    name    = "langu-api"
    content = file("dist/index.js")

    secret_text_binding {
        name = "AZURE_SPEECH_KEY"
    }
    secret_text_binding {
        name = "GOOGLE_TTS_API_KEY"
    }
}

resource "cloudflare_ruleset" "rate_limit" {
    # Per-IP rate limiting
}
```

## Design System

### Spacing

```swift
enum AppSpacing {
    static let xs = 4.0
    static let sm = 8.0
    static let md = 12.0
    static let lg = 16.0
    static let xl = 20.0
    static let xxl = 24.0
    static let xxxl = 32.0
}
```

### Colors

```swift
// Score colors
90-100: appGreen (#22C55E)
70-89:  appBlue (#3B82F6)
50-69:  appYellow (#F59E0B)
0-49:   appRed (#EF4444)

// UI colors
appBg, appCardBg, appSurface
appTextPrimary, appTextSecondary, appTextMuted
```

### Animations

```swift
enum AppAnimation {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let quick = Animation.easeOut(duration: 0.2)
}

// Pop-in entrance animation
.popIn(isVisible: appeared, delay: 0.1)
```

## Error Handling

```swift
enum AppError: Error {
    case network(NetworkError)
    case audio(AudioError)
    case data(DataError)
}

// Recovery actions
enum RecoveryAction {
    case retry(action: () async -> Void)
    case openSettings
    case dismiss(action: (() -> Void)?)
}
```

## Data Flow

### Lesson Practice Flow

```
1. User selects lesson
2. LessonView loads, preloads TTS
3. User taps record button
4. AudioRecordingService captures audio
5. User releases, audio sent to API
6. SpeechAssessmentService parses response
7. PracticeRecord saved to SwiftData
8. FeedbackView displays results
9. AchievementService checks unlocks
10. LessonProgressService updates state
```

### Achievement Unlock Flow

```
1. PracticeRecord inserted
2. ContentView detects change via @Query
3. AchievementService.checkAndUnlock() called
4. All criteria evaluated
5. New unlocks added to UserDefaults
6. AchievementUnlockOverlay displays toast
```
