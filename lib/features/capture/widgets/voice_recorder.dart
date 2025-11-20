import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/speech_to_text_service.dart';

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

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  bool _isRecording = false;
  bool _isListening = false;
  String _partialTranscription = '';
  String _finalTranscription = '';
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated microphone icon
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red.shade100
                    : Colors.purple.shade100,
                boxShadow: [
                  if (_isRecording)
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 80,
                color: _isRecording ? Colors.red : Colors.purple,
              ),
            ).animate(onPlay: (controller) {
              if (_isRecording) {
                controller.repeat();
              }
            }).scale(
              duration: 1000.ms,
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
            ),
          ),

          const SizedBox(height: 32),

          // Recording duration
          if (_isRecording)
            Text(
              _formatDuration(_recordingDuration),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
            ),

          const SizedBox(height: 16),

          // Status text
          Text(
            _isRecording
                ? 'Recording... Tap to stop'
                : 'Tap microphone to start recording',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Transcription preview
          if (_partialTranscription.isNotEmpty || _finalTranscription.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.transcribe,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transcription',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_finalTranscription.isNotEmpty)
                      Text(
                        _finalTranscription,
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (_partialTranscription.isNotEmpty)
                      Text(
                        _partialTranscription,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Quick tips
          if (!_isRecording)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Speak naturally. The app will transcribe and organize your thoughts automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      widget.onStatusChanged('Starting recording...');

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
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      widget.onStatusChanged('Stopping recording...');

      _durationTimer?.cancel();

      // Stop speech recognition
      await widget.speechToText.stopListening();

      // Stop audio recording
      final audioPath = await widget.audioRecorder.stopRecording();

      setState(() {
        _isRecording = false;
        _isListening = false;
      });

      widget.onStatusChanged('Recording complete!');

      // TODO: Upload audio to Supabase if needed
      if (audioPath != null) {
        print('Audio saved to: $audioPath');
      }
    } catch (e) {
      widget.onStatusChanged('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
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
