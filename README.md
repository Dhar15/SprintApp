# Sprint — Swipe-Based Daily Learning App

> Replace mindless scrolling with intelligent, addictive micro-learning.  
> Live dictionary definitions. Real news. Zero friction.

---

## Installing Flutter 

### Windows

```powershell
# Option 1: winget (recommended, Windows 10+)
winget install Google.Flutter

# Option 2: Manual
# 1. Download the Flutter SDK zip from https://docs.flutter.dev/get-started/install/windows
# 2. Extract to C:\flutter  (avoid paths with spaces)
# 3. Add C:\flutter\bin to your PATH environment variable:
#    Search → "Edit environment variables" → System Variables → Path → Edit → New → C:\flutter\bin
# 4. Restart your terminal, then verify:
flutter --version
```

### macOS

```bash
# Option 1: Homebrew (easiest)
brew install --cask flutter

# Option 2: Manual
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.19.0-stable.zip
unzip flutter_macos_arm64_3.19.0-stable.zip -d ~/development
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

flutter --version
```

### Linux (Ubuntu/Debian)

```bash
sudo snap install flutter --classic
flutter --version
```

### Verify Everything Is Ready

```bash
flutter doctor
```
You need ✓ on Flutter, ✓ on Android toolchain (or Xcode for iOS). Run `flutter doctor --android-licenses` to accept Android licenses if prompted.

---

## Running the App

```bash
# 1. Extract the zip, navigate into it
unzip sprint_app.zip
cd sprint_app

# 2. Install Flutter dependencies
flutter pub get

# 3. Connect an Android device (enable USB debugging)
#    OR start an emulator:
#    Android Studio → Device Manager → Start an emulator

# 4. Check Flutter can see your device
flutter devices

# 5. Run the app
flutter run

# 6. (Optional) Build a release APK to install directly
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
# Transfer to phone and install, or:
flutter install   # installs directly to connected device
```

---

## Architecture

```
sprint_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/app_theme.dart               ← Colors, fonts (DM Sans), design tokens
│   │   └── utils/
│   │       ├── storage_service.dart            ← SharedPreferences: word cache, stats, streak
│   │       └── app_config.dart                 ← API keys (gitignored)
│   │
│   └── features/
│       ├── home/screens/home_screen.dart        ← Home with streak, stats, greeting
│       │
│       ├── word_sprint/
│       │   ├── models/word_model.dart           ← WordModel + fromDictionaryApi factory
│       │   ├── services/
│       │   │   ├── word_sprint_service.dart     ← Parallel API fetch, session logic, quiz gen
│       │   │   └── word_sprint_provider.dart    ← State machine (idle→loading→words→quiz→summary)
│       │   ├── screens/word_sprint_screen.dart
│       │   └── widgets/
│       │       ├── word_card.dart               ← Word, phonetic, POS, meaning, example
│       │       └── quiz_card.dart               ← MCQ with instant feedback
│       │
│       └── news_sprint/
│           ├── models/news_model.dart
│           ├── services/
│           │   ├── news_sprint_service.dart     ← NewsAPI fetch, Groq quiz generation
│           │   └── news_sprint_provider.dart    ← State machine
│           ├── screens/news_sprint_screen.dart
│           └── widgets/
│               ├── news_card.dart               ← Article with Read More link
│               └── news_quiz_card.dart          ← AI-generated MCQ with explanation
│
└── assets/data/word_list.json                   ← 315 GRE/SAT word strings (no definitions)
```

---

## 📡 APIs Used

### Word Sprint — Free Dictionary API
- **URL:** `https://api.dictionaryapi.dev/api/v2/entries/en/{word}`
- **Auth:** None required. Completely free.
- **What it returns:** Full definition, part of speech, phonetic pronunciation, usage examples
- **Caching:** Each word definition is cached to SharedPreferences on first fetch — subsequent sessions are instant and work offline

### News Sprint — NewsAPI
- **URL:** `https://newsapi.org/v2/everything?language=en&sortBy=publishedAt`
- **Auth:** Free API key from newsapi.org
- **Cache:** Date-based — same articles all day, auto-refreshes every morning
- **Fallback:** 8 built-in static articles if network fails

### News Quiz — GroqAPI
- **URL:** `https://api.groq.com/openai/v1/chat/completions`
- **Auth:** Free API key from console.groq.com
- **What it does:**  Reads each article summary and generates a factual MCQ quiz with 4 plausible options and an explanation
- **Cost:** Free tier, 14,400 requests/day

---

## How the Word Sprint API Flow Works

```
Session start
  │
  ├─ Load word_list.json (315 strings) — instant, local
  ├─ Select 12 words: 70% unseen + 30% review
  │
  ├─ Fetch all 12 definitions in parallel:
  │     ├─ Cached in SharedPreferences? → return instantly (0ms)
  │     └─ Not cached? → GET dictionaryapi.dev → parse → cache → return
  │
  ├─ Swipe through word cards (word, phonetic, POS, meaning, example)
  ├─ Auto-start 8-question MCQ quiz
  └─ Summary screen: words learned + accuracy %

From second session onwards: fully offline, all definitions cached.
```

---

## How the News Sprint API Flow Works

```
Session start
  │
  ├─ Check date-based cache → today's articles already fetched? serve instantly
  ├─ Otherwise: GET newsapi.org → parse + summarize → cache for the day
  │
  ├─ Swipe through 8 news cards (headline, summary, Read More link)
  │
  ├─ After last article → Groq generates quiz questions in parallel:
  │     For each article: send title + summary → receive question + 4 options + explanation
  │
  └─ Summary screen: articles read + quiz score DU```

---

## ⚙️ Customisation

### Edit
`assets/data/word_list.json` is just a flat JSON array of strings:
```json
["Ephemeral", "Sardonic", "Laconic", "YourCustomWord", ...]
```
The Free Dictionary API covers virtually any English word — add whatever you want.

### Change session size
```dart
// In lib/features/word_sprint/services/word_sprint_service.dart
static const int sessionSize = 12;  // words per session
static const int quizSize    = 8;   // quiz questions
```

### Change news topics
```dart
// lib/features/news_sprint/services/news_sprint_service.dart
// Edit the q= parameter:
`'...&q=world OR technology OR business&...'`
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter: command not found` | Add Flutter `bin/` to your PATH and restart terminal |
| `flutter doctor` shows Android SDK issues | Install Android Studio, accept licenses: `flutter doctor --android-licenses` |
| Words show "No definition available" | Check internet connection. After first fetch, works offline. |
| News won't load | rss2json free tier may be rate-limited. App falls back to 8 built-in articles automatically. |
| Build fails: `minSdkVersion` too low | Set `minSdkVersion 21` in `android/app/build.gradle` |
| Fonts look wrong in emulator | Google Fonts download on first run; needs internet once |

---

## Roadmap

| # | Feature | Status |
|---|---------|--------|
| ✅ | Home screen, Word Sprint, News Sprint | Done |
| ✅ | Live definitions via Free Dictionary API | Done |
| ✅ | Word definition cache (works offline after first use) | Done |
| ✅ | Phonetic + part-of-speech display | Done |
| 🔲 | Spaced repetition algorithm (SM-2) | Next |
| 🔲 | Push notification | Next |
| 🔲 | Category filter for news | Planned |
| 🔲 | iOS Support | Planned |

---

*Flutter 3.41 · Android 5.0+ · No login · No ads · Works offline (Word Sprint after first session)*
