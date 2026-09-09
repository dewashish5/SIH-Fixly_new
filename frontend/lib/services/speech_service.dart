import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for handling speech-to-text and text-to-speech functionality
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _lastWords = '';
  bool _isInitialized = false;
  bool _isSpeaking = false;

  VoidCallback? _onSpeechComplete;

  /// Initialize the speech service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize speech-to-text
      bool sttAvailable = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );

      if (!sttAvailable) {
        debugPrint('Speech-to-text not available');
        return false;
      }

      // Initialize text-to-speech
      await _tts.setLanguage('hi-IN'); // Hindi as primary language
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        final cb = _onSpeechComplete;
        _onSpeechComplete = null;
        cb?.call();
      });
      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _onSpeechComplete = null;
      });
      _tts.setErrorHandler((dynamic msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        final cb = _onSpeechComplete;
        _onSpeechComplete = null;
        cb?.call();
      });

      _isInitialized = true;
      debugPrint('Speech service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
      return false;
    }
  }

  /// Start listening for speech input
  Future<bool> startListening({
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
    Function(String)? onPartialResult,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      _isListening = true;
      onListeningChanged(true);

      bool available = await _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            _lastWords = val.recognizedWords;
            onPartialResult?.call(val.recognizedWords);
          }
          if (val.finalResult) {
            onResult(val.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          localeId: localeId,
        ),
      );

      if (!available) {
        _isListening = false;
        onListeningChanged(false);
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      onListeningChanged(false);
      return false;
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get the last recognized words
  String get lastWords => _lastWords;

  /// Speak text using TTS
  Future<void> speak(
    String text, {
    String? language,
    VoidCallback? onComplete,
  }) async {
    if (_isSpeaking) await _tts.stop();

    try {
      _onSpeechComplete = onComplete;
      final lang = language ??
          (RegExp(r'[\u0900-\u097F]').hasMatch(text) ? 'hi-IN' : 'en-IN');
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Error in TTS: $e');
      _isSpeaking = false;
      onComplete?.call();
      _onSpeechComplete = null;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Get available languages for speech recognition
  Future<List<dynamic>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }

  /// Dispose resources
  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}