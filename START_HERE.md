# 🚀 START HERE - 5 Minute Setup!

## ⚡ QUICK TEST (1 Minute - No Setup!)

**Want to test the app immediately without any setup?**

1. Copy the example config files:
   ```bash
   cp lib/core/config/supabase_config.dart.example lib/core/config/supabase_config.dart
   cp lib/core/config/api_config.dart.example lib/core/config/api_config.dart
   ```

2. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

3. Try typing text (not voice yet):
   - Tap mic FAB
   - Switch to "Text" mode
   - Type: "Test note"
   - Tap Save

**Result:** You'll see "Check Supabase configuration!" error - this is NORMAL! You need to set up Supabase first (see below).

---

## 📝 Full Setup (5-10 Minutes)

### Step 1: Database Setup (2 minutes)
1. Go to [supabase.com](https://supabase.com)
2. Sign in or create account
3. Create new project (any name, wait 2 min)
4. Go to **SQL Editor**
5. Click **New Query**
6. Copy/paste **entire** `supabase_schema_updated.sql` file
7. Click **Run**
8. You should see: ✅ "Success. No rows returned"

### Step 2: Get Your Keys (2 minutes)

**Supabase Keys:**
1. In Supabase: Settings → API
2. Copy **Project URL**
3. Copy **anon public** key

**OpenAI Key (Recommended - Cheaper!):**
1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Sign in or create account
3. Click **Create new secret key**
4. Copy the key (starts with `sk-`)
5. Add $5 credit to your account

### Step 3: Create Config Files (IMPORTANT!)

**A) Create Config Files from Examples:**

```bash
# Copy the example files to create your config files
cp lib/core/config/supabase_config.dart.example lib/core/config/supabase_config.dart
cp lib/core/config/api_config.dart.example lib/core/config/api_config.dart
```

**B) Add Supabase Credentials:**

Open: `lib/core/config/supabase_config.dart`

Change:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

To your actual values (keep the quotes!):
```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**C) Add OpenAI Key (Optional for now):**

Open: `lib/core/config/api_config.dart`

Change:
```dart
static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
```

To your actual key:
```dart
static const String openAiApiKey = 'sk-proj-xxxxx';
```

**NOTE:** You can test WITHOUT OpenAI first! The app will work but won't have AI features.

### Step 4: Install Dependencies & Run!

```bash
# Install packages
flutter pub get

# Run the app
flutter run
```

**If you see compilation errors:**
- Make sure you created the config files (step 3A)
- Check there are no syntax errors in your config files
- The placeholder values are OK for now!

---

## ✅ Your First Tests

### Test 1: Basic Text Note (Works WITHOUT AI!)

1. Open app
2. Tap purple microphone FAB
3. Switch to **"Text"** mode
4. Type: **"This is my first test note"**
5. Tap **"Save"**

**What should happen:**
- ✅ Note saves successfully
- ✅ Message: "Thought saved! (Configure AI keys for analysis)"
- ✅ Note appears on home screen
- ❌ No AI summary (you haven't configured AI yet)

**If it fails:** Check your Supabase configuration!

### Test 2: Checklist (Basic Detection, No AI Needed!)

1. Tap mic FAB → Text mode
2. Type:
```
Todo:
- Buy milk
- Call mom
- Finish report
```
3. Tap Save

**What should happen:**
- ✅ Saves as checklist (even without AI!)
- ✅ Creates 3 checkbox items
- ✅ Shows checklist icon
- ✅ Tap card → See checkboxes!

---

## 🤖 Testing With AI (After Adding OpenAI Key)

### Test Voice To-Do List:
1. Open app
2. Tap purple microphone button
3. Tap the large mic icon
4. Say: **"Todo list for tomorrow: Buy groceries, call mom at 2pm, finish project report"**
5. Tap mic again to stop
6. Watch the magic! 🎉

**What happens:**
- ✅ AI detects it's a to-do list
- ✅ Creates 3 separate items
- ✅ Extracts "tomorrow" and "2pm"
- ✅ Creates reminders
- ✅ Shows checklist icon
- ✅ Message: "Checklist saved with 3 items!"

### Test Regular Note:
1. Tap mic button
2. Say: **"Remind me to prepare for Cubing Hub program on December 15th at Kempton Park"**
3. Stop recording

**What happens:**
- ✅ AI creates title: "Cubing Hub Program Preparation"
- ✅ Summary: "Prepare for program at Kempton Park"
- ✅ Category: Business
- ✅ Tags: cubing-hub, program, kempton-park
- ✅ Reminder: December 15th morning
- ✅ Shows reminder badge

---

## 💰 Costs (Don't Worry!)

**OpenAI GPT-3.5-turbo:**
- First 100 thoughts: **$0.20** (20 cents!)
- First 500 thoughts: **$1.00** (one dollar!)
- First 1000 thoughts: **$2.00**

**You won't spend more than a few dollars testing!**

---

## 🐛 Troubleshooting

### "Supabase initialization failed"
- Check your URL starts with `https://`
- Check your key starts with `eyJ`
- No extra spaces in the config file
- Keep the quotes around the values

### "OpenAI API error"
- Check key starts with `sk-`
- Verify you added billing at platform.openai.com
- Make sure you have at least $0.50 credit

### "Speech recognition not available"
- Grant microphone permission when asked
- If on emulator, use a real Android device
- Try text mode instead

### App won't build
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎯 What You Can Do Right Now

### ✅ Already Working:
1. **Voice capture** → Transcribed automatically
2. **Text input** → Type if you prefer
3. **AI analysis** → Categorizes, tags, summarizes
4. **To-do detection** → Recognizes checklists
5. **Date extraction** → "tomorrow", "Friday", "2pm", etc.
6. **Reminders** → Notifications at the right time
7. **Search** → Find anything quickly
8. **Categories** → Auto-organized
9. **Titles** → AI generates catchy titles
10. **Pin notes** → Keep important ones on top

### 🚧 Coming Soon (If You Want):
- ❌ Checkboxes to mark tasks complete (UI only)
- ❌ Progress bars (2/5 done)
- ❌ Edit notes (UI only)
- ❌ Manual category changes (UI only)

**But the core to-do list functionality WORKS!**

---

## 💡 Pro Tips

### For Best To-Do Lists:
```
✅ "Todo for today: task 1, task 2, task 3"
✅ "Shopping list: milk, bread, eggs"
✅ "Project tasks: design mockup by Friday, code feature by Monday"
```

### For Dates:
```
✅ "tomorrow" → Tomorrow at 9am
✅ "tomorrow 2pm" → Tomorrow at 2pm
✅ "Friday" → This Friday at 9am
✅ "December 15th" → Dec 15 at 9am
✅ "in 2 hours" → 2 hours from now
✅ "next week" → 7 days from now
```

### For Categories:
The AI auto-assigns based on content:
- **Business** → Cubing Hub, work stuff
- **Ministry** → Church, prayer, youth group
- **Personal** → Shopping, family, health
- **Ideas** → App ideas, projects
- **Reminders** → Quick tasks, calls
- **Work** → Professional tasks

---

## 🎉 You're Ready!

1. **Run the SQL** in Supabase
2. **Add your keys** to config files
3. **Run the app**
4. **Start capturing!**

Need help? Check:
- **IMPLEMENTATION_COMPLETE.md** - Full feature list
- **WHATS_NEW.md** - All new features
- **prompts_config.dart** - Customize AI behavior

---

**Let's capture some thoughts!** 🚀
