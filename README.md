# Dahlia

[Japanese / 日本語](README_ja.md)

A macOS native real-time transcription app. Captures microphone and system audio simultaneously, transcribes speech on-device, and optionally generates LLM-powered summaries.

## Features

- **Dual Audio Capture** — Record microphone (AVAudioEngine) and system audio (ScreenCaptureKit) at the same time
- **On-Device Transcription** — Real-time speech-to-text using Apple Speech framework
- **LLM Summaries** — Generate structured summaries via OpenAI-compatible API (optional)
- **Project Management** — Organize transcripts into vault/project hierarchy synced with filesystem folders
- **Meeting Detection** — Automatically detect meeting sessions with 3-layer detection
- **Screenshot Capture** — Attach screenshots to transcripts for multimodal summaries
- **Bilingual UI** — Japanese (primary) and English

## Requirements

- macOS 26+
- Swift 6.2
- Xcode 26+ (for Swift toolchain)

## Build & Run

```bash
# Debug build and run (unsigned)
swift build && swift run

# Debug build with code signing (enables Data Protection Keychain + Touch ID)
./scripts/run-dev.sh

# Build release .app bundle
./scripts/build-app.sh && open Dahlia.app

# Lint
./scripts/lint.sh
```

> **Note:** `swift run` produces an unsigned binary and cannot use Data Protection Keychain. Use `run-dev.sh` for full functionality.

## Architecture

```
AudioCaptureManager (mic)
SystemAudioCaptureManager (system audio)
    ↓ onAudioBuffer
AudioBufferBridge → AsyncStream
    ↓
SpeechTranscriberService (per source)
    ↓ AsyncSequence
TranscriptStore (200ms throttle)
    ↓ Combine debounce(500ms)
TranscriptPersistenceService → SQLite (GRDB)
```

### Project Structure

```
Sources/Dahlia/
├── Audio/          # Audio capture (mic & system)
├── Database/       # GRDB models, migrations, repository
├── Models/         # Domain models
├── Services/       # LLM, vault sync, meeting detection, keychain
├── Speech/         # Speech transcription pipeline
├── Utilities/      # Helpers (UUID v7, localization, etc.)
├── ViewModels/     # CaptionViewModel, SidebarViewModel
├── Views/          # SwiftUI views
└── Resources/      # Localized strings, assets
```

## Dependencies

- [GRDB.swift](https://github.com/groue/GRDB.swift) — SQLite toolkit

## License

All rights reserved.
