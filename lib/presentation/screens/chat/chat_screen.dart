import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/chat_message.dart';
import '../../widgets/app_widgets.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';

/// A single conversation: message list + input.
class ChatScreen extends StatefulWidget {
  /// ID of the conversation to open.
  final int conversationId;

  /// Other participant's ID.
  final int participantId;

  /// Other participant's display name.
  final String participantName;

  /// Other participant's avatar file name, if any.
  final String? participantAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatViewModel>().loadMessages(widget.conversationId);
      if (!mounted) return;
      _scrollToBottom();
      await context.read<ChatViewModel>().markRead(widget.conversationId);
    });
    _text.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty) return;
    setState(() => _sending = true);
    _text.clear();
    final vm = context.read<ChatViewModel>();
    await vm.sendMessage(widget.conversationId, message);
    if (!mounted) return;
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool get _canSend => _text.text.trim().isNotEmpty && !_sending;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final me = authViewModel.user?.id ?? 0;
    final chatViewModel = context.watch<ChatViewModel>();
    final messages = chatViewModel.messages;

    return SafeArea(
      child: Column(
        children: [
          ScreenHeader(
            title: widget.participantName,
          ),
          Expanded(
            child: chatViewModel.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatViewModel.error != null && messages.isEmpty
                    ? ErrorState(
                        message: chatViewModel.error!,
                        onRetry: () => context
                            .read<ChatViewModel>()
                            .loadMessages(widget.conversationId),
                      )
                    : messages.isEmpty
                        ? const EmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: 'No messages yet',
                            message: 'Say hello to start the conversation.',
                          )
                        : ListView.builder(
                            controller: _scroll,
                            reverse: false,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final message = messages[i];
                              final isMine = message.senderId == me;
                              final showTime = i == 0 ||
                                  messages[i - 1].createdAt
                                          .difference(message.createdAt)
                                          .inSeconds
                                          .abs() >=
                                      300 ||
                                  messages[i - 1].senderId != message.senderId;
                              return _MessageBubble(
                                message: message,
                                isMine: isMine,
                                showTime: showTime,
                              );
                            },
                          ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !_sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _canSend ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _canSend ? _send : null,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One message bubble.
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showTime;
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showTime,
  });

  @override
  Widget build(BuildContext context) {
    final time = _shortTime(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            const SizedBox(width: 8),
            UserAvatar(
              name: message.senderName,
              radius: 20,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.primary : AppColors.primaryLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMine
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: isMine
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMine ? Colors.white : AppColors.textDark,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      if (showTime) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.textGrey,
                                fontSize: 11,
                              ),
                            ),
                            if (isMine && !message.isRead)
                              const Icon(
                                Icons.done,
                                size: 12,
                                color: Colors.white70,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            UserAvatar(
              name: message.senderName,
              radius: 20,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
