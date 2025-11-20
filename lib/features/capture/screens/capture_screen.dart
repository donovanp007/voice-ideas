import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/thought.dart';
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/speech_to_text_service.dart';
import '../../../core/services/unified_ai_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/reminder_service.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/text_input.dart';

enum CaptureMode { voice, text }

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CaptureMode _captureMode = CaptureMode.voice;
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  String _status = '';

  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final SpeechToTextService _speechToText = SpeechToTextService();
  final UnifiedAiService _aiService = UnifiedAiService();
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
  }

  Future<void> _initializeSpeechToText() async {
    try {
      await _speechToText.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Thought'),
        actions: [
          if (_textController.text.isNotEmpty)
            TextButton(
              onPressed: _isProcessing ? null : _saveThought,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Mode Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<CaptureMode>(
              segments: const [
                ButtonSegment(
                  value: CaptureMode.voice,
                  label: Text('Voice'),
                  icon: Icon(Icons.mic),
                ),
                ButtonSegment(
                  value: CaptureMode.text,
                  label: Text('Text'),
                  icon: Icon(Icons.keyboard),
                ),
              ],
              selected: {_captureMode},
              onSelectionChanged: (Set<CaptureMode> newSelection) {
                setState(() {
                  _captureMode = newSelection.first;
                });
              },
            ),
          ),

          // Status indicator
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_status)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Capture interface
          Expanded(
            child: _captureMode == CaptureMode.voice
                ? VoiceRecorderWidget(
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
                    controller: _textController,
                    onSubmit: _saveThought,
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
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Analyzing with AI...';
    });

    try {
      // Analyze with AI (OpenAI or Claude based on config)
      setState(() {
        _status = 'Analyzing with ${_aiService.providerName}...';
      });

      final analysis = await _aiService.analyzeThought(_textController.text);

      // Create thought with NEW fields: title, isChecklist
      final thought = Thought(
        userId: SupabaseService.userId,
        title: analysis.title,
        originalText: _textController.text,
        aiSummary: analysis.summary,
        tags: analysis.tags,
        isChecklist: analysis.isChecklist,
        hasReminder: analysis.needsReminder,
      );

      setState(() {
        _status = 'Saving thought...';
      });

      // Save to Supabase
      final savedThought = await _supabaseService.saveThought(thought);

      // NEW: Save checklist items if this is a checklist
      if (analysis.isChecklist && analysis.checklistItems.isNotEmpty) {
        setState(() {
          _status = 'Saving checklist items...';
        });

        await _supabaseService.saveChecklistItems(
          savedThought.id,
          analysis.checklistItems,
        );
      }

      // Create reminder if needed
      if (analysis.needsReminder && analysis.suggestedReminderTime != null) {
        setState(() {
          _status = 'Creating reminder...';
        });

        final reminderTime = ReminderService.parseNaturalTime(
          analysis.suggestedReminderTime!,
        );

        if (reminderTime != null) {
          final reminderService = ReminderService();
          await reminderService.scheduleReminder(
            title: 'Thought Reminder',
            body: analysis.summary,
            scheduledTime: reminderTime,
            payload: savedThought.id,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        final message = analysis.isChecklist
            ? 'Checklist saved with ${analysis.checklistItems.length} items!'
            : 'Thought saved successfully!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving thought: $e')),
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
