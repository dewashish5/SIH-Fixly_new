import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
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
  Function(bool)? _listeningChanged;

  /// Request system permissions for microphone & speech recognition
  Future<bool> requestPermissions() async {
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }
      final speechStatus = await Permission.speech.status;
      if (!speechStatus.isGranted) {
        await Permission.speech.request();
      }
      final micGranted = await Permission.microphone.isGranted;
      final speechGranted = await Permission.speech.isGranted;
      return micGranted && speechGranted;
    } catch (e) {
      debugPrint('Error requesting speech permissions: $e');
      return false;
    }
  }

  /// Initialize the speech service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await requestPermissions();

      final bool sttAvailable = await _speech.initialize(
        onStatus: (val) {
          debugPrint('onStatus: $val');
          final listening = val == 'listening';
          _isListening = listening;
          _listeningChanged?.call(listening);
        },
        onError: (val) {
          debugPrint('onError: $val');
          _isListening = false;
          _listeningChanged?.call(false);
        },
      );

      if (!sttAvailable) {
        debugPrint('Speech-to-text not available');
        return false;
      }

      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        final cb = _onSpeechComplete;
        _onSpeechComplete = null;
        cb?.call();
      });
      _tts.setCancelHandler(() {
        _isSpeaking = false;
        // Still notify so live loop can resume listening.
        final cb = _onSpeechComplete;
        _onSpeechComplete = null;
        cb?.call();
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
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      _listeningChanged = onListeningChanged;
      _isListening = true;
      onListeningChanged(true);

      await _speech.listen(
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
          cancelOnError: true,
        ),
      );

      _isListening = _speech.isListening;
      onListeningChanged(_isListening);
      return _isListening;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      onListeningChanged(false);
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening || _speech.isListening) {
      await _speech.stop();
      _isListening = false;
      _listeningChanged?.call(false);
    }
  }

  bool get isListening => _isListening;

  String get lastWords => _lastWords;

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
      await _tts.setSpeechRate(0.55);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Error in TTS: $e');
      _isSpeaking = false;
      onComplete?.call();
      _onSpeechComplete = null;
    }
  }

  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  bool get isSpeaking => _isSpeaking;

  Future<List<dynamic>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}
