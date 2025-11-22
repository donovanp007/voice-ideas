import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/thought.dart';
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/speech_to_text_service.dart';
import '../../../core/services/unified_ai_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/text_input.dart';

enum CaptureMode { voice, text }

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  CaptureMode _captureMode = CaptureMode.voice;
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  String _status = '';

  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final SpeechToTextService _speechToText = SpeechToTextService();
  final UnifiedAiService _aiService = UnifiedAiService();
  final SupabaseService _supabaseService = SupabaseService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  Future<void> _initializeSpeechToText() async {
    try {
      await _speechToText.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition not available: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          children: [
            // Beautiful gradient header
            _buildHeader(context),

            // Mode Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: _buildModeToggle(),
            ),

            // Status indicator
            if (_status.isNotEmpty)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStatusCard(),
                ),
              ),

            const SizedBox(height: 8),

            // Capture interface
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _captureMode == CaptureMode.voice
                    ? VoiceRecorderWidget(
                        key: const ValueKey('voice'),
                        audioRecorder: _audioRecorder,
                        speechToText: _speechToText,
                        onTranscriptionComplete: _handleTranscription,
                        onStatusChanged: (status) {
                          setState(() {
                            _status = status;
                          });
                        },
                      )
                    : TextInputWidget(
                        key: const ValueKey('text'),
                        controller: _textController,
                        onSubmit: _saveThought,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
          child: Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capture Thought',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Voice or type your idea',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_textController.text.isNotEmpty)
                _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _saveThought,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryStart,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppTheme.primaryStart,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryStart,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              mode: CaptureMode.voice,
              icon: Icons.mic_rounded,
              label: 'Voice',
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              mode: CaptureMode.text,
              icon: Icons.keyboard_rounded,
              label: 'Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required CaptureMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _captureMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _captureMode = mode);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryStart : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryStart : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor = AppTheme.info;
    IconData statusIcon = Icons.info_outline_rounded;

    if (_status.toLowerCase().contains('error')) {
      statusColor = AppTheme.error;
      statusIcon = Icons.error_outline_rounded;
    } else if (_status.toLowerCase().contains('complete') ||
        _status.toLowerCase().contains('success')) {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (_status.toLowerCase().contains('analyzing')) {
      statusColor = AppTheme.primaryStart;
      statusIcon = Icons.auto_awesome;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTranscription(String transcription) {
    setState(() {
      _textController.text = transcription;
    });
  }

  Future<void> _saveThought() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter some text'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Saving thought...';
    });

    try {
      // Try AI analysis, but don't fail if it doesn't work
      String? title;
      String? aiSummary;
      List<String> tags = [];
      bool isChecklist = false;
      List<String> checklistItems = [];
      bool needsReminder = false;
      String? suggestedReminderTime;

      try {
        setState(() {
          _status = 'Analyzing with ${_aiService.providerName}...';
        });

        final analysis = await _aiService.analyzeThought(_textController.text);

        title = analysis.title;
        aiSummary = analysis.summary;
        tags = analysis.tags;
        isChecklist = analysis.isChecklist;
        checklistItems = analysis.checklistItems;
        needsReminder = analysis.needsReminder;
        suggestedReminderTime = analysis.suggestedReminderTime;

        setState(() {
          _status = 'AI analysis complete!';
        });
      } catch (aiError) {
        // AI failed, but continue saving without it
        print('AI analysis failed: $aiError');
        setState(() {
          _status = 'Saving without AI (check API keys)...';
        });

        // Basic checklist detection as fallback
        final text = _textController.text.toLowerCase();
        if (text.contains('todo') ||
            text.contains('checklist') ||
            text.contains('shopping list') ||
            text.split('\n').where((line) => line.trim().startsWith('-')).length > 1) {
          isChecklist = true;
          // Extract items from lines starting with -
          checklistItems = _textController.text
              .split('\n')
              .where((line) => line.trim().startsWith('-'))
              .map((line) => line.trim().substring(1).trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      }

      // Create thought (with or without AI data)
      final thought = Thought(
        userId: SupabaseService.userId,
        title: title,
        originalText: _textController.text,
        aiSummary: aiSummary,
        tags: tags,
        isChecklist: isChecklist,
        hasReminder: needsReminder,
      );

      setState(() {
        _status = 'Saving to database...';
      });

      // Save to Supabase
      final savedThought = await _supabaseService.saveThought(thought);

      // Save checklist items if detected
      if (isChecklist && checklistItems.isNotEmpty) {
        setState(() {
          _status = 'Saving checklist items...';
        });

        await _supabaseService.saveChecklistItems(
          savedThought.id,
          checklistItems,
        );
      }

      // Create reminder if needed (only if AI detected it)
      if (needsReminder && suggestedReminderTime != null) {
        setState(() {
          _status = 'Creating reminder...';
        });

        try {
          final reminderTime = ReminderService.parseNaturalTime(
            suggestedReminderTime,
          );

          if (reminderTime != null) {
            final reminderService = ReminderService();
            await reminderService.scheduleReminder(
              title: 'Thought Reminder',
              body: aiSummary ?? _textController.text.split('\n').first,
              scheduledTime: reminderTime,
              payload: savedThought.id,
            );
          }
        } catch (reminderError) {
          print('Reminder creation failed: $reminderError');
          // Continue even if reminder fails
        }
      }

      if (mounted) {
        Navigator.pop(context, true);

        String message;
        if (isChecklist && checklistItems.isNotEmpty) {
          message = 'Checklist saved with ${checklistItems.length} items!';
        } else if (aiSummary == null) {
          message = 'Thought saved! (Configure AI keys for analysis)';
        } else {
          message = 'Thought saved successfully!';
        }

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
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e\n\nCheck Supabase configuration!'),
            duration: const Duration(seconds: 4),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = '';
        });
      }
    }
  }
}
