import 'package:uuid/uuid.dart';

/// Represents a single item in a checklist
class ChecklistItem {
  final String id;
  final String thoughtId;
  final String text;
  final bool isCompleted;
  final int position;
  final DateTime createdAt;
  final DateTime? completedAt;

  ChecklistItem({
    String? id,
    required this.thoughtId,
    required this.text,
    this.isCompleted = false,
    required this.position,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a ChecklistItem from JSON (Supabase response)
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      thoughtId: json['thought_id'] as String,
      text: json['text'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Convert ChecklistItem to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thought_id': thoughtId,
      'text': text,
      'is_completed': isCompleted,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ChecklistItem copyWith({
    String? id,
    String? thoughtId,
    String? text,
    bool? isCompleted,
    int? position,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      thoughtId: thoughtId ?? this.thoughtId,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Toggle completion status
  ChecklistItem toggleCompleted() {
    return copyWith(
      isCompleted: !isCompleted,
      completedAt: !isCompleted ? DateTime.now() : null,
    );
  }
}
