import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/location/app_location.dart';
import '../../../../services/gemini_live_service.dart';
import '../../../../services/speech_service.dart';
import '../../../ai/data/ai_api_repository.dart';
import '../../../ai/presentation/widgets/ai_fade_in_text.dart';
import '../../../ai/presentation/widgets/ai_thinking_dots.dart';
import '../../../ai/presentation/widgets/siri_glow_frame.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LiveVoiceState { listening, thinking, speaking, paused }

class _ChatMessage {
  const _ChatMessage({
    required this.isBot,
    required this.text,
    required this.timestamp,
    this.loading = false,
    this.action,
    this.booking,
    this.bookings = const [],
    this.workers = const [],
    this.estimate,
    this.policy,
    this.category,
    this.imagePath,
  });

  final bool isBot;
  final String text;
  final DateTime timestamp;
  final bool loading;
  final String? action;
  final Map<String, dynamic>? booking;
  final List<dynamic> bookings;
  final List<dynamic> workers;
  final Map<String, dynamic>? estimate;
  final Map<String, dynamic>? policy;
  final String? category;
  final String? imagePath;
}

class CustomerAiHelperPage extends StatefulWidget {
  const CustomerAiHelperPage({
    super.key,
    this.startInLiveMode = false,
  });

  /// When true (Hey Flexi FAB), open straight into Siri-style live voice.
  final bool startInLiveMode;

  @override
  State<CustomerAiHelperPage> createState() => _CustomerAiHelperPageState();
}

