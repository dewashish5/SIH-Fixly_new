import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerAiHelperPage extends StatefulWidget {
  const CustomerAiHelperPage({super.key});

  @override
  State<CustomerAiHelperPage> createState() => _CustomerAiHelperPageState();
}

class _CustomerAiHelperPageState extends State<CustomerAiHelperPage> {
  final _queryController = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      isBot: true,
      text:
          'Hi! I\'m your AI helper. Describe your home service need and I\'ll find the best match.',
    ),
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _queryController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isBot: false, text: text));
      _messages.add(const _ChatMessage(
        isBot: true,
        text:
            'Based on your description, I recommend an electrician for switch/socket repair. Let me find workers for you.',
      ));
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.aiHelper,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isBot
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isBot
                          ? AppColors.surfaceContainer
                          : AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg.text),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1);
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your problem...',
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Discover Services',
            onPressed: () => context.push(RouteNames.customerAiDiscovery),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.isBot, required this.text});

  final bool isBot;
  final String text;
}
