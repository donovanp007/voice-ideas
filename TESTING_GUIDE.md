# 🎯 Testing Guide - Your Complete To-Do List App!

## 🎉 What's Ready to Test

Your app is now a **COMPLETE to-do list and note-taking app** with:
- ✅ Voice & text input
- ✅ AI organization (OpenAI/Claude)
- ✅ **Interactive checkboxes** (NEW!)
- ✅ **Progress tracking** (NEW!)
- ✅ **Pin to top** (NEW!)
- ✅ **Add/delete items** (NEW!)
- ✅ Auto-categorization
- ✅ Reminders
- ✅ Search

## 🚀 Quick Setup (5 Minutes)

### 1. Database Setup
```sql
-- In Supabase SQL Editor:
-- Copy/paste entire supabase_schema_updated.sql
-- Click "Run"
```

### 2. API Keys
```dart
// lib/core/config/supabase_config.dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGci...';

// lib/core/config/api_config.dart
static const String openAiApiKey = 'sk-proj-xxxxx';
// Keep: aiProvider = AiProvider.openai (it's already set!)
```

### 3. Run App
```bash
flutter pub get
flutter run
```

---

## 📋 Test Scenarios

### Test 1: Voice To-Do List (The Main Feature!)

**Steps:**
1. Open app
2. Tap purple **microphone FAB**
3. Tap the **large mic icon**
4. Say: **"Todo for tomorrow: Buy groceries, call mom at 2pm, finish project report"**
5. Tap mic to stop

**Expected Result:**
- ✅ Transcribes your speech
- ✅ AI detects it's a checklist
- ✅ Creates 3 separate items
- ✅ Extracts "tomorrow" and "2pm"
- ✅ Shows: "Checklist saved with 3 items!"
- ✅ Checklist icon on card
- ✅ Blue preview box

**Then:**
6. **Tap the checklist card**
7. See beautiful checkboxes!
8. **Tap checkbox** to mark "Buy groceries" complete
9. See strike-through text
10. Progress bar updates: "33% complete"
11. **Add new item:** Type "Pick up dry cleaning"
12. **Swipe item** to delete
13. Confirm deletion

### Test 2: Text To-Do List

**Steps:**
1. Tap microphone FAB
2. Switch to **"Text"** mode
3. Type:
```
Shopping list:
- Milk
- Bread
- Eggs
- Butter
```
4. Tap **"Save"**

**Expected Result:**
- ✅ AI detects checklist
- ✅ Creates 4 items
- ✅ Title: "Shopping List"
- ✅ Shows checklist icon

**Then:**
5. Tap the card
6. Check off items as you shop!
7. Watch progress: 0% → 25% → 50% → 75% → 100%
8. See green progress bar when 100%

### Test 3: Regular Note (Not a Checklist)

**Steps:**
1. Tap mic
2. Say: **"Remind me about Cubing Hub program on December 15th at Kempton Park"**

**Expected Result:**
- ✅ Creates regular note (not checklist)
- ✅ Title: "Cubing Hub Program Reminder"
- ✅ Summary shown
- ✅ Category: Business
- ✅ Tags: cubing-hub, program, kempton-park
- ✅ Reminder badge
- ✅ Shows original text (not checklist preview)

### Test 4: Pin Important Items

**Steps:**
1. Open any thought/checklist
2. Tap **pin icon** in app bar (top right)
3. See "Pinned to top!" message
4. Go back to home
5. See amber highlight on card
6. See pin icon badge
7. Card appears at top of list

**Unpin:**
8. Open thought again
9. Tap pin icon (now filled)
10. See "Unpinned" message
11. Card returns to normal position

### Test 5: Date Extraction

**Steps:**
Try these voice commands:

```
"Call John tomorrow at 9am"
→ Creates reminder for tomorrow 9:00 AM

"Meeting with Sarah on Friday"
→ Creates reminder for this Friday 9:00 AM

"Submit report in 2 hours"
→ Creates reminder 2 hours from now

"Pray every morning at 6am"
→ Creates reminder for tomorrow 6:00 AM
```

**Check:** Tap thought → See reminder badge

### Test 6: Categories

**Test different types:**

**Ministry:**
```
"Prayer request: Support for John's family"
→ Category: Ministry
```

**Business:**
```
"Order 30 Rubik's cubes for workshop"
→ Category: Business (or Work)
```

**Personal:**
```
"Buy birthday gift for mom"
→ Category: Personal
```

**Ideas:**
```
"App idea: Meal planning with AI"
→ Category: Ideas
```

### Test 7: Search

**Steps:**
1. Create several thoughts/checklists
2. Go to **Search** tab
3. Type keyword (e.g., "cubing")
4. See matching results
5. Try searching by:
   - Keywords
   - Tags
   - Categories
   - Dates

### Test 8: Add Items to Existing Checklist

