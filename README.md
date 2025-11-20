# Thought Recorder

A voice-first "second brain" app that captures your thoughts, ideas, and reminders instantly.

## Features

- **Quick Voice Capture**: Record your thoughts with one tap
- **Text Input**: Type when speaking isn't convenient
- **AI Organization**: Automatic categorization and summarization using Claude AI
- **Smart Reminders**: Android reminders for actionable items
- **Search & Retrieve**: Find your thoughts quickly
- **Preserve Originals**: AI summaries alongside original transcriptions

## Tech Stack

- **Flutter**: Cross-platform mobile framework
- **Supabase**: Backend, database, and authentication
- **Speech-to-Text**: Voice transcription
- **Claude AI**: Intelligent organization and analysis
- **Android Reminders**: Native reminder integration

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Configure Supabase:
   - Create a Supabase project
   - Update `lib/core/config/supabase_config.dart` with your credentials

3. Configure Claude AI:
   - Get an Anthropic API key
   - Update `lib/core/config/api_config.dart`

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # Configuration files
│   ├── services/        # Core services
│   └── models/          # Data models
├── features/            # Feature modules
│   ├── home/
│   ├── capture/
│   ├── thought_detail/
│   ├── categories/
│   └── search/
└── shared/              # Shared widgets
```

## License

MIT
