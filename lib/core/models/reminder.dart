import 'package:uuid/uuid.dart';

/// Represents a reminder associated with a thought
class Reminder {
  final String id;
  final String thoughtId;
  final String? androidReminderId;
  final DateTime reminderTime;
  final String title;
  final DateTime createdAt;

  Reminder({
    String? id,
    required this.thoughtId,
    this.androidReminderId,
    required this.reminderTime,
    required this.title,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a Reminder from JSON (Supabase response)
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      thoughtId: json['thought_id'] as String,
      androidReminderId: json['android_reminder_id'] as String?,
      reminderTime: DateTime.parse(json['reminder_time'] as String),
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert Reminder to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thought_id': thoughtId,
      'android_reminder_id': androidReminderId,
      'reminder_time': reminderTime.toIso8601String(),
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