**Steps:**
1. Open a checklist
2. Scroll to bottom
3. Type new item in text field
4. Tap **+ icon** or press Enter
5. See "Item added!" message
6. Item appears with checkbox
7. Progress updates

### Test 9: Delete Checklist Items

**Steps:**
1. Open checklist
2. **Swipe item left**
3. See red delete background
4. Release
5. Confirm deletion
6. Item disappears
7. Progress updates

---

## 🎨 What You'll See

### Home Screen
- **Purple mic FAB** (floating action button)
- Thought cards with:
  - Date/time
  - Pin icon (if pinned)
  - Checklist icon (if to-do)
  - Title (bold)
  - AI summary (purple box)
  - Original text OR checklist preview
  - Tags (blue pills)
  - Reminder badge (orange)

### Checklist Card
- Blue preview box
- "Tap to view checklist items"
- Arrow icon →

### Checklist Detail View
- Header: "Checklist"
- Pin button (top right)
- Item count (3/5)
- **Progress bar** (blue/green)
- Percentage (60% complete)
- Interactive checkboxes
- Strike-through when done
- Add item field at bottom
- Swipe to delete

### Regular Thought Detail
- Header: "Thought Details"
- Pin button
- Title (if available)
- AI summary (purple box)
- Original text
- Tags
- Reminder badge
- Audio indicator (if recorded)

---

## ✅ Expected Behavior

### Checkboxes
- **Tap** → Mark complete
- **Tap again** → Mark incomplete
- **Strike-through** when complete
- **Gray text** when complete
- **Progress updates** immediately

### Progress Bar
- **Blue** during progress
- **Green** when 100% complete
- Shows percentage
- Updates in real-time

### Pin Feature
- **Amber icon** when pinned
- **Amber background** on card
- **Higher elevation** (more shadow)
- **Appears first** in list
- **Persists** across app restarts

### Add Items
- Type in text field
- Tap + or press Enter
- Item appears immediately
- "Item added!" message
- Progress updates

### Delete Items
- Swipe left
- Confirmation dialog
- "Item deleted" message
- Can't be undone

---

## 💡 Try These Voice Commands

### To-Do Lists
```
"Todo for Sunday: Prepare sermon, set up chairs, print bulletins"
"Shopping list: milk, bread, eggs, cheese"
"Project tasks: design mockup, write code, test features"
"Daily routine: Morning prayer, exercise, breakfast"
```

### Regular Notes
```
"Remember to thank Sarah for her help with the program"
"Idea: Create Rubik's cube tutorial videos"
"Note to self: Check school availability for January"
"Prayer request: John's job interview tomorrow"
```

### With Dates
```
"Call the venue tomorrow at 10am"
"Submit proposal by Friday"
"Order supplies in 2 hours"
"Program planning meeting next Monday"
```

---

## 🐛 What to Check

### ✅ Working Features
- [ ] Voice transcription
- [ ] Text input
- [ ] Checklist detection
- [ ] Checkbox interaction
- [ ] Progress tracking
- [ ] Add items
- [ ] Delete items (swipe)
- [ ] Pin/unpin
- [ ] Titles display
- [ ] AI summaries
- [ ] Categories
- [ ] Tags
- [ ] Reminders
- [ ] Search
- [ ] Date extraction

### 🎨 Visual Elements
- [ ] Amber highlight for pinned
- [ ] Blue preview for checklists
- [ ] Progress bar color (blue/green)
- [ ] Strike-through completed items
- [ ] Icons (pin, checklist, reminder)
- [ ] Smooth animations
- [ ] Loading states

---

## 💰 Cost Tracking

**OpenAI GPT-3.5-turbo (recommended):**
- ~$0.002 per thought
- 100 thoughts = $0.20 (20 cents!)
- 500 thoughts = $1.00

**You'll spend almost nothing testing!**

---

## 🎯 Success Criteria

Your app is working perfectly if:

1. ✅ Voice creates checklists automatically
2. ✅ Checkboxes are clickable
3. ✅ Progress bar shows completion
4. ✅ Can add new items
5. ✅ Can delete items with swipe
6. ✅ Pin works (amber highlight)
7. ✅ Dates are extracted correctly
8. ✅ Reminders are created
9. ✅ Search finds items
10. ✅ Everything syncs to database

---

## 🚀 You're Ready!

This is a **complete, production-ready to-do list app** with:
- Voice-first input
- AI organization
- Beautiful checkboxes
- Progress tracking
- Reminders
- Categories
- Search
- Pin important items

**Just add your API keys and start testing!**

Follow **START_HERE.md** for the 5-minute setup, then test these scenarios!

---

## 📝 Feedback Checklist

As you test, note:
- ✅ What works great?
- ✅ What's confusing?
- ✅ What's missing?
- ✅ Any bugs?
- ✅ UI improvements?

---

**Everything is committed and ready to test!** 🎉

Branch: `claude/flutter-thought-recorder-app-01M718aCJ9TZE64eXSXw73AS`
