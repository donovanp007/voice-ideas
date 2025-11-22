import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/speech_to_text_service.dart';
import '../../../core/theme/app_theme.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final AudioRecorderService audioRecorder;
  final SpeechToTextService speechToText;
  final Function(String) onTranscriptionComplete;
  final Function(String) onStatusChanged;

  const VoiceRecorderWidget({
    super.key,
    required this.audioRecorder,
    required this.speechToText,
    required this.onTranscriptionComplete,
    required this.onStatusChanged,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isListening = false;
  String _partialTranscription = '';
  String _finalTranscription = '';
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated microphone button
          _buildMicrophoneButton(),

          const SizedBox(height: 32),

          // Recording duration
          AnimatedOpacity(
            opacity: _isRecording ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildDurationDisplay(),
          ),

          const SizedBox(height: 20),

          // Status text
          _buildStatusText(),

          const SizedBox(height: 32),

          // Transcription preview
          Expanded(
            child: _buildTranscriptionPreview(),
          ),

          // Quick tips
          if (!_isRecording) _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _isRecording ? _stopRecording() : _startRecording();
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring (when recording)
            if (_isRecording)
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, _) {
                  return Container(
                    width: 200 + (60 * _waveAnimation.value),
                    height: 200 + (60 * _waveAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.3 * (1 - _waveAnimation.value)),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            // Second wave ring
            if (_isRecording)
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, _) {
                  final offset = (_waveAnimation.value + 0.3) % 1.0;
                  return Container(
                    width: 200 + (60 * offset),
                    height: 200 + (60 * offset),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.2 * (1 - offset)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            // Main button
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isRecording
                    ? LinearGradient(
                        colors: [
                          AppTheme.error,
                          AppTheme.error.withRed(230),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? AppTheme.error : AppTheme.primaryStart)
                        .withOpacity(0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(_recordingDuration),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.error,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        Text(
          _isRecording ? 'Recording...' : 'Tap to start',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isRecording
              ? 'Tap the button to stop'
              : 'Share your thoughts freely',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptionPreview() {
    if (_partialTranscription.isEmpty && _finalTranscription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.transcribe,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Live Transcription',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_finalTranscription.isNotEmpty)
                    Text(
                      _finalTranscription,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  if (_partialTranscription.isNotEmpty)
                    Text(
                      _partialTranscription,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryStart.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryStart.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.primaryStart,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Pro Tip',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryStart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Speak naturally. AI will automatically organize, categorize, and create action items from your thoughts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      widget.onStatusChanged('Starting recording...');

      // Start animations
      _pulseController.repeat(reverse: true);
      _waveController.repeat();

      // Start speech recognition
      await widget.speechToText.startListening(
        onResult: (text) {
          setState(() {
            _finalTranscription = text;
            _partialTranscription = '';
          });
          widget.onTranscriptionComplete(text);
        },
        onPartialResult: (text) {
          setState(() {
            _partialTranscription = text;
          });
        },
      );

      // Start audio recording
      await widget.audioRecorder.startRecording();

      setState(() {
        _isRecording = true;
        _isListening = true;
        _recordingDuration = Duration.zero;
      });

      widget.onStatusChanged('Recording...');

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      widget.onStatusChanged('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      widget.onStatusChanged('Stopping recording...');

      _durationTimer?.cancel();
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();

      // Stop speech recognition
      await widget.speechToText.stopListening();

      // Stop audio recording
      final audioPath = await widget.audioRecorder.stopRecording();

      setState(() {
        _isRecording = false;
        _isListening = false;
      });

      widget.onStatusChanged('Recording complete!');

      if (audioPath != null) {
        print('Audio saved to: $audioPath');
      }
    } catch (e) {
      widget.onStatusChanged('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop recording: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
