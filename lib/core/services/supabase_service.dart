import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/thought.dart';
import '../models/category.dart';
import '../models/reminder.dart';
import '../models/checklist_item.dart';

/// Service for all Supabase operations
class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Get current user ID (for demo, we'll use a static ID)
  /// In production, you'd use Supabase auth
  static String get userId {
    // TODO: Implement proper auth
    return 'demo-user-id';
  }

  // ==================== THOUGHT OPERATIONS ====================

  /// Save a new thought
  Future<Thought> saveThought(Thought thought) async {
    final response = await client
        .from('thoughts')
        .insert(thought.toJson())
        .select()
        .single();

    return Thought.fromJson(response);
  }

  /// Update an existing thought
  Future<Thought> updateThought(Thought thought) async {
    final updatedThought = thought.copyWith(updatedAt: DateTime.now());

    final response = await client
        .from('thoughts')
        .update(updatedThought.toJson())
        .eq('id', thought.id)
        .select()
        .single();

    return Thought.fromJson(response);
  }

  /// Get all thoughts for the current user
  /// NEW: Supports filtering by archived status, pinned items appear first
  Future<List<Thought>> getThoughts({
    String? categoryId,
    bool includeArchived = false,
    int? limit,
    int? offset,
  }) async {
    var query = client
        .from('thoughts')
        .select()
        .eq('user_id', userId);

    // Filter out archived thoughts unless explicitly requested
    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    // Order by pinned status first, then by creation date
    query = query.order('is_pinned', ascending: false).order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }

    final response = await query;
    return (response as List).map((json) => Thought.fromJson(json)).toList();
  }

  /// Search thoughts by text
  Future<List<Thought>> searchThoughts(String query) async {
    final response = await client
        .from('thoughts')
        .select()
        .eq('user_id', userId)
        .or('original_text.ilike.%$query%,ai_summary.ilike.%$query%')
        .order('created_at', ascending: false);

    return (response as List).map((json) => Thought.fromJson(json)).toList();
  }

  /// Delete a thought
  Future<void> deleteThought(String thoughtId) async {
    await client.from('thoughts').delete().eq('id', thoughtId);
  }

  /// Upload audio file to Supabase Storage
  Future<String> uploadAudio(String filePath, String fileName) async {
    final file = await client.storage.from('recordings').upload(
          '$userId/$fileName',
          filePath,
        );

    return client.storage.from('recordings').getPublicUrl('$userId/$fileName');
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Save a new category
  Future<Category> saveCategory(Category category) async {
    final response = await client
        .from('categories')
        .insert(category.toJson())
        .select()
        .single();

    return Category.fromJson(response);
  }

  /// Get all categories for the current user
  Future<List<Category>> getCategories() async {
    final response = await client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Category.fromJson(json)).toList();
  }

  /// Initialize default categories for a new user
  Future<void> initializeDefaultCategories() async {
    final categories = Category.getDefaultCategories(userId);

    for (final category in categories) {
      await saveCategory(category);
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await client.from('categories').delete().eq('id', categoryId);
  }

  // ==================== REMINDER OPERATIONS ====================

  /// Save a new reminder
  Future<Reminder> saveReminder(Reminder reminder) async {
    final response = await client
        .from('reminders')
        .insert(reminder.toJson())
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  /// Get reminders for a thought
  Future<List<Reminder>> getRemindersForThought(String thoughtId) async {
    final response = await client
        .from('reminders')
        .select()
        .eq('thought_id', thoughtId)
        .order('reminder_time', ascending: true);

    return (response as List).map((json) => Reminder.fromJson(json)).toList();
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    await client.from('reminders').delete().eq('id', reminderId);
  }

  // ==================== CHECKLIST OPERATIONS (NEW) ====================

  /// Save checklist items for a thought
  Future<List<ChecklistItem>> saveChecklistItems(
      String thoughtId, List<String> items) async {
    final checklistItems = <ChecklistItem>[];

    for (var i = 0; i < items.length; i++) {
      final item = ChecklistItem(
        thoughtId: thoughtId,
        text: items[i],
        position: i,
      );

      final response = await client
          .from('checklist_items')
          .insert(item.toJson())
          .select()
          .single();

      checklistItems.add(ChecklistItem.fromJson(response));
    }

    return checklistItems;
  }

  /// Get checklist items for a thought
  Future<List<ChecklistItem>> getChecklistItems(String thoughtId) async {
    final response = await client
        .from('checklist_items')
        .select()
        .eq('thought_id', thoughtId)
        .order('position', ascending: true);

    return (response as List)
        .map((json) => ChecklistItem.fromJson(json))
        .toList();
  }

  /// Update a checklist item (e.g., toggle completion)
  Future<ChecklistItem> updateChecklistItem(ChecklistItem item) async {
    final response = await client
        .from('checklist_items')
        .update(item.toJson())
        .eq('id', item.id)
        .select()
        .single();

    return ChecklistItem.fromJson(response);
  }

  /// Delete a checklist item
  Future<void> deleteChecklistItem(String itemId) async {
    await client.from('checklist_items').delete().eq('id', itemId);
  }

  /// Get completion percentage for a checklist thought
  Future<int> getChecklistCompletion(String thoughtId) async {
    final items = await getChecklistItems(thoughtId);

    if (items.isEmpty) return 0;

    final completedCount = items.where((item) => item.isCompleted).length;
    return ((completedCount / items.length) * 100).round();
  }

  /// Toggle pin status of a thought
  Future<Thought> togglePin(Thought thought) async {
    return await updateThought(thought.togglePin());
  }

  /// Toggle archive status of a thought
  Future<Thought> toggleArchive(Thought thought) async {
    return await updateThought(thought.toggleArchive());
  }
}
