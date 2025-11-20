import 'package:uuid/uuid.dart';

/// Represents a single thought/idea captured by the user
class Thought {
  final String id;
  final String userId;
  final String originalText;
  final String? aiSummary;
  final String? recordingUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final List<String> tags;
  final bool hasReminder;
  final String? reminderId;

  Thought({
    String? id,
    required this.userId,
    required this.originalText,
    this.aiSummary,
    this.recordingUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.categoryId,
    List<String>? tags,
    this.hasReminder = false,
    this.reminderId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  /// Create a Thought from JSON (Supabase response)
  factory Thought.fromJson(Map<String, dynamic> json) {
    return Thought(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      originalText: json['original_text'] as String,
      aiSummary: json['ai_summary'] as String?,
      recordingUrl: json['recording_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryId: json['category_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      hasReminder: json['has_reminder'] as bool? ?? false,
      reminderId: json['reminder_id'] as String?,
    );
  }

  /// Convert Thought to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'original_text': originalText,
      'ai_summary': aiSummary,
      'recording_url': recordingUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category_id': categoryId,
      'tags': tags,
      'has_reminder': hasReminder,
      'reminder_id': reminderId,
    };
  }

  /// Create a copy with modified fields
  Thought copyWith({
    String? id,
    String? userId,
    String? originalText,
    String? aiSummary,
    String? recordingUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    List<String>? tags,
    bool? hasReminder,
    String? reminderId,
  }) {
    return Thought(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalText: originalText ?? this.originalText,
      aiSummary: aiSummary ?? this.aiSummary,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderId: reminderId ?? this.reminderId,
    );
  }
}
