import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/thought.dart';
import '../../../core/services/supabase_service.dart';
import '../../thought_detail/screens/thought_detail_screen.dart';

/// Provider for thoughts list
final thoughtsProvider = FutureProvider<List<Thought>>((ref) async {
  final supabaseService = SupabaseService();
  return await supabaseService.getThoughts();
});

class ThoughtsListScreen extends ConsumerWidget {
  const ThoughtsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thoughtsAsync = ref.watch(thoughtsProvider);

    return thoughtsAsync.when(
      data: (thoughts) {
        if (thoughts.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(thoughtsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 80),
            itemCount: thoughts.length,
            itemBuilder: (context, index) {
              final thought = thoughts[index];
              return _buildThoughtCard(context, thought);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(thoughtsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 120,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No thoughts yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone button to capture your first thought',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtCard(BuildContext context, Thought thought) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // NEW: Add border for pinned items
      color: thought.isPinned ? Colors.amber.shade50 : null,
      elevation: thought.isPinned ? 4 : 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThoughtDetailScreen(thought: thought),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and status indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // NEW: Pin indicator
                        if (thought.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        // NEW: Checklist indicator
                        if (thought.isChecklist)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.checklist,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            dateFormat.format(thought.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (thought.hasReminder)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.alarm,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reminder',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // NEW: Title
              if (thought.title != null && thought.title!.isNotEmpty) ...[
                Text(
                  thought.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
              ],

              // AI Summary (if available)
              if (thought.aiSummary != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          thought.aiSummary!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Original text (or checklist preview)
              if (!thought.isChecklist)
                Text(
                  thought.originalText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )
              else
                // Checklist preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.checklist_rtl,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap to view checklist items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),

              // Tags
              if (thought.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: thought.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Audio indicator
              if (thought.recordingUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Audio recording available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
