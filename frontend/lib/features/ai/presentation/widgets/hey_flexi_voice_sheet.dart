import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/location/app_location.dart';
import '../../../../services/speech_service.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';
import '../../data/ai_api_repository.dart';

enum HeyFlexiState { listening, thinking, speaking, idle, confirmed }

class HeyFlexiVoiceSheet extends StatefulWidget {
  const HeyFlexiVoiceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (_) => const HeyFlexiVoiceSheet(),
    );
  }

  @override
  State<HeyFlexiVoiceSheet> createState() => _HeyFlexiVoiceSheetState();
}

class _HeyFlexiVoiceSheetState extends State<HeyFlexiVoiceSheet>
    with SingleTickerProviderStateMixin {
  final _speechService = SpeechService();
  final _aiRepo = AiApiRepository();
  final _textController = TextEditingController();

  HeyFlexiState _state = HeyFlexiState.listening;
  String _spokenText = '';
  String _aiReplyText = 'Listening... Speak naturally to Flexi (Hindi or English)';
  Map<String, dynamic> _conversationState = {};
  List<String> _suggestedReplies = [
    '💧 Nal leak ho raha hai (Plumber)',
    '⚡ Switch kharab hai (Electrician)',
    '🧹 Deep cleaning chahiye',
    '📦 Booking status check karo',
  ];
  Map<String, dynamic>? _createdBooking;

  late AnimationController _pulseController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initAndListen();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulseController.dispose();
    _textController.dispose();
    _speechService.stopListening();
    _speechService.stopSpeaking();
    super.dispose();
  }

  Future<void> _initAndListen() async {
    await _speechService.initialize();
    if (!_isDisposed && mounted) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _state = HeyFlexiState.listening;
      _spokenText = '';
    });

    final currentLocale = context.read<AppSessionCubit>().state.locale;
    final localeId = currentLocale == 'hi' ? 'hi_IN' : 'en_IN';

    await _speechService.startListening(
      localeId: localeId,
      onPartialResult: (text) {
        if (!_isDisposed && mounted) {
          setState(() => _spokenText = text);
        }
      },
      onResult: (finalText) {
        if (!_isDisposed && mounted && finalText.trim().isNotEmpty) {
          setState(() {
            _spokenText = finalText;
            _state = HeyFlexiState.thinking;
          });
          _sendMessage(finalText);
        }
      },
      onListeningChanged: (listening) {
        if (!listening &&
            !_isDisposed &&
            mounted &&
            _state == HeyFlexiState.listening) {
          if (_spokenText.trim().isNotEmpty) {
            setState(() => _state = HeyFlexiState.thinking);
            _sendMessage(_spokenText);
          }
        }
      },
    );
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    setState(() {
      _state = HeyFlexiState.thinking;
      _suggestedReplies = [];
    });

    try {
      final sessionCubit = context.read<AppSessionCubit>();
      final lang = sessionCubit.state.locale;

      List<double>? coords;
      if (AppLocation.instance.hasFix) {
        coords = [
          AppLocation.instance.requireLng,
          AppLocation.instance.requireLat,
        ];
      }

      final address = AppLocation.instance.addressLabel;

      final res = await _aiRepo.chatWithAgent(
        message: query,
        conversationState: _conversationState,
        language: lang,
        coordinates: coords,
        addressLine: address,
      );

      if (_isDisposed || !mounted) return;

      // 1. Update multi-turn state in memory
      _conversationState = res.state;

      setState(() {
        _aiReplyText = res.reply;
        _suggestedReplies = res.suggestedReplies;
      });

      // 2. Action Handlers
      if (res.action == 'SESSION_EXPIRED') {
        // Reset state from memory and allow fresh input
        _conversationState = {};
        _speakAiReply(res.reply, onComplete: () {
          if (!_isDisposed && mounted) {
            _startListening();
          }
        });
      } else if (res.action == 'SESSION_ABORTED') {
        // Reset state and close modal
        _conversationState = {};
        _speakAiReply(res.reply, onComplete: () {
          if (!_isDisposed && mounted) {
            Navigator.of(context).pop();
          }
        });
      } else if (res.action == 'BOOKING_CREATED') {
        // Booking Placed -> direct navigation to Live Tracking screen
        _createdBooking = res.booking;
        setState(() => _state = HeyFlexiState.confirmed);
        HapticFeedback.heavyImpact();

        final bookingId = res.booking?['bookingId'] ?? res.booking?['_id'];

        _speakAiReply(res.reply, onComplete: () {
          if (!_isDisposed && mounted) {
            Navigator.of(context).pop();
            if (bookingId != null) {
              context.push('${RouteNames.customerTracking}?bookingId=$bookingId');
            } else {
              context.push(RouteNames.customerTracking);
            }
          }
        });
      } else {
        // Standard turn -> speak reply and listen for next turn
        _speakAiReply(res.reply, onComplete: () {
          if (!_isDisposed && mounted) {
            _startListening();
          }
        });
      }
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _state = HeyFlexiState.idle;
        _aiReplyText = 'Sorry, could not process request. Please tap mic and try again.';
      });
    }
  }

  void _speakAiReply(String replyText, {VoidCallback? onComplete}) {
    if (_isDisposed || !mounted) return;

    setState(() => _state = HeyFlexiState.speaking);

    final lang = _conversationState['language'] == 'hi' ? 'hi-IN' : 'en-IN';
    _speechService.speak(
      replyText,
      language: lang,
      onComplete: () {
        if (!_isDisposed && mounted) {
          onComplete?.call();
        }
      },
    );
  }

  void _interrupt() {
    _speechService.stopSpeaking();
    _speechService.stopListening();
    if (_state == HeyFlexiState.speaking || _state == HeyFlexiState.thinking) {
      _startListening();
    } else {
      setState(() => _state = HeyFlexiState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isListening = _state == HeyFlexiState.listening;
    final isThinking = _state == HeyFlexiState.thinking;
    final isSpeaking = _state == HeyFlexiState.speaking;
    final isConfirmed = _state == HeyFlexiState.confirmed;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isConfirmed
              ? const Color(0xFF10B981)
              : Colors.cyanAccent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConfirmed
                    ? const Color(0xFF10B981)
                    : (isSpeaking
                        ? Colors.cyanAccent
                        : (isThinking ? Colors.purpleAccent : const Color(0xFF10B981))))
                .withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Drag Handle & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Hey Flexi AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Animated Pulsing Voice Orb
              GestureDetector(
                onTap: () {
                  if (isSpeaking) {
                    _interrupt();
                  } else if (isListening) {
                    _speechService.stopListening();
                    setState(() => _state = HeyFlexiState.idle);
                  } else {
                    _startListening();
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = isListening || isSpeaking
                        ? 1.0 + (_pulseController.value * 0.12)
                        : 1.0;
                    final glowRadius = 20.0 + (_pulseController.value * 24.0);

                    final orbColor = isConfirmed
                        ? const Color(0xFF10B981)
                        : (isSpeaking
                            ? Colors.cyanAccent
                            : (isThinking
                                ? Colors.purpleAccent
                                : (isListening
                                    ? const Color(0xFF10B981)
                                    : Colors.white38)));

                    return Container(
                      width: 110 * scale,
                      height: 110 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            orbColor.withValues(alpha: 0.8),
                            orbColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: orbColor.withValues(alpha: 0.35),
                            blurRadius: glowRadius,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: orbColor, width: 2),
                          ),
                          child: Icon(
                            isConfirmed
                                ? Icons.check_circle_rounded
                                : (isSpeaking
                                    ? Icons.volume_up_rounded
                                    : (isThinking
                                        ? Icons.hourglass_top_rounded
                                        : (isListening
                                            ? Icons.mic_rounded
                                            : Icons.mic_off_rounded))),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isConfirmed
                      ? 'Booking Confirmed! Navigating to tracking...'
                      : (isSpeaking
                          ? 'Flexi is Speaking...'
                          : (isThinking
                              ? 'Analyzing & Finding Best Pro...'
                              : (isListening
                                  ? 'Listening... Speak now'
                                  : 'Tap mic to speak'))),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isConfirmed
                        ? const Color(0xFF34D399)
                        : (isSpeaking
                            ? Colors.cyanAccent
                            : (isThinking
                                ? Colors.amberAccent
                                : const Color(0xFF34D399))),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Transcript / AI Reply Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(minHeight: 64, maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    isSpeaking
                        ? _aiReplyText
                        : (_spokenText.isNotEmpty
                            ? _spokenText
                            : _aiReplyText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isSpeaking ? Colors.white : Colors.white70,
                      fontWeight: isSpeaking ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ),

              if (_createdBooking != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Booking #${_createdBooking!['bookingId'] ?? 'CONFIRMED'}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Quick Suggested Responses
              if (_suggestedReplies.isNotEmpty && !isThinking && !isConfirmed)
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestedReplies.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chip = _suggestedReplies[index];
                      return ActionChip(
                        onPressed: () {
                          _speechService.stopSpeaking();
                          _sendMessage(chip);
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        label: Text(
                          chip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),

              // Inline Text Input (Keyboard Fallback for Emulator / Direct Typing)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Or type issue (e.g. Bijli nahi aa rahi)...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (val) {
                          final query = val.trim();
                          if (query.isNotEmpty) {
                            _speechService.stopSpeaking();
                            _speechService.stopListening();
                            _sendMessage(query);
                            _textController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final query = _textController.text.trim();
                        if (query.isNotEmpty) {
                          _speechService.stopSpeaking();
                          _speechService.stopListening();
                          _sendMessage(query);
                          _textController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _speechService.stopSpeaking();
                      _speechService.stopListening();
                      _conversationState = {};
                      setState(() {
                        _state = HeyFlexiState.idle;
                        _spokenText = '';
                        _aiReplyText = 'Session reset. Tap mic to start fresh.';
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white60),
                    label: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  if (isSpeaking)
                    FilledButton.tonalIcon(
                      onPressed: _interrupt,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
                      ),
                      icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.redAccent),
                      label: const Text(
                        'Stop Speaking',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        if (isListening) {
                          _speechService.stopListening();
                          setState(() => _state = HeyFlexiState.idle);
                        } else {
                          _startListening();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                      ),
                      icon: Icon(
                        isListening ? Icons.pause : Icons.mic,
                        size: 16,
                        color: const Color(0xFF0F172A),
                      ),
                      label: Text(
                        isListening ? 'Pause' : 'Tap to Speak',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
