# Langu - Project Guidelines

## Project Overview

**Langu** is a language pronunciation learning app with AI-powered speech assessment and content generation.

### Tech Stack
- **iOS**: SwiftUI, SwiftData, AVFoundation, iOS 17+
- **Backend**: Cloudflare Workers (TypeScript)
- **Content Generation**: TypeScript CLI with Anthropic API
- **APIs**: Azure Speech Services, Google Cloud TTS, Anthropic Claude
- **Infrastructure**: Terraform

### Repository Structure
```
ios/                  # iOS app (SwiftUI)
api/                  # Cloudflare Workers backend
tools/
  content-generator/  # AI content generation CLI
docs/                 # Technical documentation
```

### Content System
- Content is stored as JSON in `ios/langu/Resources/Content/`
- `ContentLoader` reads JSON from the app bundle at runtime
- `tools/content-generator/` generates new content via Anthropic API
- Content types: units (with lessons), stories, themes

## Design System

### Visual Style

**"Minimal x Energetic" design:**
- No box-shadows; depth via background color hierarchy (surface -> surface2 -> white)
- Only 1 looping animation: streak flame pulse (2s)
- Interactions use fast transitions (0.12s tap, 0.15s hover)
- Accent is #ff4c2b only. No purple gradients.
- Fonts: Syne (headings/numbers) + DM Sans (body/UI)

### Colors

```swift
// Brand
appAccent:   #FF4C2B  // CTA, streak, XP bar, active state
accentWarm:  #FF8C42  // Gradient pair with accent
accentLight: #FFF1EE  // Light accent background

// Semantic
appGreen:    #1DBA82  // SRS safe, success (asset catalog)
appGold:     #F5A623  // SRS today, warning
appBlue:     #2F6BFF  // Info, vocabulary

// Neutrals
ink:         #0E0E0F  // Primary text
ink2:        #3A3A3C  // Secondary text
ink3:        #8E8E93  // Placeholder, caption
surface:     #E8DCC8  // App background (warm parchment)
surface2:    #D6C9B0  // Card background (warm stone)

// Score colors (use Color.scoreColor(for: score))
90-100: appGreen | 70-89: appBlue | 50-69: appGold | 0-49: appAccent
```

### Spacing / Radius / Typography

```swift
AppSpacing: xs(4) sm(8) md(12) lg(16) xl(20) xxl(24) xxxl(32) huge(40)
AppRadius:  sm(12) md(12) lg(16) xl(20) xxl(20) pill(999)
AppFont:    title() headline() body() caption() timer() koreanPrompt() scoreDisplay() sectionLabel() cardTitle()
AppAnimation: pulse, fadeUp, tap, hover, stagger(index:)
AppShadow:  zeroed out (use color hierarchy instead)
```

## Architecture Patterns

### State Management
```swift
@Observable final class SomeService { ... }
@Environment(AppState.self) private var appState
```

### Navigation
```swift
appState.navigateToLesson(lesson)
appState.navigateToFeedback(lesson, feedback)
```

### Content Loading
```swift
// Content is loaded from bundled JSON files
ContentLoader.units    // [LessonUnit] — each unit contains its lessons
ContentLoader.lessons  // [Lesson] — flattened from all units
ContentLoader.stories  // [Story]
ContentLoader.themes   // [Theme]
```

### API Configuration
```swift
// APIConfig provides endpoints (configurable via LANGU_API_URL env var)
APIConfig.assessEndpoint
APIConfig.ttsEndpoint
APIConfig.evaluateThemeEndpoint
```

## Code Conventions

### File Organization
```
ios/langu/
├── Models/           # Data structures (Codable)
├── Resources/Content # JSON content files
├── Views/            # SwiftUI views (grouped by feature)
├── Services/         # Business logic, ContentLoader, APIConfig
├── Theme/            # Design system
└── Navigation/       # AppState, routing
```

### View Structure
```swift
struct SomeView: View {
    // MARK: - Environment
    @Environment(AppState.self) private var appState
    // MARK: - State
    @State private var appeared = false
    // MARK: - Body
    var body: some View { ... }
    // MARK: - Subviews
    private var headerSection: some View { ... }
    // MARK: - Actions
    private func handleTap() { ... }
}
```

## Testing

```bash
# iOS
xcodebuild -project ios/langu.xcodeproj -scheme langu -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' build
xcodebuild -project ios/langu.xcodeproj -scheme langu test -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'

# API
cd api && npm run typecheck

# Content Generator
cd tools/content-generator && npm run build
```

## Deployment

### Backend API
```bash
cd api
npm run deploy:prod
wrangler secret put AZURE_SPEECH_KEY
wrangler secret put GOOGLE_TTS_API_KEY
wrangler secret put ANTHROPIC_API_KEY
```

## Documentation
- `docs/ARCHITECTURE.md` - System design
- `docs/API.md` - API reference
- `docs/FEATURES.md` - Feature list
