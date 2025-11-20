/// AI Prompts Configuration
///
/// This file contains all the prompts used for AI analysis.
/// Feel free to edit these to customize how the AI organizes your thoughts!
///
class PromptsConfig {
  /// Main prompt for analyzing a single thought
  /// This is used when you capture a new thought
  static String thoughtAnalysisPrompt(String text) {
    return '''
Analyze the following thought/idea and provide a structured response:

"$text"

Please respond in the following JSON format:
{
  "title": "A short, catchy title (3-7 words)",
  "summary": "A concise 1-2 sentence summary",
  "category": "One of: Personal, Work, Ideas, Reminders, Ministry, Business, or Other",
  "tags": ["tag1", "tag2", "tag3"],
  "needs_reminder": true/false,
  "suggested_reminder_time": "If needs_reminder is true, suggest when (e.g., 'tomorrow 9am', 'in 2 hours', 'next week')",
  "action_items": ["List any actionable items extracted from the thought"],
  "is_checklist": true/false,
  "checklist_items": ["If is_checklist is true, list each task separately"]
}

Focus on:
1. Creating a memorable title
2. Capturing the essence of the thought
3. Identifying the best category
4. Extracting relevant tags (max 5)
5. Determining if this requires follow-up/reminder
6. Identifying concrete action items
7. Detecting if this is a to-do list or checklist
''';
  }

  /// Prompt for batch analyzing multiple thoughts
  /// Used to find patterns across your notes
  static String batchAnalysisPrompt(List<String> thoughts) {
    final thoughtsList = thoughts
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return '''
Analyze these related thoughts and identify patterns:

$thoughtsList

Provide insights in JSON format:
{
  "common_themes": ["theme1", "theme2"],
  "suggested_actions": ["action1", "action2"],
  "priority_items": [1, 3, 5],
  "insights": "Overall insight about these thoughts"
}
''';
  }

  /// Prompt for suggesting better organization
  /// Used when you want AI to help reorganize your notes
  static String organizationSuggestionPrompt(List<String> categories) {
    return '''
Based on these existing categories: ${categories.join(', ')}

Suggest improvements to the organization system:
1. Are there missing categories that would be useful?
2. Could any categories be merged or split?
3. What's the best way to organize these thoughts?

Provide suggestions in JSON format:
{
  "suggested_categories": ["new category 1", "new category 2"],
  "merge_suggestions": [{"merge": ["cat1", "cat2"], "into": "new name"}],
  "organization_tips": "General advice for better organization"
}
''';
  }

  /// Prompt for generating weekly insights
  /// Used to create a summary of your week's thoughts
  static String weeklyInsightsPrompt(List<String> weekThoughts) {
    final thoughtsList = weekThoughts
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return '''
Analyze this week's thoughts and create an insightful summary:

$thoughtsList

Provide a weekly insight report in JSON format:
{
  "week_summary": "Overall summary of the week",
  "top_themes": ["theme1", "theme2", "theme3"],
  "completed_actions": 5,
  "pending_actions": 3,
  "productivity_insight": "Insight about productivity patterns",
  "recommendations": ["recommendation1", "recommendation2"]
}
''';
  }

  /// System message for the AI
  /// Sets the tone and behavior of the AI assistant
  static const String systemMessage = '''
You are a helpful personal assistant that helps organize thoughts, ideas, and tasks.

Your role:
- Analyze thoughts and create clear, concise summaries
- Categorize content accurately
- Extract relevant tags and action items
- Detect when reminders are needed
- Identify checklists and to-do items
- Provide insights without being overly formal

Tone:
- Professional but friendly
- Concise and clear
- Practical and action-oriented
- Respectful of the user's time

Always respond in valid JSON format as specified in the prompts.
''';

  /// Tips for users on how to get the best AI analysis
  static const String usageTips = '''
Tips for Better AI Analysis:

1. Be Specific: "Call John about Q4 budget tomorrow" vs "Call John"

2. Include Context: "Holiday program at Kempton Park school - need 30 cubes and instructor" vs "Need cubes"

3. Natural Language: Speak/write naturally - the AI understands conversational text

4. Action Words: Use verbs for tasks - "Schedule", "Follow up", "Order", "Plan"

5. Time References: Include when things should happen - "tomorrow", "next week", "by Friday"

6. Multiple Items: List multiple tasks in one thought - AI will create checklists automatically

Examples:
✅ "Schedule Cubing Hub holiday program for December 15th at Kempton Park. Need to order 30 speed cubes and confirm instructor availability."
✅ "Prayer request: John's family needs support this week. Follow up on Thursday."
✅ "Business idea: Create mobile app for cube timer with tutorial videos. Research competitors this weekend."
''';
}
