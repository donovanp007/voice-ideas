import '../config/api_config.dart';
import 'ai_service.dart';
import 'openai_service.dart';

/// Unified AI Service that switches between Claude and OpenAI
/// Based on the configuration in ApiConfig
class UnifiedAiService {
  late final dynamic _service;

  UnifiedAiService() {
    // Choose the AI service based on configuration
    switch (ApiConfig.aiProvider) {
      case AiProvider.claude:
        _service = ClaudeAiService();
        break;
      case AiProvider.openai:
        _service = OpenAiService();
        break;
    }
  }

  /// Analyze a thought using the configured AI provider
  Future<ThoughtAnalysis> analyzeThought(String text) async {
    return await _service.analyzeThought(text);
  }

  /// Batch analyze multiple thoughts
  Future<BatchAnalysis> batchAnalyzeThoughts(List<String> thoughts) async {
    return await _service.batchAnalyzeThoughts(thoughts);
  }

  /// Get the current provider name (for debugging/display)
  String get providerName {
    return ApiConfig.aiProvider == AiProvider.claude ? 'Claude' : 'OpenAI';
  }

  /// Get cost estimate per thought (in USD)
  double get estimatedCostPerThought {
    switch (ApiConfig.aiProvider) {
      case AiProvider.claude:
        return 0.015; // ~1.5 cents per thought
      case AiProvider.openai:
        // Cost depends on model
        if (ApiConfig.openAiModel.contains('gpt-4')) {
          return 0.01; // ~1 cent for GPT-4
        } else {
          return 0.002; // ~0.2 cents for GPT-3.5
        }
    }
  }
}

/// Re-export ThoughtAnalysis and BatchAnalysis for convenience
export 'ai_service.dart' show ThoughtAnalysis, BatchAnalysis;
