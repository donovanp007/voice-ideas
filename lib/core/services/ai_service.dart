import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for AI-powered analysis using Claude
class AiService {
  /// Analyze a thought and generate:
  /// - Summary
  /// - Suggested category
  /// - Tags
  /// - Whether it needs a reminder
  Future<ThoughtAnalysis> analyzeThought(String text) async {
    final response = await http.post(
      Uri.parse(ApiConfig.claudeApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ApiConfig.claudeApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': ApiConfig.claudeModel,
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': _buildAnalysisPrompt(text),
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;

      return _parseAnalysisResponse(content);
    } else {
      throw Exception('Failed to analyze thought: ${response.body}');
    }
  }

  /// Build the prompt for thought analysis
  String _buildAnalysisPrompt(String text) {
    return '''
Analyze the following thought/idea and provide a structured response:

"$text"

Please respond in the following JSON format:
{
  "summary": "A concise 1-2 sentence summary",
  "category": "One of: Personal, Work, Ideas, Reminders, Ministry, Business, or Other",
  "tags": ["tag1", "tag2", "tag3"],
  "needs_reminder": true/false,
  "suggested_reminder_time": "If needs_reminder is true, suggest when (e.g., 'tomorrow 9am', 'in 2 hours', 'next week')",
  "action_items": ["List any actionable items extracted from the thought"]
}

Focus on:
1. Capturing the essence of the thought
2. Identifying the best category
3. Extracting relevant tags (max 5)
4. Determining if this requires follow-up/reminder
5. Identifying concrete action items
''';
  }

  /// Parse Claude's response into a ThoughtAnalysis object
  ThoughtAnalysis _parseAnalysisResponse(String response) {
    try {
      // Extract JSON from response (Claude might wrap it in markdown)
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      return ThoughtAnalysis(
        summary: data['summary'] as String,
        category: data['category'] as String,
        tags: (data['tags'] as List<dynamic>).cast<String>(),
        needsReminder: data['needs_reminder'] as bool? ?? false,
        suggestedReminderTime: data['suggested_reminder_time'] as String?,
        actionItems: (data['action_items'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      // Fallback if parsing fails
      return ThoughtAnalysis(
        summary: response.substring(0, response.length > 200 ? 200 : response.length),
        category: 'Other',
        tags: [],
        needsReminder: false,
        actionItems: [],
      );
    }
  }

  /// Batch analyze multiple thoughts for pattern detection
  Future<BatchAnalysis> batchAnalyzeThoughts(List<String> thoughts) async {
    final response = await http.post(
      Uri.parse(ApiConfig.claudeApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ApiConfig.claudeApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': ApiConfig.claudeModel,
        'max_tokens': 2048,
        'messages': [
          {
            'role': 'user',
            'content': _buildBatchAnalysisPrompt(thoughts),
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;

      return _parseBatchAnalysisResponse(content);
    } else {
      throw Exception('Failed to batch analyze: ${response.body}');
    }
  }

  String _buildBatchAnalysisPrompt(List<String> thoughts) {
    final thoughtsList = thoughts.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');

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

  BatchAnalysis _parseBatchAnalysisResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      return BatchAnalysis(
        commonThemes: (data['common_themes'] as List<dynamic>).cast<String>(),
        suggestedActions: (data['suggested_actions'] as List<dynamic>).cast<String>(),
        priorityItems: (data['priority_items'] as List<dynamic>).cast<int>(),
        insights: data['insights'] as String,
      );
    } catch (e) {
      return BatchAnalysis(
        commonThemes: [],
        suggestedActions: [],
        priorityItems: [],
        insights: response,
      );
    }
  }
}

/// Analysis result for a single thought
class ThoughtAnalysis {
  final String summary;
  final String category;
  final List<String> tags;
  final bool needsReminder;
  final String? suggestedReminderTime;
  final List<String> actionItems;

  ThoughtAnalysis({
    required this.summary,
    required this.category,
    required this.tags,
    required this.needsReminder,
    this.suggestedReminderTime,
    required this.actionItems,
  });
}

/// Batch analysis result for multiple thoughts
class BatchAnalysis {
  final List<String> commonThemes;
  final List<String> suggestedActions;
  final List<int> priorityItems;
  final String insights;

  BatchAnalysis({
    required this.commonThemes,
    required this.suggestedActions,
    required this.priorityItems,
    required this.insights,
  });
}
