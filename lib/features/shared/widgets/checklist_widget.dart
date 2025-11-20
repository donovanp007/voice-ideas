import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/checklist_item.dart';
import '../../../core/services/supabase_service.dart';

/// A beautiful widget to display and manage checklist items
class ChecklistWidget extends ConsumerStatefulWidget {
  final String thoughtId;
  final bool isEditable;

  const ChecklistWidget({
    super.key,
    required this.thoughtId,
    this.isEditable = true,
  });

  @override
  ConsumerState<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends ConsumerState<ChecklistWidget> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _newItemController = TextEditingController();
  List<ChecklistItem> _items = [];
  bool _isLoading = true;
  bool _isAddingItem = false;

  @override
  void initState() {
    super.initState();
    _loadChecklistItems();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklistItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await _supabaseService.getChecklistItems(widget.thoughtId);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading checklist: $e')),
        );
      }
    }
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    // Optimistically update UI
    final updatedItem = item.toggleCompleted();
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    });

    try {
      await _supabaseService.updateChecklistItem(updatedItem);
    } catch (e) {
      // Revert on error
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(ChecklistItem item) async {
    // Optimistically remove from UI
    final itemIndex = _items.indexOf(item);
    setState(() {
      _items.remove(item);
    });

    try {
      await _supabaseService.deleteChecklistItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _items.insert(itemIndex, item);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  Future<void> _addNewItem() async {
    if (_newItemController.text.trim().isEmpty) return;

    final itemText = _newItemController.text.trim();
    _newItemController.clear();

    setState(() => _isAddingItem = true);

    try {
      final newItems = await _supabaseService.saveChecklistItems(
        widget.thoughtId,
        [itemText],
      );

      setState(() {
        _items.addAll(newItems);
        _isAddingItem = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingItem = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    }
  }

  int get _completedCount => _items.where((item) => item.isCompleted).length;
  int get _totalCount => _items.length;
  double get _completionPercentage =>
      _totalCount == 0 ? 0 : _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty && !widget.isEditable) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with progress
        _buildHeader(context),

        const SizedBox(height: 16),

        // Progress bar
        if (_totalCount > 0) _buildProgressBar(context),

        const SizedBox(height: 16),

        // Checklist items
        ..._items.map((item) => _buildChecklistItem(context, item)),

        // Add new item (if editable)
        if (widget.isEditable) ...[
          const SizedBox(height: 16),
          _buildAddItemField(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.checklist,
              color: Colors.blue.shade700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Checklist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        if (_totalCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _completionPercentage == 1.0
                  ? Colors.green.shade100
                  : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_completedCount / $_totalCount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _completionPercentage == 1.0
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _completionPercentage,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _completionPercentage == 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(_completionPercentage * 100).toStringAsFixed(0)}% complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(BuildContext context, ChecklistItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: widget.isEditable
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Item?'),
                content: Text('Remove "${item.text}" from checklist?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) => _deleteItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.isCompleted
              ? Colors.grey.shade50
              : Colors.white,
          border: Border.all(
            color: item.isCompleted
                ? Colors.grey.shade300
                : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CheckboxListTile(
          value: item.isCompleted,
          onChanged: widget.isEditable
              ? (value) => _toggleItem(item)
              : null,
          title: Text(
            item.text,
            style: TextStyle(
              decoration: item.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: item.isCompleted
                  ? Colors.grey.shade600
                  : Colors.black,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          dense: true,
        ),
      ),
    );
  }

  Widget _buildAddItemField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newItemController,
              decoration: const InputDecoration(
                hintText: 'Add new item...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _addNewItem(),
              enabled: !_isAddingItem,
            ),
          ),
          const SizedBox(width: 8),
          if (_isAddingItem)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: Colors.blue.shade700,
              onPressed: _addNewItem,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