class _CustomerAiHelperPageState extends State<CustomerAiHelperPage> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _speechService = SpeechService();
  final _liveService = GeminiLiveService();
  final _aiRepo = AiApiRepository();

  final _messages = <_ChatMessage>[];
  Map<String, dynamic> _conversationState = {};
  bool _awaitingReply = false;
  bool _isDictating = false;

  /// App locales only (LocaleScope.supportedLocales).
  String _selectedLanguage = 'en';

  // --- Dynamic AI Suggested Replies ---
  List<String> _suggestedReplies = [];

  // --- Live Voice Talking Mode ---
  bool _isLiveMode = false;
  LiveVoiceState _liveVoiceState = LiveVoiceState.listening;
  String _liveSpokenText = '';
  String _liveAiReplyText = '';
  bool _liveBridgeReady = false;

  static const _langLabels = <String, String>{
    'en': 'EN',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'bn': 'বাংলা',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'pa': 'ਪੰਜਾਬੀ',
  };

  @override
  void initState() {
    super.initState();
    _speechService.initialize();

    // App locale first; only supported Fixly locales.
    final appLocale = context.read<AppSessionCubit>().state.locale;
    _selectedLanguage = _normalizeLang(appLocale);
    _conversationState['language'] = _selectedLanguage;

    _initConversation();

    if (widget.startInLiveMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startLiveMode();
      });
    }
  }

  String _normalizeLang(String? raw) {
    final v = (raw ?? 'en').toLowerCase().trim();
    if (v == 'hindi') return 'hi';
    if (v == 'english') return 'en';
    final base = v.split(RegExp(r'[-_]')).first;
    if (LocaleScope.supportedLocales.contains(base)) return base;
    return 'en';
  }

  String _sttLocaleId(String lang) {
    const map = {
      'en': 'en_IN',
      'hi': 'hi_IN',
      'ta': 'ta_IN',
      'te': 'te_IN',
      'kn': 'kn_IN',
      'bn': 'bn_IN',
      'mr': 'mr_IN',
      'gu': 'gu_IN',
      'pa': 'pa_IN',
    };
    return map[lang] ?? 'en_IN';
  }

  String _ttsLocaleId(String lang) => _sttLocaleId(lang).replaceAll('_', '-');

  bool get _allowsHinglish =>
      _selectedLanguage == 'en' || _selectedLanguage == 'hi';

  List<String> _getDefaultSuggestedReplies(String lang) {
    if (lang == 'hi') {
      return [
        '💧 बाथरूम में नल लीक हो रहा है',
        '⚡ स्विचबोर्ड से स्पार्क / एमसीबी ट्रिप',
        '🧹 घर की गहरी सफाई (डीप क्लीनिंग)',
        '❄️ एसी ठीक से ठंडा नहीं कर रहा',
        '📦 मेरी बुकिंग की स्थिति जांचें',
      ];
    }
    return [
      '💧 Tap leaking in bathroom',
      '⚡ Switchboard sparking / MCB tripping',
      '🧹 Deep home cleaning needed',
      '❄️ AC not cooling properly',
      '📦 Check my booking status',
    ];
  }

  void _initConversation() {
    _suggestedReplies = _getDefaultSuggestedReplies(_selectedLanguage);
    final hinglishNote = _allowsHinglish
        ? (_selectedLanguage == 'hi'
            ? ' आप Hinglish में भी बोल सकते हैं।'
            : ' You can also speak in Hinglish.')
        : '';
    _messages.add(
      _ChatMessage(
        isBot: true,
        text: _selectedLanguage == 'hi'
            ? 'नमस्ते! मैं फ्लेक्सी एआई हूँ। बताइए घर में क्या समस्या है, या Live Talk दबाएं।$hinglishNote'
            : 'Hello! I am Flexi AI. Tell me the home issue, or tap Live Talk.$hinglishNote',
        timestamp: DateTime.now(),
        action: 'PROMPT_CATEGORY',
      ),
    );
  }

  void _switchLanguage(String newLang) {
    final lang = _normalizeLang(newLang);
    if (_selectedLanguage == lang) return;
    setState(() {
      _selectedLanguage = lang;
      _conversationState['language'] = lang;
      if (_messages.length <= 1 && (_messages.isEmpty || _messages.first.isBot)) {
        _messages.clear();
        _initConversation();
      } else if (!_awaitingReply) {
        _suggestedReplies = _getDefaultSuggestedReplies(_selectedLanguage);
      }
    });

    if (_isLiveMode) {
      setState(() {
        _liveAiReplyText = 'Listening… language set to ${_langLabels[lang] ?? lang}';
      });
      _reconnectLiveSession();
    }
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _speechService.stopListening();
    _speechService.stopSpeaking();
    _liveService.disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Send Message & Process Agent Response ---
  Future<void> _sendMessage(String text, {String? imagePath}) async {
    final query = text.trim();
    if ((query.isEmpty && imagePath == null) || _awaitingReply) return;

    // Add user message to chat stream
    setState(() {
      _messages.add(
        _ChatMessage(
          isBot: false,
          text: query.isNotEmpty ? query : 'Attached photo of the issue',
          timestamp: DateTime.now(),
          imagePath: imagePath,
        ),
      );
      _messages.add(
        _ChatMessage(
          isBot: true,
          text: '...',
          timestamp: DateTime.now(),
          loading: true,
        ),
      );
      _awaitingReply = true;
      _queryController.clear();
      _suggestedReplies = [];
    });
    _scrollToBottom();

    try {
      if (imagePath != null) {
        // Visual issue diagnosis
        final analysis = await AiApiRepository().analyzeIssue(
          query.isNotEmpty ? query : 'Check issue from image',
          imagePath: imagePath,
        );
        final note = analysis.aiNote.trim().isNotEmpty
            ? analysis.aiNote
            : 'Detected ${analysis.category} issue (Estimated ~${analysis.estimatedHours}h). Would you like to proceed with booking?';

        if (!mounted) return;
        setState(() {
          _messages.removeLast();
          _messages.add(
            _ChatMessage(
              isBot: true,
              text: note,
              timestamp: DateTime.now(),
              category: analysis.category,
              action: 'PROMPT_CONFIRMATION',
            ),
          );
          _awaitingReply = false;
          _suggestedReplies = [
            'Yes, book a ${analysis.category} worker',
            'What is the estimated cost?',
            'Show available slots',
            'Cancel',
          ];
        });
      } else {
        // Conversational Agent (Flexi AI)
        List<double>? coords;
        if (AppLocation.instance.hasFix) {
          coords = [
            AppLocation.instance.requireLng,
            AppLocation.instance.requireLat,
          ];
        }
        final address = AppLocation.instance.addressLabel;
        final lang = _selectedLanguage;

        debugPrint('\n================================================================');
        debugPrint('🗣️ [CUSTOMER TALKING / SENT TO AI]');
        debugPrint('💬 Text:       "$query"');
        debugPrint('🌐 Language:   $lang');
        debugPrint('📍 Coords:     $coords');
        debugPrint('🏠 Address:    "$address"');
        debugPrint('🧠 State:      $_conversationState');
        debugPrint('----------------------------------------------------------------');

        final res = await _aiRepo.chatWithAgent(
          message: query,
          conversationState: _conversationState,
          language: lang,
          coordinates: coords,
          addressLine: address,
        );

        debugPrint('🤖 [AI AGENT REPLY RECEIVED]');
        debugPrint('⚡ Action:     ${res.action}');
        debugPrint('🗣️ Reply:      "${res.reply}"');
        debugPrint('📊 Next State: ${res.state}');
        if (res.workers.isNotEmpty) {
          debugPrint('👷 Workers:    ${res.workers.length} online workers received');
        }
        if (res.estimate != null) {
          debugPrint('💰 Estimate:   ₹${res.estimate!['totalAmount']} (Base: ₹${res.estimate!['baseServiceFee']})');
        }
        debugPrint('================================================================\n');

        if (!mounted) return;

        // Session Handling
        if (res.action == 'SESSION_EXPIRED') {
          _conversationState = {'language': _selectedLanguage};
        } else if (res.action == 'SESSION_ABORTED') {
          _conversationState = {'language': _selectedLanguage};
          if (_isLiveMode) {
            _closeLiveMode();
          }
        } else {
          _conversationState = Map<String, dynamic>.from(res.state);
          _conversationState['language'] = _selectedLanguage;
        }

        setState(() {
          _messages.removeLast();
          _messages.add(
            _ChatMessage(
              isBot: true,
              text: res.reply,
              timestamp: DateTime.now(),
              action: res.action,
              booking: res.booking,
              bookings: res.bookings,
              workers: res.workers,
              estimate: res.estimate,
              policy: res.policy,
              category: res.state['category']?.toString(),
            ),
          );
          _awaitingReply = false;
          _suggestedReplies = res.suggestedReplies.isNotEmpty
              ? res.suggestedReplies
              : _generateFallbackSuggestions(res.action, res.reply, _selectedLanguage);
        });

        // Live mode: speak reply then ALWAYS re-listen (unless booking created).
        if (_isLiveMode) {
          _speakLiveAiReply(
            res.reply,
            onComplete: () {
              if (!mounted || !_isLiveMode) return;
              if (res.action == 'BOOKING_CREATED') {
                final bookingId =
                    res.booking?['bookingId'] ?? res.booking?['_id'];
                _closeLiveMode();
                if (bookingId != null) {
                  context.push(
                    '${RouteNames.customerTracking}?bookingId=$bookingId',
                  );
                } else {
                  context.push(RouteNames.customerTracking);
                }
              } else {
                _listenInLiveMode();
              }
            },
          );
        } else if (res.action == 'BOOKING_CREATED') {
          final bookingId = res.booking?['bookingId'] ?? res.booking?['_id'];
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            if (bookingId != null) {
              context.push('${RouteNames.customerTracking}?bookingId=$bookingId');
            } else {
              context.push(RouteNames.customerTracking);
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage(
            isBot: true,
            text: _selectedLanguage == 'hi'
                ? 'मैं अभी इस अनुरोध को पूरा नहीं कर सका। कृपया पुनः प्रयास करें या नीचे दिए गए विकल्पों में से चुनें।'
                : 'I could not process that request right now. Please try again or tap one of the suggested options.',
            timestamp: DateTime.now(),
          ),
        );
        _awaitingReply = false;
        _suggestedReplies = _selectedLanguage == 'hi'
            ? [
                '💧 प्लंबर सहायता',
                '⚡ इलेक्ट्रीशियन सहायता',
                '🧹 सफाई सेवा',
                'मेरी बुकिंग स्थिति',
              ]
            : [
                '💧 Plumbing assistance',
                '⚡ Electrician assistance',
                '🧹 Cleaning services',
                'Track my orders',
              ];
      });

      if (_isLiveMode) {
        setState(() {
          _liveVoiceState = LiveVoiceState.listening;
          _liveAiReplyText = _selectedLanguage == 'hi'
              ? 'कृपया इसे दोबारा बोलें।'
              : 'Please try saying that again.';
        });
        _listenInLiveMode();
      }
    }

    _scrollToBottom();
  }

  List<String> _generateFallbackSuggestions(String? action, String reply, String lang) {
    final isHi = lang == 'hi';
    final lower = reply.toLowerCase();
    if (action == 'SESSION_EXPIRED') {
      return isHi
          ? ['💧 नल लीक हो रहा है', '⚡ स्विच में स्पार्क', '🧹 डीप क्लीनिंग', '📦 बुकिंग स्थिति']
          : ['💧 Tap leaking in bathroom', '⚡ Switch sparking', '🧹 Deep cleaning', '📦 Check booking status'];
    }
    if (action == 'SESSION_ABORTED') {
      return isHi
          ? ['प्लंबर चाहिए', 'इलेक्ट्रीशियन चाहिए', 'डीप क्लीनिंग', 'मदद']
          : ['Need a plumber', 'Need an electrician', 'Deep cleaning', 'Help'];
    }
    if (action == 'BOOKING_CREATED' || lower.contains('confirmed') || lower.contains('कन्फर्म')) {
      return isHi
          ? ['बुकिंग ट्रैक करें', 'मेरी बुकिंग्स देखें', 'नई सेवा बुक करें']
          : ['Track worker arrival', 'View my bookings', 'Book another service'];
    }
    if (action == 'BOOKING_STATUS' || lower.contains('booking #') || lower.contains('स्थिति')) {
      return isHi
          ? ['कार्यकर्ता को कॉल करें', 'ऑर्डर विवरण देखें', 'नई सेवा बुक करें']
          : ['Call worker', 'View order details', 'Book a new service'];
    }
    if (action == 'CONFIRM_EMERGENCY_BOOKING' || lower.contains('emergency') || lower.contains('sos') || lower.contains('आपातकालीन')) {
      return isHi
          ? ['हाँ, तुरंत कार्यकर्ता भेजें', 'विवरण बदलें', 'रद्द करें']
          : ['Yes, dispatch worker now', 'Change details', 'Cancel request'];
    }
    if (action == 'PROMPT_CONFIRMATION' || lower.contains('confirm') || lower.contains('कन्फर्म')) {
      return isHi
          ? ['हाँ, बुकिंग कन्फर्म करें', 'लागत क्या है?', 'रद्द करें']
          : ['Yes, confirm booking', 'What is the price?', 'Cancel'];
    }
    return isHi
        ? ['प्लंबर चाहिए', 'इलेक्ट्रीशियन चाहिए', 'डीप क्लीनिंग', 'बुकिंग स्थिति']
        : ['Need a plumber', 'Need an electrician', 'Deep cleaning', 'Check booking status'];
  }

  // --- Reset Conversation ---
  void _resetChat() {
    setState(() {
      _messages.clear();
      _conversationState = {'language': _selectedLanguage};
      _suggestedReplies = _getDefaultSuggestedReplies(_selectedLanguage);
      _messages.add(
        _ChatMessage(
          isBot: true,
          text: _selectedLanguage == 'hi'
              ? 'बातचीत रीसेट हो गई है। मैं आज आपकी क्या मदद कर सकता हूँ?'
              : 'Conversation reset. How can I help you today?',
          timestamp: DateTime.now(),
          action: 'PROMPT_CATEGORY',
        ),
      );
    });
  }

  // --- Live Voice Mode Engine ---
  Future<void> _startLiveMode() async {
    setState(() {
      _isLiveMode = true;
      _liveVoiceState = LiveVoiceState.listening;
      _liveSpokenText = '';
      _liveAiReplyText = _allowsHinglish
          ? 'Listening… hmm, go ahead'
          : 'Listening…';
    });
    HapticFeedback.mediumImpact();
    await _connectLiveBridge();
    _listenInLiveMode();
  }

  Future<void> _connectLiveBridge() async {
    try {
      final token = await _aiRepo.mintLiveToken(language: _selectedLanguage);
      final wsUrl = token['websocketUrl']?.toString();
      final model =
          token['liveModel']?.toString() ?? 'gemini-3.1-flash-live-preview';
      if (wsUrl == null || wsUrl.isEmpty) {
        _liveBridgeReady = false;
        return;
      }
      _liveService.onModelTranscript = (t) {
        if (!mounted || !_isLiveMode) return;
        setState(() => _liveAiReplyText = t);
      };
      _liveService.onUserTranscript = (t) {
        if (!mounted || !_isLiveMode) return;
        setState(() => _liveSpokenText = t);
      };
      _liveService.onToolCall = (call) async {
        // Flash brain bridge for booking tools.
        final fns = (call['functionCalls'] as List?) ?? const [];
        for (final fn in fns) {
          if (fn is! Map) continue;
          final id = fn['id']?.toString() ?? '';
          final name = fn['name']?.toString() ?? '';
          final args = fn['args'] as Map<String, dynamic>? ?? {};
          final utterance =
              args['utterance']?.toString() ?? _liveSpokenText;
          if (utterance.trim().isEmpty) continue;
          try {
            final res = await _aiRepo.liveToolBridge(
              utterance: utterance,
              conversationState: _conversationState,
              language: _selectedLanguage,
            );
            _conversationState = Map<String, dynamic>.from(res.state);
            _conversationState['language'] = _selectedLanguage;
            _liveService.sendToolResponse(
              id: id,
              name: name,
              response: {
                'reply': res.reply,
                'action': res.action,
              },
            );
            if (!mounted) return;
            setState(() {
              _messages.add(
                _ChatMessage(
                  isBot: true,
                  text: res.reply,
                  timestamp: DateTime.now(),
                  action: res.action,
                  booking: res.booking,
                  bookings: res.bookings,
                  workers: res.workers,
                  estimate: res.estimate,
                  policy: res.policy,
                ),
              );
              _liveAiReplyText = res.reply;
            });
          } catch (e) {
            _liveService.sendToolResponse(
              id: id,
              name: name,
              response: {'error': e.toString()},
            );
          }
        }
      };
      _liveService.onError = (e) {
        debugPrint('Live WS error: $e');
        _liveBridgeReady = false;
      };
      await _liveService.connect(
        websocketUrl: wsUrl,
        model: model,
        systemLanguage: _selectedLanguage,
        tools: [
          {
            'functionDeclarations': [
              {
                'name': 'call_fixly_brain',
                'description':
                    'Call Fixly booking brain for services, booking, status, price.',
                'parameters': {
                  'type': 'OBJECT',
                  'properties': {
                    'utterance': {
                      'type': 'STRING',
                      'description': 'User request in their language',
                    },
                  },
                  'required': ['utterance'],
                },
              },
            ],
          },
        ],
      );
      _liveBridgeReady = true;
    } catch (e) {
      debugPrint('Live token/connect failed, STT/TTS fallback: $e');
      _liveBridgeReady = false;
    }
  }

  Future<void> _reconnectLiveSession() async {
    await _liveService.disconnect();
    await _connectLiveBridge();
  }

  void _closeLiveMode() {
    _speechService.stopListening();
    _speechService.stopSpeaking();
    _liveService.disconnect();
    _liveBridgeReady = false;
    setState(() {
      _isLiveMode = false;
      _liveVoiceState = LiveVoiceState.paused;
    });
    _scrollToBottom();
  }

  Future<void> _listenInLiveMode() async {
    if (!_isLiveMode) return;

    setState(() {
      _liveVoiceState = LiveVoiceState.listening;
      _liveSpokenText = '';
    });

    final sttLocale = _sttLocaleId(_selectedLanguage);

    await _speechService.startListening(
      localeId: sttLocale,
      onPartialResult: (text) {
        if (!mounted || !_isLiveMode) return;
        setState(() => _liveSpokenText = text);
      },
      onResult: (finalText) {
        if (!mounted || !_isLiveMode) return;
        if (finalText.trim().isNotEmpty) {
          debugPrint('🎤 [VOICE STT FINAL] "$finalText" ($sttLocale)');
          setState(() {
            _liveSpokenText = finalText;
            _liveVoiceState = LiveVoiceState.thinking;
          });
          // Nudge Live session + run brain chat for structured reply.
          if (_liveBridgeReady) {
            _liveService.sendRealtimeText(
              'User said: $finalText. If booking needed, call call_fixly_brain.',
            );
          }
          _sendMessage(finalText);
        } else if (_isLiveMode) {
          _listenInLiveMode();
        }
      },
      onListeningChanged: (listening) {
        if (!listening &&
            mounted &&
            _isLiveMode &&
            _liveVoiceState == LiveVoiceState.listening) {
          if (_liveSpokenText.trim().isNotEmpty) {
            setState(() => _liveVoiceState = LiveVoiceState.thinking);
            _sendMessage(_liveSpokenText);
          } else {
            // Restart listen quickly so conversation feels continuous.
            Future.delayed(const Duration(milliseconds: 280), () {
              if (mounted &&
                  _isLiveMode &&
                  _liveVoiceState == LiveVoiceState.listening) {
                _listenInLiveMode();
              }
            });
          }
        }
      },
    );
  }

  void _speakLiveAiReply(String replyText, {VoidCallback? onComplete}) {
    if (!_isLiveMode) return;

    final lang = _ttsLocaleId(_selectedLanguage);
    debugPrint('🔊 [VOICE TTS OUT] "$replyText" ($lang)');

    setState(() {
      _liveVoiceState = LiveVoiceState.speaking;
      _liveAiReplyText = replyText;
    });

    // Prefer Live for low-latency speech when connected; still use TTS for certainty.
    if (_liveBridgeReady) {
      _liveService.sendRealtimeText(
        'Say this to the user naturally, briefly, with human tone: $replyText',
      );
    }

    _speechService.speak(
      replyText,
      language: lang,
      onComplete: () {
        if (!mounted || !_isLiveMode) return;
        if (onComplete != null) {
          onComplete();
        } else {
          _listenInLiveMode();
        }
      },
    );
  }

  void _interruptSpeaking() {
    _speechService.stopSpeaking();
    if (_isLiveMode) {
      _listenInLiveMode();
    }
  }

  // --- Text Dictation in Standard Mode ---
  void _toggleDictation() async {
    if (_isDictating) {
      await _speechService.stopListening();
      setState(() => _isDictating = false);
    } else {
      setState(() => _isDictating = true);
      final sttLocale = _sttLocaleId(_selectedLanguage);
      await _speechService.startListening(
        localeId: sttLocale,
        onPartialResult: (text) {
          if (!mounted) return;
          setState(() {
            _queryController.text = text;
            _queryController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          });
        },
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            _queryController.text = text;
            _isDictating = false;
          });
        },
        onListeningChanged: (listening) {
          if (mounted) setState(() => _isDictating = listening);
        },
      );
    }
  }

  // --- Photo Diagnostic Picker ---
  Future<void> _pickPhotoForAi() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;
    _sendMessage(_queryController.text.trim(), imagePath: picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final glowMode = !_isLiveMode
        ? SiriGlowMode.idle
        : switch (_liveVoiceState) {
            LiveVoiceState.listening => SiriGlowMode.listening,
            LiveVoiceState.thinking => SiriGlowMode.thinking,
            LiveVoiceState.speaking => SiriGlowMode.speaking,
            LiveVoiceState.paused => SiriGlowMode.idle,
          };

    return SiriGlowFrame(
      active: _isLiveMode,
      mode: glowMode,
      borderRadius: _isLiveMode ? 0 : 28,
      child: Scaffold(
      backgroundColor: _isLiveMode ? Colors.black : null,
      appBar: _isLiveMode
          ? null
          : AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.scheme.primary,
                    context.scheme.tertiary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Flexi AI Helper',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Cooperative Smart Assistant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Toggle Pill ("EN" / "हिन्दी")
          _buildLanguageTogglePill(),
          const SizedBox(width: 4),

          // Live Talk Launcher Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: _startLiveMode,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: context.scheme.primaryContainer.withValues(alpha: 0.8),
              ),
              icon: Icon(
                Icons.graphic_eq_rounded,
                size: 16,
                color: context.scheme.primary,
              ),
              label: Text(
                _selectedLanguage == 'hi' ? 'लाइव टॉक' : 'Live Talk',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.scheme.primary,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'reset') _resetChat();
              if (val == 'discover') context.push(RouteNames.customerAiDiscovery);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Restart Session'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'discover',
                child: Row(
                  children: [
                    Icon(Icons.explore_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Discover Services'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Main Chat View (hidden in Siri live mode) ---
          if (!_isLiveMode)
            Column(
            children: [
              // Message List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageItem(msg);
                  },
                ),
              ),

              // Dynamic Suggested Replies Horizontal Bar (hidden in live)
              if (_suggestedReplies.isNotEmpty && !_awaitingReply)
                _buildSuggestedRepliesBar(),

              // Modern Input Bar
              _buildBottomInputBar(),
            ],
          ),

          // --- Live Voice Talking Fullscreen / Floating Overlay ---
          if (_isLiveMode) _buildLiveVoiceOverlay(),
        ],
      ),
      ),
    );
  }

  // --- Multilingual Language Toggle Pill ---
  Widget _buildLanguageTogglePill() {
    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: _switchLanguage,
      itemBuilder: (context) => LocaleScope.supportedLocales
          .map(
            (code) => PopupMenuItem<String>(
              value: code,
              child: Text(
                '${_langLabels[code] ?? code}${_selectedLanguage == code ? '  ✓' : ''}',
              ),
            ),
          )
          .toList(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.isDark
              ? context.scheme.surfaceContainerHighest
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Text(
          _langLabels[_selectedLanguage] ?? _selectedLanguage.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.scheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayLangToggle() {
    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: _switchLanguage,
      itemBuilder: (context) => LocaleScope.supportedLocales
          .map(
            (code) => PopupMenuItem<String>(
              value: code,
              child: Text(_langLabels[code] ?? code),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: Text(
          _langLabels[_selectedLanguage] ?? _selectedLanguage.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // --- Message Item Builder ---
  Widget _buildMessageItem(_ChatMessage msg) {
    final isBot = msg.isBot;
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.scheme.primary,
                    context.scheme.tertiary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isBot
                        ? (context.isDark
                            ? context.scheme.surfaceContainerHighest
                            : const Color(0xFFF1F5F9))
                        : context.scheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isBot
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomRight: isBot
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: msg.loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: AiThinkingDots(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.38,
                                color: isBot
                                    ? context.scheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                            if (isBot) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _speechService.speak(msg.text),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      size: 16,
                                      color: context.scheme.primary
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: msg.text),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Copied to clipboard'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.copy_rounded,
                                      size: 15,
                                      color: context.scheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),

                // Booking Type Selection Quick Action Chips
                if (msg.action == 'PROMPT_BOOKING_TYPE')
                  _buildBookingTypeChips(),

                // Worker Carousel Card
                if (msg.workers.isNotEmpty)
                  _buildWorkerCarouselCard(msg.workers),

                // Strict Zero Workers Available Warning Card
                if (msg.action == 'NO_WORKERS_AVAILABLE')
                  _buildNoWorkersWarningCard(),

                // Estimate & Cooperative Fair Wage Policy Card
                if (msg.estimate != null && msg.booking == null)
                  _buildEstimateAndPolicyCard(msg.estimate!, msg.policy),

                // Booking Created Action Card
                if (msg.booking != null) _buildBookingCreatedCard(msg.booking!),

                // Booking Status Query Card
                if (msg.bookings.isNotEmpty)
                  _buildBookingListCard(msg.bookings),

                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isBot) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: BoxDecoration(
                color: context.scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: context.scheme.primary,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.08, end: 0);
  }

  // --- Booking Type Selection Chips ---
  Widget _buildBookingTypeChips() {
    final isHi = _selectedLanguage == 'hi';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          ActionChip(
            avatar: const Text('⚡', style: TextStyle(fontSize: 14)),
            label: Text(
              isHi ? '⚡ Emergency SOS (तुरंत)' : '⚡ Emergency SOS',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            onPressed: () => _sendMessage(isHi ? 'आपातकालीन सेवा (Emergency SOS) तुरंत' : '⚡ Emergency SOS urgently needed'),
          ),
          ActionChip(
            avatar: const Text('⏱️', style: TextStyle(fontSize: 14)),
            label: Text(
              isHi ? '⏱️ Standard (सामान्य)' : '⏱️ Standard Booking',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            backgroundColor: context.scheme.primary.withValues(alpha: 0.12),
            side: BorderSide(color: context.scheme.primary, width: 1.2),
            onPressed: () => _sendMessage(isHi ? 'सामान्य बुकिंग (Standard) कर दो' : 'Standard booking'),
          ),
          ActionChip(
            avatar: const Text('📅', style: TextStyle(fontSize: 14)),
            label: Text(
              isHi ? '📅 Schedule (आगे का समय)' : '📅 Schedule Later',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
            onPressed: () => _sendMessage(isHi ? 'बाद के समय के लिए शेड्यूल करें' : 'Schedule for later time'),
          ),
        ],
      ),
    );
  }

  // --- Worker Selection Carousel Card ---
  Widget _buildWorkerCarouselCard(List<dynamic> workers) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: workers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final w = workers[i] as Map<String, dynamic>;
          final name = w['name']?.toString() ?? 'Verified Worker';
          final rate = w['hourlyRate'] ?? 199;
          final rating = (w['rating'] as num?)?.toDouble() ?? 4.8;
          final jobs = w['ratingCount'] ?? 10;
          final society = w['society']?.toString() ?? 'Fixly Cooperative';
          final avatarUrl = w['avatar']?.toString();

          return Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.isDark ? context.scheme.surfaceContainerHighest : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.scheme.primary.withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: context.scheme.primary.withValues(alpha: 0.15),
                      backgroundImage: (avatarUrl != null && avatarUrl.startsWith('http')) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || !avatarUrl.startsWith('http'))
                          ? Icon(Icons.person, color: context.scheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                            ],
                          ),
                          Text(
                            society,
                            style: TextStyle(fontSize: 10.5, color: context.scheme.onSurface.withValues(alpha: 0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '$rating ($jobs)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '₹$rate/hr',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => _sendMessage('Select worker: $name (ID: ${w['_id']})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.scheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Select Worker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Strict Zero Workers Warning Card ---
  Widget _buildNoWorkersWarningCard() {
    final isHi = _selectedLanguage == 'hi';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 6),
              Text(
                isHi ? 'कोई ऑनलाइन कार्यकर्ता उपलब्ध नहीं' : 'No Online Workers Available',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isHi
                ? 'इस श्रेणी में सभी सत्यापित कार्यकर्ता वर्तमान में ऑफ़लाइन या व्यस्त हैं। फिक्सली केवल वास्तविक कार्यकर्ता उपलब्धता की गारंटी देता है।'
                : 'All certified workers in this category are currently offline or busy. To avoid ghost bookings, Fixly requires verified worker availability.',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _sendMessage(isHi ? 'बाद के समय के लिए शेड्यूल करें' : 'Schedule for later'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  ),
                  child: Text(
                    isHi ? '📅 बाद में शेड्यूल करें' : '📅 Schedule for Later',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _sendMessage(isHi ? 'अन्य सेवाएं देखें' : 'Try another service'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    backgroundColor: const Color(0xFFD97706),
                  ),
                  child: Text(
                    isHi ? 'अन्य सेवाएं' : 'Other Services',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Estimate & Cooperative Fair Wage Policy Card ---
  Widget _buildEstimateAndPolicyCard(Map<String, dynamic> estimate, Map<String, dynamic>? policy) {
    final isHi = _selectedLanguage == 'hi';
    final basePrice = estimate['baseServiceFee'] ?? 150;
    final urgentFee = estimate['urgentFee'] ?? 0;
    final platformFee = estimate['platformFee'] ?? 0;
    final total = estimate['totalAmount'] ?? (basePrice + urgentFee + platformFee);

    final policyTitle = policy?['title']?.toString() ??
        (isHi ? 'फिक्सली उचित पारिश्रमिक एवं कल्याण गारंटी' : 'Fixly Cooperative Fair Wage Guarantee');
    final fairWageNotice = policy?['fairWageNotice']?.toString() ??
        (isHi
            ? 'सेवा शुल्क का 100% सीधे सहकारी कार्यकर्ता को जाता है।'
            : '100% of the service fee goes directly to the cooperative worker.');
    final welfareNotice = policy?['welfareFundNotice']?.toString() ??
        (isHi
            ? 'कार्यकर्ता सामाजिक सुरक्षा और चिकित्सा दुर्घटना कोष में 5% योगदान शामिल।'
            : 'Includes 5% contribution to Worker Social Security & Medical Accident Fund.');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? context.scheme.surfaceContainerHighest : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 6),
              Text(
                isHi ? 'मूल्य अनुमान एवं पारिश्रमिक विवरण' : 'Price Estimate & Fair Wage Breakdown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildEstimateRow(
            isHi ? 'आधार विज़िट / जांच शुल्क' : 'Base Visiting / Diagnosis Fee',
            '₹$basePrice',
          ),
          if (urgentFee > 0)
            _buildEstimateRow(
              isHi ? 'आपातकालीन SOS प्राथमिकता शुल्क' : 'Emergency SOS Priority Surcharge',
              '+₹$urgentFee',
              isHighlight: true,
            ),
          _buildEstimateRow(
            isHi ? 'फिक्सली प्लेटफ़ॉर्म शुल्क (0% बिचौलिया)' : 'Fixly Platform Fee (0% Middleman)',
            '₹$platformFee',
            isGreen: true,
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHi ? 'कुल अनुमानित राशि' : 'Total Estimated Amount',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                '₹$total',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF047857)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policyTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$fairWageNotice • $welfareNotice',
                        style: TextStyle(fontSize: 10.5, color: context.scheme.onSurface.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _sendMessage(isHi ? 'रद्द करें' : 'Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    isHi ? 'रद्द करें' : 'Cancel',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _sendMessage(isHi ? 'हाँ, बुकिंग कन्फर्म करें' : 'Yes, confirm booking'),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    isHi ? 'बुकिंग कन्फर्म करें' : 'Confirm Booking',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateRow(String label, String value, {bool isHighlight = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.scheme.onSurface.withValues(alpha: 0.7))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlight
                  ? const Color(0xFFDC2626)
                  : (isGreen ? const Color(0xFF059669) : context.scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // --- Booking Created Rich Card ---
  Widget _buildBookingCreatedCard(Map<String, dynamic> booking) {
    final bookingId = booking['bookingId'] ?? '#BK-CONFIRMED';
    final totalAmount = booking['invoice']?['totalAmount'] ?? 200;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Booking Confirmed ($bookingId)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estimated Fee: ₹$totalAmount • Verified worker will be assigned shortly.',
            style: TextStyle(
              fontSize: 12,
              color: context.scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => context.push(RouteNames.customerOrders),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.18),
                  ),
                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => context.push(RouteNames.customerTracking),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text(
                  'Track Live',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Booking List Rich Card ---
  Widget _buildBookingListCard(List<dynamic> bookings) {
    final latest = bookings.first as Map<String, dynamic>;
    final bookingId = latest['bookingId'] ?? '#BK';
    final status = latest['status'] ?? 'PENDING';
    final worker = latest['worker'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order $bookingId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (worker != null) ...[
            const SizedBox(height: 6),
            Text(
              'Worker: ${worker['name'] ?? 'Assigned Professional'}',
              style: TextStyle(
                fontSize: 12,
                color: context.scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (worker['phone'] != null)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:${worker['phone']}')),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_rounded, size: 14, color: context.scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Call Worker (${worker['phone']})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // --- Dynamic AI Suggested Replies Bar ---
  Widget _buildSuggestedRepliesBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _suggestedReplies[index];
          return ActionChip(
            onPressed: () => _sendMessage(reply),
            backgroundColor: context.isDark
                ? context.scheme.surfaceContainerHighest
                : Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: context.scheme.primary.withValues(alpha: 0.25),
              ),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: context.scheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  reply,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: context.scheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Bottom Messenger Style Input Bar ---
  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: context.scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Photo Diagnostic Button
            IconButton(
              onPressed: _pickPhotoForAi,
              tooltip: 'Attach Issue Photo',
              icon: Icon(
                Icons.add_photo_alternate_rounded,
                color: context.scheme.onSurface.withValues(alpha: 0.7),
                size: 22,
              ),
            ),

            // Live Voice Launcher Button
            IconButton(
              onPressed: _startLiveMode,
              tooltip: 'Live Talking Mode',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.scheme.primary,
                      context.scheme.tertiary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),

            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.isDark
                      ? context.scheme.surfaceContainerHighest
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _queryController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (val) => _sendMessage(val),
                  decoration: InputDecoration(
                    hintText: _isDictating
                        ? (_selectedLanguage == 'hi' ? 'सुन रहा हूँ...' : 'Listening...')
                        : (_selectedLanguage == 'hi'
                            ? 'समस्या बताएं या Live Talk दबाएं...'
                            : 'Ask AI anything or tap Live Talk...'),
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: context.scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      onPressed: _toggleDictation,
                      icon: Icon(
                        _isDictating ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isDictating
                            ? Colors.redAccent
                            : context.scheme.onSurface.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send Button
            Material(
              color: context.scheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _awaitingReply
                    ? null
                    : () => _sendMessage(_queryController.text),
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AI Live Voice Talking Fullscreen Overlay ---
  // --- Siri-style live: edge glow + chats only ---
  Widget _buildLiveVoiceOverlay() {
    final isListening = _liveVoiceState == LiveVoiceState.listening;
    final isThinking = _liveVoiceState == LiveVoiceState.thinking;
    final isSpeaking = _liveVoiceState == LiveVoiceState.speaking;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _closeLiveMode();
                        if (widget.startInLiveMode && context.canPop()) {
                          context.pop();
                        }
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      isSpeaking
                          ? 'Flexi speaking'
                          : (isThinking
                              ? 'Thinking'
                              : (isListening ? 'Listening' : 'Paused')),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    _buildOverlayLangToggle(),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  itemCount: _messages.length +
                      (_liveSpokenText.trim().isNotEmpty && isListening ? 1 : 0) +
                      (isThinking ? 1 : 0) +
                      (isSpeaking && _liveAiReplyText.trim().isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      return _buildSiriChatLine(_messages[index]);
                    }
                    var after = index - _messages.length;
                    final hasPartial =
                        _liveSpokenText.trim().isNotEmpty && isListening;
                    if (hasPartial) {
                      if (after == 0) {
                        // Live partial — plain text (avoid restart flicker).
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _liveSpokenText,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }
                      after -= 1;
                    }
                    if (isThinking && after == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AiThinkingDots(color: Colors.white70),
                        ),
                      );
                    }
                    // Speaking transcript / TTS line
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AiFadeInText(
                          text: _liveAiReplyText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 20,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Siri-style orb — bottom center, transparent GIF (no plate BG)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSpeaking)
                      TextButton(
                        onPressed: _interruptSpeaking,
                        child: const Text(
                          'Tap to interrupt',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    Semantics(
                      label: isSpeaking
                          ? 'Flexi speaking'
                          : (isThinking ? 'Flexi thinking' : 'Flexi listening'),
                      child: ExcludeSemantics(
                        child: Image.asset(
                          'assets/ai/siri_orb.gif',
                          width: 132,
                          height: 132,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, error, stackTrace) => const SizedBox(
                            width: 132,
                            height: 132,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiriChatLine(_ChatMessage msg) {
    final isBot = msg.isBot;
    if (msg.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AiThinkingDots(color: Colors.white70),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          ),
          child: AiFadeInText(
            text: msg.text,
            style: TextStyle(
              color: isBot ? Colors.white.withValues(alpha: 0.92) : Colors.white,
              fontSize: isBot ? 20 : 17,
              height: 1.35,
              fontWeight: isBot ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
