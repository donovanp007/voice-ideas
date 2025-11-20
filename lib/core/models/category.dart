import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Represents a category for organizing thoughts
class Category {
  final String id;
  final String userId;
  final String name;
  final String colorHex;
  final String icon;
  final bool aiAssigned;
  final DateTime createdAt;

  Category({
    String? id,
    required this.userId,
    required this.name,
    required this.colorHex,
    required this.icon,
    this.aiAssigned = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Get Flutter Color from hex string
  Color get color {
    return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
  }

  /// Create a Category from JSON (Supabase response)
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String,
      icon: json['icon'] as String,
      aiAssigned: json['ai_assigned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert Category to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color_hex': colorHex,
      'icon': icon,
      'ai_assigned': aiAssigned,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Default categories to create on first launch
  static List<Category> getDefaultCategories(String userId) {
    return [
      Category(
        userId: userId,
        name: 'Personal',
        colorHex: '#4CAF50',
        icon: '👤',
      ),
      Category(
        userId: userId,
        name: 'Work',
        colorHex: '#2196F3',
        icon: '💼',
      ),
      Category(
        userId: userId,
        name: 'Ideas',
        colorHex: '#FFC107',
        icon: '💡',
      ),
      Category(
        userId: userId,
        name: 'Reminders',
        colorHex: '#F44336',
        icon: '⏰',
      ),
      Category(
        userId: userId,
        name: 'Ministry',
        colorHex: '#9C27B0',
        icon: '✝️',
      ),
      Category(
        userId: userId,
        name: 'Business',
        colorHex: '#FF5722',
        icon: '🚀',
      ),
    ];
  }
}
