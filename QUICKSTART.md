# Thought Recorder - Quick Start Guide

Get your voice-first "second brain" running in 10 minutes!

## 🚀 Quick Setup (3 Steps)

### 1. Configure Supabase (5 minutes)

**a) Create Supabase Project:**
- Go to [supabase.com](https://supabase.com) and create a free account
- Click "New Project"
- Name it "thought-recorder" (or anything you like)
- Set a strong database password
- Choose a region close to you
- Wait 2 minutes for setup to complete

**b) Create Database Tables:**
- In your project, go to "SQL Editor"
- Click "New Query"
- Copy and paste the entire contents of `supabase_schema.sql`
- Click "Run"
- You should see: "Success. No rows returned"

**c) Get Your API Keys:**
- Go to Settings → API
- Copy your "Project URL" and "anon public" key
- Open `lib/core/config/supabase_config.dart`
- Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY`

### 2. Configure Claude AI (2 minutes)

**a) Get API Key:**
- Go to [console.anthropic.com](https://console.anthropic.com)
- Sign up or log in
- Go to API Keys
- Click "Create Key"
- Copy your key

**b) Add to App:**
- Open `lib/core/config/api_config.dart`
- Replace `YOUR_CLAUDE_API_KEY` with your actual key

### 3. Run the App (3 minutes)

```bash
# Install dependencies
flutter pub get

# Connect your Android device or start emulator
# Then run:
flutter run
```

That's it! 🎉

## 🎤 First Use

1. **Allow Permissions**
   - Grant microphone permission when prompted
   - Allow notifications

2. **Initialize Categories**
   - Tap the "Categories" tab
   - Tap "Initialize Categories"
   - This creates default organization folders

3. **Capture Your First Thought**
   - Go back to "Home" tab
   - Tap the purple microphone button
   - Tap the large microphone icon
   - Speak your thought (e.g., "Remind me to call Sarah about the project tomorrow")
   - Tap to stop
   - Watch the AI transcribe, summarize, and organize it!

## 💡 Usage Tips

### Voice Capture
- Speak naturally - no need to be formal
- The app handles background noise reasonably well
- Longer thoughts (30s - 2min) work best for AI analysis

### Text Mode
- Swipe to "Text" mode if you can't speak
- Great for meetings or quiet environments
- AI still analyzes and organizes your text

### AI Features
- **Summaries**: AI creates a concise version of your thought
- **Categories**: Automatically sorts into Personal, Work, Ideas, etc.
- **Tags**: Extracts key topics for easy searching
- **Reminders**: Detects action items and creates reminders

### Search
- Use the Search tab to find anything
- Search works on both original text and AI summaries
- Try searching by topic, name, or keyword

## 🔧 Troubleshooting

### "Failed to initialize Supabase"
- Check your `supabase_config.dart` has the correct URL and key
- Make sure you ran the SQL schema
- Verify internet connection

### "Microphone permission denied"
- Go to Android Settings → Apps → Thought Recorder → Permissions
- Enable Microphone permission

### "AI analysis failed"
- Check your Claude API key in `api_config.dart`
- Verify you have API credits at console.anthropic.com
- Check internet connection

### App won't build
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Real-World Examples

### For Business (like Donny's Cubing Hub)
- "Schedule holiday program at Kempton Park for December 15th"
- "Follow up with school principal about Rubik's Cube program expansion"
- "Order 50 new speedcubes for upcoming workshops"

### For Ministry
- "Prayer request: John's family needs support this week"
- "Bible study topic idea: Faith in modern challenges"
- "Youth group activity: Team building with worship night"

### For Personal Ideas
- "App idea: Combine meal planning with grocery delivery"
- "Gift idea for mom: Photo album of family memories"
- "Weekend project: Build a raised garden bed"

## 🎯 Best Practices

1. **Capture Immediately**: Don't wait - record thoughts as they come
2. **Review Weekly**: Spend 10 minutes each week reviewing your thoughts
3. **Act on Reminders**: The app creates reminders for action items
4. **Tag Consistently**: AI suggests tags, but you can customize
5. **Search Often**: Use search to recall past ideas

## 🔐 Privacy & Security

- All data is stored in YOUR Supabase database
- Voice recordings are optional (currently transcription-only)
- API keys are stored locally on your device
- No data is shared with third parties

## 📈 Next Steps

After you're comfortable:
- Customize categories for your workflow
- Set up authentication (see SETUP.md)
- Explore batch analysis features
- Add more devices (coming soon)

## 💬 Need Help?

- Check the detailed SETUP.md guide
- Review Flutter documentation: flutter.dev
- Supabase docs: supabase.com/docs
- Anthropic API docs: docs.anthropic.com

---

Built with ❤️ to help you never lose a brilliant idea again!
