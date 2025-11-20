# Thought Recorder - Setup Guide

This guide will help you set up and run the Thought Recorder app.

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- A Supabase account
- An Anthropic API key for Claude AI

## Step 1: Install Flutter

If you haven't already, install Flutter:

```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install

# Add Flutter to your PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

## Step 2: Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)

2. Go to your project's SQL Editor

3. Run the entire `supabase_schema.sql` file to create tables

4. Go to Settings > API to get your credentials:
   - Project URL
   - Anon public key

5. Update `lib/core/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_PROJECT_URL';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

## Step 3: Set Up Claude AI

1. Get an API key from [console.anthropic.com](https://console.anthropic.com)

2. Update `lib/core/config/api_config.dart`:
   ```dart
   static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY';
   ```

## Step 4: Install Dependencies

```bash
flutter pub get
```

## Step 5: Android Configuration

The Android permissions are already configured in `android/app/src/main/AndroidManifest.xml`.

Make sure you have:
- Microphone permission
- Internet permission
- Storage permissions
- Notification permissions

## Step 6: Run the App

### On Android Device/Emulator

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run

# Or run in release mode
flutter run --release
```

## Features to Test

1. **Voice Capture**
   - Tap the microphone FAB on the home screen
   - Tap the large microphone icon to start recording
   - Speak your thought
   - Tap again to stop
   - The app will transcribe and save automatically

2. **Text Capture**
   - Tap the microphone FAB
   - Switch to "Text" mode
   - Type your thought
   - Tap "Save Thought"

3. **AI Organization**
   - After saving, the AI will:
     - Generate a summary
     - Suggest a category
     - Extract tags
     - Determine if a reminder is needed

4. **Categories**
   - Go to the Categories tab
   - Tap "Initialize Categories" to create defaults
   - View thoughts by category

5. **Search**
   - Go to the Search tab
   - Type keywords to find thoughts
   - Searches both original text and AI summaries

## Customization

### Change App Name

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="Your App Name"
```

### Change App Icon

Replace the launcher icons in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

Or use [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons):

```bash
flutter pub add dev:flutter_launcher_icons
```

### Add More Categories

Edit the default categories in `lib/core/models/category.dart`:
```dart
static List<Category> getDefaultCategories(String userId) {
  return [
    // Add your custom categories here
  ];
}
```

## Troubleshooting

### Microphone Not Working

1. Check permissions in Android settings
2. Grant microphone permission when prompted
3. Ensure you're running on a physical device (emulators may have issues)

### Supabase Connection Error

1. Verify your Supabase URL and key
2. Check your internet connection
3. Ensure the SQL schema was run successfully

### AI Not Working

1. Verify your Claude API key
2. Check you have API credits
3. Ensure internet connectivity

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Development Tips

### Hot Reload

While the app is running:
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Debug Console

Use Flutter DevTools:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Logging

The app uses print statements for debugging. View logs:
```bash
flutter logs
```

## Production Deployment

Before releasing to production:

1. **Implement proper authentication**
   - Use Supabase Auth
   - Update RLS policies
   - Secure user data

2. **Update RLS policies** in Supabase:
   ```sql
   -- Example: User-specific policies
   CREATE POLICY "Users can only view their thoughts"
   ON thoughts FOR SELECT
   USING (auth.uid()::text = user_id);
   ```

3. **Set up proper app signing**
   - Create a keystore
   - Update `android/app/build.gradle`

4. **Test on multiple devices**
   - Different Android versions
   - Various screen sizes

5. **Optimize performance**
   - Enable code obfuscation
   - Minimize app size
   - Test on low-end devices

## Next Steps

- Add user authentication
- Implement audio playback
- Add export functionality
- Create widgets for quick capture
- Add offline mode
- Implement data sync
- Add sharing capabilities

## Support

For issues or questions:
- Check the Flutter documentation
- Review Supabase docs
- Consult the Anthropic API docs

## License

MIT License - Feel free to use and modify as needed!
