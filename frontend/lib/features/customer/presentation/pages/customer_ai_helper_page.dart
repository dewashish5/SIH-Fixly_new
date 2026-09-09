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
import '../../../../services/speech_service.dart';
import '../../../ai/data/ai_api_repository.dart';

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
  final String? category;
  final String? imagePath;
}

class CustomerAiHelperPage extends StatefulWidget {
  const CustomerAiHelperPage({super.key});

  @override
  State<CustomerAiHelperPage> createState() => _CustomerAiHelperPageState();
}

class _CustomerAiHelperPageState extends State<CustomerAiHelperPage>
    with SingleTickerProviderStateMixin {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _speechService = SpeechService();

  final _messages = <_ChatMessage>[];
  Map<String, dynamic> _conversationState = {};
  bool _awaitingReply = false;
  bool _isDictating = false;

  // --- Dynamic AI Suggested Replies ---
  List<String> _suggestedReplies = [
    '💧 Tap leaking in bathroom',
    '⚡ Switchboard sparking / MCB tripping',
    '🧹 Deep home cleaning needed',
    '❄️ AC not cooling properly',
    '📦 Check my booking status',
  ];

  // --- Live Voice Talking Mode ---
  bool _isLiveMode = false;
  LiveVoiceState _liveVoiceState = LiveVoiceState.listening;
  String _liveSpokenText = '';
  String _liveAiReplyText = '';
  late AnimationController _pulseAnimController;

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _speechService.initialize();

    // Initial greeting
    _messages.add(
      _ChatMessage(
        isBot: true,
        text:
            'Hello! I am Flexi AI, your smart home service assistant. '
            'Tell me what problem you are facing or tap "Live Talk" to converse with me directly.',
        timestamp: DateTime.now(),
        action: 'PROMPT_CATEGORY',
      ),
    );
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    _speechService.stopListening();
    _speechService.stopSpeaking();
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
        final res = await AiApiRepository().chatWithAgent(
          message: query,
          conversationState: _conversationState,
        );

        if (!mounted) return;
        setState(() {
          _conversationState = res.state;
          _messages.removeLast();
          _messages.add(
            _ChatMessage(
              isBot: true,
              text: res.reply,
              timestamp: DateTime.now(),
              action: res.action,
              booking: res.booking,
              bookings: res.bookings,
              category: res.state['category']?.toString(),
            ),
          );
          _awaitingReply = false;
          _suggestedReplies = res.suggestedReplies.isNotEmpty
              ? res.suggestedReplies
              : _generateFallbackSuggestions(res.action, res.reply);
        });

        // If Live Mode is active, speak the AI reply aloud and cycle back to listening
        if (_isLiveMode) {
          _speakLiveAiReply(res.reply);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _ChatMessage(
            isBot: true,
            text: 'I could not process that request right now. Please try again or tap one of the suggested options.',
            timestamp: DateTime.now(),
          ),
        );
        _awaitingReply = false;
        _suggestedReplies = [
          '💧 Plumbing assistance',
          '⚡ Electrician assistance',
          '🧹 Cleaning services',
          'Track my orders',
        ];
      });

      if (_isLiveMode) {
        setState(() {
          _liveVoiceState = LiveVoiceState.listening;
          _liveAiReplyText = 'Please try saying that again.';
        });
        _listenInLiveMode();
      }
    }

    _scrollToBottom();
  }

  List<String> _generateFallbackSuggestions(String? action, String reply) {
    final lower = reply.toLowerCase();
    if (action == 'BOOKING_CREATED' || lower.contains('confirmed')) {
      return ['Track worker arrival', 'View my bookings', 'Book another service'];
    }
    if (action == 'BOOKING_STATUS' || lower.contains('booking #')) {
      return ['Call worker', 'View order details', 'Book a new service'];
    }
    if (action == 'CONFIRM_EMERGENCY_BOOKING' || lower.contains('emergency') || lower.contains('sos')) {
      return ['Yes, dispatch worker now', 'Change details', 'Cancel request'];
    }
    if (action == 'PROMPT_CONFIRMATION' || lower.contains('confirm')) {
      return ['Yes, confirm booking', 'What is the price?', 'Change address', 'Cancel'];
    }
    return [
      'Need a plumber',
      'Need an electrician',
      'Deep cleaning',
      'Check booking status',
    ];
  }

  // --- Reset Conversation ---
  void _resetChat() {
    setState(() {
      _messages.clear();
      _conversationState = {};
      _suggestedReplies = [
        '💧 Tap leaking in bathroom',
        '⚡ Switchboard sparking / MCB tripping',
        '🧹 Deep home cleaning needed',
        '❄️ AC not cooling properly',
        '📦 Check my booking status',
      ];
      _messages.add(
        _ChatMessage(
          isBot: true,
          text: 'Conversation reset. How can I help you today?',
          timestamp: DateTime.now(),
          action: 'PROMPT_CATEGORY',
        ),
      );
    });
  }

  // --- Live Voice Mode Engine ---
  void _startLiveMode() {
    setState(() {
      _isLiveMode = true;
      _liveVoiceState = LiveVoiceState.listening;
      _liveSpokenText = '';
      _liveAiReplyText = 'Listening... Speak naturally to Flexi AI';
    });
    HapticFeedback.mediumImpact();
    _listenInLiveMode();
  }

  void _closeLiveMode() {
    _speechService.stopListening();
    _speechService.stopSpeaking();
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

    await _speechService.startListening(
      onPartialResult: (text) {
        if (!mounted || !_isLiveMode) return;
        setState(() => _liveSpokenText = text);
      },
      onResult: (finalText) {
        if (!mounted || !_isLiveMode) return;
        if (finalText.trim().isNotEmpty) {
          setState(() {
            _liveSpokenText = finalText;
            _liveVoiceState = LiveVoiceState.thinking;
          });
          _sendMessage(finalText);
        }
      },
      onListeningChanged: (listening) {
        if (!listening && mounted && _isLiveMode && _liveVoiceState == LiveVoiceState.listening) {
          if (_liveSpokenText.trim().isNotEmpty) {
            setState(() => _liveVoiceState = LiveVoiceState.thinking);
            _sendMessage(_liveSpokenText);
          }
        }
      },
    );
  }

  void _speakLiveAiReply(String replyText) {
    if (!_isLiveMode) return;

    setState(() {
      _liveVoiceState = LiveVoiceState.speaking;
      _liveAiReplyText = replyText;
    });

    _speechService.speak(
      replyText,
      onComplete: () {
        if (!mounted || !_isLiveMode) return;
        // Automatically switch back to listening for natural conversational exchange!
        _listenInLiveMode();
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
      await _speechService.startListening(
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
    return Scaffold(
      appBar: AppBar(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Flexi AI Helper',
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
                    Text(
                      'Cooperative Smart Assistant',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Live Talk Launcher Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: _startLiveMode,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: context.scheme.primaryContainer.withValues(alpha: 0.8),
              ),
              icon: Icon(
                Icons.graphic_eq_rounded,
                size: 17,
                color: context.scheme.primary,
              ),
              label: Text(
                'Live Talk',
                style: TextStyle(
                  fontSize: 12,
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
          // --- Main Chat View ---
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

              // Dynamic Suggested Replies Horizontal Bar
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
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thinking...',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
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
                    hintText: _isDictating ? 'Listening...' : 'Ask AI anything or tap Live Talk...',
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
  Widget _buildLiveVoiceOverlay() {
    final isListening = _liveVoiceState == LiveVoiceState.listening;
    final isThinking = _liveVoiceState == LiveVoiceState.thinking;
    final isSpeaking = _liveVoiceState == LiveVoiceState.speaking;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Close button and Live Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isSpeaking
                                ? Colors.cyanAccent
                                : (isThinking
                                    ? Colors.amberAccent
                                    : const Color(0xFF10B981)),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isSpeaking
                                        ? Colors.cyanAccent
                                        : const Color(0xFF10B981))
                                    .withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI LIVE TALKING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _closeLiveMode,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Animated Pulsating Glowing Voice Orb
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseAnimController.value * 0.15);
                    final glowRadius = 24.0 + (_pulseAnimController.value * 28.0);

                    return Container(
                      width: 160 * scale,
                      height: 160 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isSpeaking
                              ? [
                                  Colors.cyanAccent,
                                  context.scheme.primary,
                                  Colors.transparent,
                                ]
                              : (isThinking
                                  ? [
                                      Colors.purpleAccent,
                                      Colors.deepPurple,
                                      Colors.transparent,
                                    ]
                                  : [
                                      const Color(0xFF10B981),
                                      context.scheme.primary,
                                      Colors.transparent,
                                    ]),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isSpeaking
                                    ? Colors.cyanAccent
                                    : (isThinking
                                        ? Colors.purpleAccent
                                        : const Color(0xFF10B981)))
                                .withValues(alpha: 0.4),
                            blurRadius: glowRadius,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSpeaking
                                ? Icons.volume_up_rounded
                                : (isThinking
                                    ? Icons.hourglass_top_rounded
                                    : Icons.mic_rounded),
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Status State Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSpeaking
                      ? 'Flexi AI is Speaking...'
                      : (isThinking
                          ? 'Thinking & Finding Match...'
                          : 'Listening to You...'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSpeaking
                        ? Colors.cyanAccent
                        : (isThinking ? Colors.amberAccent : const Color(0xFF34D399)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Live Subtitles / Live Transcript Box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 80, maxHeight: 150),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    isSpeaking
                        ? _liveAiReplyText
                        : (_liveSpokenText.isNotEmpty
                            ? _liveSpokenText
                            : 'Speak now (e.g. "My AC is leaking", "Need an electrician", "Where is my worker")'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isSpeaking ? Colors.white : Colors.white70,
                      fontWeight:
                          isSpeaking ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Quick Suggested Replies in Live Mode
              if (_suggestedReplies.isNotEmpty && !isThinking)
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _suggestedReplies.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chip = _suggestedReplies[index];
                      return ActionChip(
                        onPressed: () {
                          if (isSpeaking) _speechService.stopSpeaking();
                          _sendMessage(chip);
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        label: Text(
                          chip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Bottom Control Buttons in Live Mode
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute / Pause Listening
                    IconButton.filledTonal(
                      onPressed: () {
                        if (isListening) {
                          _speechService.stopListening();
                          setState(() => _liveVoiceState = LiveVoiceState.paused);
                        } else {
                          _listenInLiveMode();
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: Icon(
                        isListening ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    // Main Action (Stop AI speaking or Force Send)
                    if (isSpeaking)
                      FilledButton.icon(
                        onPressed: _interruptSpeaking,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Interrupt / Speak'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () {
                          if (_liveSpokenText.trim().isNotEmpty) {
                            _sendMessage(_liveSpokenText);
                          } else {
                            _listenInLiveMode();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: context.scheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Send Spoken Words'),
                      ),

                    // End Live Session
                    IconButton.filledTonal(
                      onPressed: _closeLiveMode,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.redAccent,
                        size: 24,
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
}
