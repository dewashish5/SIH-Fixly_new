import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Thin Gemini Live WebSocket client (hybrid: audio/text in, tool out).
/// Uses ephemeral token from backend. Falls back callers handle STT/TTS.
class GeminiLiveService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _setupDone = false;

  void Function(String transcript)? onUserTranscript;
  void Function(String transcript)? onModelTranscript;
  void Function(Uint8List pcm)? onAudioChunk;
  void Function(Map<String, dynamic> call)? onToolCall;
  void Function(Object error)? onError;
  void Function()? onClosed;

  bool get isConnected => _channel != null;

  Future<void> connect({
    required String websocketUrl,
    required String model,
    required String systemLanguage,
    List<Map<String, dynamic>>? tools,
  }) async {
    await disconnect();
    _setupDone = false;
    _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));
    _sub = _channel!.stream.listen(
      _onMessage,
      onError: (e) => onError?.call(e),
      onDone: () {
        onClosed?.call();
        _channel = null;
      },
    );

    // Constrained tokens often ignore client setup; still send minimal setup.
    final setup = <String, dynamic>{
      'setup': {
        'model': 'models/$model',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
        },
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'Flexi AI voice. Locale=$systemLanguage. Short fillers ok (hmm/haan/ok). Human, fast.',
            },
          ],
        },
        if (tools != null && tools.isNotEmpty) 'tools': tools,
      },
    };
    _channel!.sink.add(jsonEncode(setup));
  }

  void sendRealtimeText(String text) {
    if (_channel == null) return;
    _channel!.sink.add(
      jsonEncode({
        'realtimeInput': {'text': text},
      }),
    );
  }

  void sendAudioPcm16le(Uint8List pcm, {String mime = 'audio/pcm;rate=16000'}) {
    if (_channel == null) return;
    _channel!.sink.add(
      jsonEncode({
        'realtimeInput': {
          'audio': {
            'mimeType': mime,
            'data': base64Encode(pcm),
          },
        },
      }),
    );
  }

  void sendToolResponse({
    required String id,
    required String name,
    required Object response,
  }) {
    if (_channel == null) return;
    _channel!.sink.add(
      jsonEncode({
        'toolResponse': {
          'functionResponses': [
            {
              'id': id,
              'name': name,
              'response': response is Map ? response : {'result': response},
            },
          ],
        },
      }),
    );
  }

  void _onMessage(dynamic raw) {
    try {
      final data = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : jsonDecode(utf8.decode(raw as List<int>)) as Map<String, dynamic>;

      if (data['setupComplete'] != null) {
        _setupDone = true;
        return;
      }

      final toolCall = data['toolCall'] as Map<String, dynamic>?;
      if (toolCall != null) {
        onToolCall?.call(toolCall);
      }

      final serverContent = data['serverContent'] as Map<String, dynamic>?;
      if (serverContent == null) return;

      final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
      final parts = (modelTurn?['parts'] as List?) ?? const [];
      for (final part in parts) {
        if (part is! Map) continue;
        final text = part['text']?.toString();
        if (text != null && text.isNotEmpty) {
          onModelTranscript?.call(text);
        }
        final inline = part['inlineData'] as Map<String, dynamic>?;
        if (inline != null && inline['data'] != null) {
          onAudioChunk?.call(base64Decode(inline['data'] as String));
        }
      }

      final inputTx = serverContent['inputTranscription'] as Map<String, dynamic>?;
      final inText = inputTx?['text']?.toString();
      if (inText != null && inText.isNotEmpty) {
        onUserTranscript?.call(inText);
      }
      final outputTx = serverContent['outputTranscription'] as Map<String, dynamic>?;
      final outText = outputTx?['text']?.toString();
      if (outText != null && outText.isNotEmpty) {
        onModelTranscript?.call(outText);
      }
    } catch (e) {
      debugPrint('GeminiLive parse error: $e');
      onError?.call(e);
    }
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _setupDone = false;
  }

  bool get setupComplete => _setupDone;
}
