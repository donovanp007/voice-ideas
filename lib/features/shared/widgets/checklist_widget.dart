import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/checklist_item.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

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

class _ChecklistWidgetState extends ConsumerState<ChecklistWidget>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _newItemController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<ChecklistItem> _items = [];
  bool _isLoading = true;
  bool _isAddingItem = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _loadChecklistItems();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    _focusNode.dispose();
    _progressController.dispose();
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
      _progressController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading checklist: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    HapticFeedback.lightImpact();

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
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(ChecklistItem item) async {
    HapticFeedback.mediumImpact();

    // Optimistically remove from UI
    final itemIndex = _items.indexOf(item);
    setState(() {
      _items.remove(item);
    });

    try {
      await _supabaseService.deleteChecklistItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Item removed'),
              ],
            ),
            backgroundColor: const Color(0xFF475569),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
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
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: AppTheme.error,
          ),
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

      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Item added'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingItem = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: AppTheme.error,
          ),
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
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading checklist...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
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

        const SizedBox(height: 20),

        // Checklist items
        ..._items.asMap().entries.map((entry) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 200 + (entry.key * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildChecklistItem(context, entry.value),
          );
        }),

        // Add new item (if editable)
        if (widget.isEditable) ...[
          const SizedBox(height: 16),
          _buildAddItemField(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isComplete = _completionPercentage == 1.0 && _totalCount > 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isComplete
                ? LinearGradient(
                    colors: [AppTheme.success, AppTheme.success.withGreen(180)],
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isComplete ? Icons.check_circle_rounded : Icons.checklist_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isComplete ? 'All Done!' : 'Checklist',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (_totalCount > 0)
                Text(
                  '$_completedCount of $_totalCount completed',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        if (_totalCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.primaryStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(_completionPercentage * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isComplete ? AppTheme.success : AppTheme.primaryStart,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final isComplete = _completionPercentage == 1.0;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _completionPercentage * _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isComplete
                          ? LinearGradient(
                              colors: [
                                AppTheme.success,
                                AppTheme.success.withGreen(180)
                              ],
                            )
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
      ),
      confirmDismiss: (direction) async {
        return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Item?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${item.text}"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ?? false;
      },
      onDismissed: (direction) => _deleteItem(item),
      child: GestureDetector(
        onTap: widget.isEditable ? () => _toggleItem(item) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isCompleted
                  ? AppTheme.success.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: item.isCompleted ? 2 : 1,
            ),
            boxShadow: item.isCompleted ? null : AppTheme.softShadow,
          ),
          child: Row(
            children: [
              // Custom checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient:
                      item.isCompleted ? AppTheme.primaryGradient : null,
                  color: item.isCompleted ? null : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: item.isCompleted
                      ? null
                      : Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: item.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Item text
              Expanded(
                child: Text(
                  item.text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isCompleted
                        ? Colors.grey.shade500
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              // Swipe hint
              if (widget.isEditable)
                Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.grey.shade300,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newItemController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Add new item...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1E293B),
              ),
              onSubmitted: (_) => _addNewItem(),
              enabled: !_isAddingItem,
            ),
          ),
          GestureDetector(
            onTap: _isAddingItem ? null : _addNewItem,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isAddingItem
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
