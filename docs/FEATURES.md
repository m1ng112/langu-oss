# Features

## Implemented Features

### P0 - Core (MVP)

| Feature | Status | Description |
|---------|--------|-------------|
| Lesson Display | ✅ | Korean text, romanization, translation, hints |
| Audio Recording | ✅ | WAV recording with real-time waveform |
| Speech Assessment | ✅ | 5-axis scoring via Azure Speech API |
| Feedback View | ✅ | Score display with detailed breakdown |
| Basic Navigation | ✅ | Tab-based navigation with NavigationStack |
| Local Persistence | ✅ | SwiftData for practice records |

### P1 - Engagement

| Feature | Status | Description |
|---------|--------|-------------|
| XP System | ✅ | 10-50 XP per lesson based on score |
| Streak Tracking | ✅ | Consecutive daily practice |
| Daily Goals | ✅ | 1-10 lessons/day (configurable) |
| Progress Tracking | ✅ | Unit/lesson completion status |
| Achievement System | ✅ | 27+ badges, 6 categories, 5 rarities |
| Statistics | ✅ | Charts for weekly activity and trends |

### P2 - Polish

| Feature | Status | Description |
|---------|--------|-------------|
| Onboarding | ✅ | 3-page welcome flow |
| Error Handling | ✅ | User-friendly error messages with recovery |
| Accessibility | ✅ | VoiceOver, Dynamic Type, Haptics |
| Dark Mode | ✅ | System/Light/Dark modes |
| Animations | ✅ | Spring animations, pop-in effects |
| Design Overhaul | ✅ | Duolingo-style rounded design |

### P3 - Extended

| Feature | Status | Description |
|---------|--------|-------------|
| Push Notifications | ✅ | Daily reminder scheduling |
| Audio Playback | ✅ | Review recorded audio |
| TTS Integration | ✅ | Reference pronunciation with Google TTS |
| Short Stories | ✅ | Multi-sentence reading practice |
| Word-level Feedback | ✅ | Per-word accuracy and error detection |
| Recognition Comparison | ✅ | Show recognized vs reference text |

---

## Feature Details

### Lessons

**Units (6 total):**
1. Greetings (안녕하세요, 감사합니다, etc.)
2. Daily Phrases
3. Shopping
4. Restaurant
5. Transportation
6. Self-Introduction

**Each Lesson Contains:**
- Korean text
- Romanization (toggleable)
- English translation
- Pronunciation hint
- Emoji
- Difficulty level (Beginner/Intermediate/Advanced)

**Progression:**
- Lessons unlock sequentially within units
- Units unlock when previous unit is complete
- Score ≥70% required to unlock next lesson

### Speech Assessment

**Scoring Axes:**
| Axis | Weight | Description |
|------|--------|-------------|
| Pronunciation | 30% | Overall pronunciation quality |
| Accuracy | 30% | Phoneme-level accuracy |
| Fluency | 20% | Speech flow and pacing |
| Prosody | 20% | Intonation and rhythm |
| Completeness | Info | Percentage of text spoken |

**Word-level Feedback:**
- Individual accuracy scores per word
- Error types: None, Mispronunciation, Omission, Insertion
- Color-coded chips (Green/Yellow/Red)

**Overall Score Mapping:**
| Score | Stars | XP | Emoji |
|-------|-------|-----|-------|
| 90-100 | ★★★ | 50 | 🎉 |
| 70-89 | ★★ | 35 | 😊 |
| 50-69 | ★ | 20 | 💪 |
| 0-49 | - | 10 | 🔄 |

### Text-to-Speech

**Voices:**
- 4 WaveNet voices (high quality): 2 female, 2 male
- 4 Standard voices: 2 female, 2 male
- Default: ko-KR-Wavenet-A (female)

**Features:**
- Adjustable speaking rate (0.25-4.0x)
- In-memory caching
- Preload on lesson load

### Short Stories

**Available Stories (5):**
1. Morning Routine (Beginner, 7 sentences)
2. At the Café (Beginner, 7 sentences)
3. Weekend Plans (Intermediate, 7 sentences)
4. First Day at Work (Intermediate, 7 sentences)
5. Visiting Seoul (Advanced, 7 sentences)

**Practice Modes:**
- **Full Mode**: Record entire story at once
- **Sentence Mode**: Practice sentence by sentence with auto-advance

**Each Story Contains:**
- Korean sentences with romanization
- Full English translation
- Sentence-level scoring
- Average score calculation

### Achievements

**Categories:**
| Category | Examples |
|----------|----------|
| Milestones | First Lesson, First Perfect Score |
| Lessons | 10, 25, 50, 100 Lessons |
| Streaks | 7, 14, 30, 90 Day Streaks |
| XP | 100, 500, 1000, 5000 XP |
| Mastery | Unit Complete, All Units |
| Special | Early Bird, Night Owl, Weekend Warrior |

**Rarities:**
| Rarity | XP Bonus | Example |
|--------|----------|---------|
| Common | 10 | First Steps |
| Uncommon | 25 | Week Warrior |
| Rare | 50 | Perfect Week |
| Epic | 100 | Month Master |
| Legendary | 200 | Korean Champion |

### Settings

| Setting | Options | Default |
|---------|---------|---------|
| Appearance | System/Light/Dark | System |
| Daily Goal | 1-10 lessons | 3 |
| Notifications | On/Off | Off |
| Reminder Time | Time picker | 7:00 PM |

---

## Planned Features

### P4 - Future

| Feature | Priority | Description |
|---------|----------|-------------|
| Localization | Medium | Korean/Japanese UI |
| Offline Mode | Medium | Offline lesson playback |
| Social Features | Low | Leaderboards, friends |
| Custom Lessons | Low | User-created content |
| Spaced Repetition | Medium | Review scheduling |
| Pronunciation Guides | Medium | Visual mouth/tongue position |

---

## Technical Constraints

| Constraint | Limit |
|------------|-------|
| Audio recording | Max 60 seconds |
| Audio file size | 5 MB (base64) |
| TTS text length | 500 characters |
| API rate limit | 100 requests/day/IP |
| Min iOS version | iOS 17.0 |
