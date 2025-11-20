import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/prompts_config.dart';

/// Service for AI-powered analysis using OpenAI
/// More affordable alternative to Claude - great for testing!
class OpenAiService {
  /// Analyze a thought and generate:
  /// - Title
  /// - Summary
  /// - Suggested category
  /// - Tags
  /// - Whether it needs a reminder
  /// - Checklist items if applicable
  Future<ThoughtAnalysis> analyzeThought(String text) async {
    final response = await http.post(
      Uri.parse(ApiConfig.openAiApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
      },
      body: jsonEncode({
        'model': ApiConfig.openAiModel,
        'messages': [
          {
            'role': 'system',
            'content': PromptsConfig.systemMessage,
          },
          {
            'role': 'user',
            'content': PromptsConfig.thoughtAnalysisPrompt(text),
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      return _parseAnalysisResponse(content);
    } else {
      throw Exception('Failed to analyze thought: ${response.body}');
    }
  }

  /// Parse OpenAI's response into a ThoughtAnalysis object
  ThoughtAnalysis _parseAnalysisResponse(String response) {
    try {
      // Extract JSON from response (OpenAI might wrap it in markdown)
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      return ThoughtAnalysis(
        title: data['title'] as String? ?? 'Untitled',
        summary: data['summary'] as String,
        category: data['category'] as String,
        tags: (data['tags'] as List<dynamic>).cast<String>(),
        needsReminder: data['needs_reminder'] as bool? ?? false,
        suggestedReminderTime: data['suggested_reminder_time'] as String?,
        actionItems:
            (data['action_items'] as List<dynamic>?)?.cast<String>() ?? [],
        isChecklist: data['is_checklist'] as bool? ?? false,
        checklistItems:
            (data['checklist_items'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      // Fallback if parsing fails
      return ThoughtAnalysis(
        title: 'Untitled',
        summary: response.substring(
            0, response.length > 200 ? 200 : response.length),
        category: 'Other',
        tags: [],
        needsReminder: false,
        actionItems: [],
        isChecklist: false,
        checklistItems: [],
      );
    }
  }

  /// Batch analyze multiple thoughts for pattern detection
  Future<BatchAnalysis> batchAnalyzeThoughts(List<String> thoughts) async {
    final response = await http.post(
      Uri.parse(ApiConfig.openAiApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
      },
      body: jsonEncode({
        'model': ApiConfig.openAiModel,
        'messages': [
          {
            'role': 'system',
            'content': PromptsConfig.systemMessage,
          },
          {
            'role': 'user',
            'content': PromptsConfig.batchAnalysisPrompt(thoughts),
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      return _parseBatchAnalysisResponse(content);
    } else {
      throw Exception('Failed to batch analyze: ${response.body}');
    }
  }

  BatchAnalysis _parseBatchAnalysisResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonString = response.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonString);

      return BatchAnalysis(
        commonThemes: (data['common_themes'] as List<dynamic>).cast<String>(),
        suggestedActions:
            (data['suggested_actions'] as List<dynamic>).cast<String>(),
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
  final String title;
  final String summary;
  final String category;
  final List<String> tags;
  final bool needsReminder;
  final String? suggestedReminderTime;
  final List<String> actionItems;
  final bool isChecklist;
  final List<String> checklistItems;

  ThoughtAnalysis({
    required this.title,
    required this.summary,
    required this.category,
    required this.tags,
    required this.needsReminder,
    this.suggestedReminderTime,
    required this.actionItems,
    required this.isChecklist,
    required this.checklistItems,
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
