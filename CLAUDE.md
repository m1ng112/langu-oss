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

**Duolingo-inspired rounded design:**
- Rounded corners (12-28pt radius)
- Soft shadows
- Capsule-shaped buttons
- Playful emoji integration
- Spring animations

### Colors

```swift
appGreen:    #22C55E  // Success, primary action
appBlue:     #3B82F6  // Info, links
appPurple:   #8B5CF6  // Accent
appYellow:   #F59E0B  // Warning, XP
appOrange:   #F97316  // Accent
appRed:      #EF4444  // Error, needs improvement

// Score colors (use Color.scoreColor(for: score))
90-100: appGreen | 70-89: appBlue | 50-69: appYellow | 0-49: appRed
```

### Spacing / Radius / Typography

```swift
AppSpacing: xs(4) sm(8) md(12) lg(16) xl(20) xxl(24) xxxl(32)
AppRadius:  sm(12) md(16) lg(20) xl(24) xxl(28) pill(999)
AppFont:    title() headline() body() caption() timer() koreanPrompt()
AppAnimation: spring, springBouncy, quick, slow
AppShadow:  sm, md, lg
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
