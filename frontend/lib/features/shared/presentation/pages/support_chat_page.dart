import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../services/speech_service.dart';
import '../cubit/support_cubit.dart';
import '../../data/support_api_repository.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _speechService = SpeechService();

  bool _isRecordingVoice = false;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadChat();
    _speechService.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speechService.stopListening();
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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<SupportCubit>().sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _sendSnippet(String snippet) {
    if (snippet.toLowerCase().contains('human') ||
        snippet.toLowerCase().contains('agent')) {
      context.read<SupportCubit>().escalateToHuman();
    } else {
      context.read<SupportCubit>().sendMessage(snippet);
    }
    _scrollToBottom();
  }

  // --- Attachment Pickers ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      setState(() => _isUploadingMedia = true);
      await context.read<SupportCubit>().sendMediaMessage(
            filePath: picked.path,
            mediaType: 'image',
          );
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null || !mounted) return;

      setState(() => _isUploadingMedia = true);
      await context.read<SupportCubit>().sendMediaMessage(
            filePath: picked.path,
            mediaType: 'video',
          );
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _pickVoiceOrAudio() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
      );
      if (file == null || !mounted) return;
      final path = file.path;
      if (path == null || path.isEmpty) return;

      setState(() => _isUploadingMedia = true);
      await context.read<SupportCubit>().sendMediaMessage(
            filePath: path,
            mediaType: 'audio',
          );
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  void _toggleSpeechToText() async {
    if (_isRecordingVoice) {
      await _speechService.stopListening();
      setState(() => _isRecordingVoice = false);
    } else {
      final success = await _speechService.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            _controller.text = text;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          });
        },
        onListeningChanged: (listening) {
          if (mounted) setState(() => _isRecordingVoice = listening);
        },
      );
      if (!success && mounted) {
        setState(() => _isRecordingVoice = false);
      }
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Attach Media for Support',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachmentItem(
                      icon: Icons.camera_alt_rounded,
                      color: Colors.pink,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.photo_library_rounded,
                      color: Colors.purple,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.videocam_rounded,
                      color: Colors.orange,
                      label: 'Video',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickVideo();
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.mic_rounded,
                      color: Colors.teal,
                      label: 'Audio Note',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickVoiceOrAudio();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPreview(String url, String mediaType) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: mediaType == 'image'
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : const Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(),
                              ),
                      )
                    : Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              mediaType == 'video'
                                  ? Icons.movie_creation_outlined
                                  : Icons.audiotrack_rounded,
                              size: 48,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mediaType == 'video'
                                  ? 'Video Attachment'
                                  : 'Voice / Audio Note',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Open Attachment'),
                            ),
                          ],
                        ),
                      ),
              ),
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return BlocConsumer<SupportCubit, SupportState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: const BackButton(),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: state.isAgentActive
                      ? Colors.teal.withValues(alpha: 0.15)
                      : (state.isEscalated
                          ? Colors.amber.withValues(alpha: 0.15)
                          : context.scheme.primary.withValues(alpha: 0.12)),
                  child: Icon(
                    state.isAgentActive
                        ? Icons.support_agent_rounded
                        : (state.isEscalated
                            ? Icons.hourglass_top_rounded
                            : Icons.auto_awesome_rounded),
                    size: 20,
                    color: state.isAgentActive
                        ? Colors.teal
                        : (state.isEscalated
                            ? Colors.amber.shade800
                            : context.scheme.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.supportChat,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: state.isAgentActive
                                  ? Colors.teal
                                  : (state.isEscalated
                                      ? Colors.amber
                                      : Colors.green),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              state.isAgentActive
                                  ? 'Human Agent Connected'
                                  : (state.isEscalated
                                      ? 'Waiting for Human Agent...'
                                      : (state.isResolved
                                          ? 'Issue Resolved'
                                          : 'Fixly AI Assistant Active')),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: state.isEscalated
                                        ? Colors.amber.shade800
                                        : context.scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'reset':
                      context.read<SupportCubit>().resetChat();
                      break;
                    case 'escalate':
                      context.read<SupportCubit>().escalateToHuman();
                      break;
                    case 'switch_ai':
                      context.read<SupportCubit>().sendMessage('switch to bot');
                      break;
                    case 'refresh':
                      context.read<SupportCubit>().loadChat();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Start Fresh Chat'),
                      ],
                    ),
                  ),
                  if (state.isHandledByBot && !state.isEscalated)
                    const PopupMenuItem(
                      value: 'escalate',
                      child: Row(
                        children: [
                          Icon(Icons.support_agent_rounded, size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Talk to Human Agent'),
                        ],
                      ),
                    ),
                  if (!state.isHandledByBot || state.isEscalated)
                    const PopupMenuItem(
                      value: 'switch_ai',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Switch to AI Assistant'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh Chat'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Escalation Notice Banner
              if (state.isEscalated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  color: Colors.amber.shade50,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Your ticket has been escalated to our Human Support Desk. An admin agent has been notified and will take over shortly.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<SupportCubit>().sendMessage('switch to bot'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Use AI instead', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

              // Chat Messages View
              Expanded(
                child: state.status == SupportStatus.loading &&
                        state.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : (state.messages.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final msg = state.messages[index];
                              return _buildMessageItem(context, msg, timeFormat);
                            },
                          )),
              ),

              // Sending / Uploading indicator
              if (state.isSending || _isUploadingMedia)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isUploadingMedia
                                ? 'Uploading media attachment...'
                                : 'Fixly AI is replying...',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // AI Suggested Quick Reply Snippets
              if (state.quickReplies.isNotEmpty && !state.isResolved)
                _buildQuickRepliesRow(context, state.quickReplies),

              // Modern Messenger Bottom Input Bar
              _buildModernInputBar(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: context.scheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 38,
                color: context.scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How can Fixly AI help you?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything about your bookings, tracking, payments, or safety. You can also attach photos or videos of the issue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    SupportMessageModel msg,
    DateFormat timeFormat,
  ) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: context.scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            msg.body,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    final isAi = msg.isAi;
    final isAdmin = msg.isAdmin;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender tag
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAi
                          ? Icons.auto_awesome_rounded
                          : Icons.support_agent_rounded,
                      size: 13,
                      color: isAi ? Colors.deepPurple : Colors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAi
                          ? 'Fixly AI'
                          : (msg.senderName ?? 'Support Agent (Admin)'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAi ? Colors.deepPurple : Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),

            // Message Bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? context.scheme.primary
                    : (isAi
                        ? context.scheme.surfaceContainerLow
                        : Colors.teal.shade50),
                border: Border.all(
                  color: isUser
                      ? Colors.transparent
                      : (isAi
                          ? context.scheme.outlineVariant.withValues(alpha: 0.6)
                          : Colors.teal.shade200),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Render Media Attachments if present
                  if (msg.hasAttachments) ...[
                    for (final attUrl in msg.attachments) ...[
                      if (msg.isImage)
                        GestureDetector(
                          onTap: () => _showMediaPreview(attUrl, 'image'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              attUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 80,
                                color: Colors.black12,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (msg.isVideo)
                        GestureDetector(
                          onTap: () => _showMediaPreview(attUrl, 'video'),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded,
                                      color: Colors.white, size: 36),
                                  SizedBox(width: 8),
                                  Text(
                                    'Watch Video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showMediaPreview(attUrl, 'audio'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (isUser ? Colors.white : Colors.teal)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 20,
                                  color: isUser ? Colors.white : Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Voice Note (Tap to listen)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isUser ? Colors.white : Colors.teal.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                    ],
                  ],

                  // Text content
                  Text(
                    msg.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: isUser
                          ? Colors.white
                          : (isAdmin
                              ? Colors.teal.shade900
                              : context.scheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(msg.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.75)
                          : context.scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesRow(BuildContext context, List<String> snippets) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: snippets.map((snippet) {
                final isAgentTrigger = snippet.toLowerCase().contains('human') ||
                    snippet.toLowerCase().contains('agent');
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Icon(
                      isAgentTrigger
                          ? Icons.support_agent_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: isAgentTrigger
                          ? Colors.amber.shade900
                          : context.scheme.primary,
                    ),
                    label: Text(snippet),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          isAgentTrigger ? FontWeight.bold : FontWeight.w500,
                      color: isAgentTrigger
                          ? Colors.amber.shade900
                          : context.scheme.onSurface,
                    ),
                    backgroundColor: isAgentTrigger
                        ? Colors.amber.shade50
                        : context.scheme.surfaceContainerHighest
                            .withValues(alpha: 0.7),
                    side: BorderSide(
                      color: isAgentTrigger
                          ? Colors.amber.shade300
                          : context.scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    onPressed: () => _sendSnippet(snippet),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean, modern WhatsApp/Messenger style bottom input bar
  Widget _buildModernInputBar(BuildContext context, SupportState state) {
    final hasText = _controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment Button (+)
            IconButton(
              onPressed: _showAttachmentSheet,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: context.scheme.primary,
                size: 26,
              ),
              tooltip: 'Attach Image / Video / Voice',
              visualDensity: VisualDensity.compact,
            ),

            // Text Input Field Container
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: context.scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _isRecordingVoice
                              ? 'Listening... speak now'
                              : 'Ask Fixly AI or describe issue...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: _isRecordingVoice
                                ? Colors.red.shade700
                                : context.scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),

                    // Voice Note / Mic Button inside input
                    IconButton(
                      icon: Icon(
                        _isRecordingVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isRecordingVoice ? Colors.red : context.scheme.onSurfaceVariant,
                        size: 22,
                      ),
                      tooltip: _isRecordingVoice ? 'Stop recording' : 'Voice to text',
                      visualDensity: VisualDensity.compact,
                      onPressed: _toggleSpeechToText,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            CircleAvatar(
              radius: 21,
              backgroundColor: hasText
                  ? context.scheme.primary
                  : context.scheme.primary.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                tooltip: context.l10n.sendMessage,
                color: Colors.white,
                onPressed: hasText ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
