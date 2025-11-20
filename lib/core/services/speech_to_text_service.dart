import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for converting speech to text
class SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  /// Initialize the speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Check microphone permission
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        throw Exception('Microphone permission not granted');
      }
    }

    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );

    return _isInitialized;
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else if (onPartialResult != null) {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Cancel listening
  Future<void> cancel() async {
    await _speechToText.cancel();
  }

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Check if available
  bool get isAvailable => _speechToText.isAvailable;

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    return await _speechToText.locales();
  }
}
