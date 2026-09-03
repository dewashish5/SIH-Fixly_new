import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/theme_x.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/support_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    context.read<SupportCubit>().sendMessage(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return BlocBuilder<SupportCubit, SupportState>(
      builder: (context, state) {
        return AppScaffold(
          title: context.l10n.supportChat,
          showBack: true,
          body: Column(
            children: [
              Expanded(
                child: state.status == SupportStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          return Align(
                            alignment: msg.isAgent
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: msg.isAgent
                                    ? context.scheme.surfaceContainerHighest
                                    : context.scheme.primary.withValues(
                                        alpha: context.isDark ? 0.28 : 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg.text),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeFormat.format(msg.time),
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Type a message...',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: context.l10n.sendMessage,
                    color: context.scheme.primary,
                    onPressed: _send,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
