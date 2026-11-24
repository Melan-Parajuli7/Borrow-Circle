import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/chat_conversation.dart';
import '../../widgets/app_widgets.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../chat/chat_screen.dart';

/// List of the current user's chat conversations.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Future<void> _refresh() async {
    await context.read<ChatViewModel>().loadConversations(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = context.watch<ChatViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final me = authViewModel.user?.id ?? 0;

    return SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Messages', showBack: false),
          Expanded(
            child: chatViewModel.isLoading && chatViewModel.conversations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatViewModel.error != null &&
                      chatViewModel.conversations.isEmpty
                    ? ErrorState(message: chatViewModel.error!, onRetry: _refresh)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            if (chatViewModel.conversations.isEmpty)
                              const EmptyState(
                                icon: Icons.chat_bubble_outline,
                                title: 'No conversations yet',
                                message:
                                    'Start a conversation from a loan or item listing.',
                              ),
                            for (final c in chatViewModel.conversations)
                              ...[
                                _ConversationTile(
                                  conversation: c,
                                  myId: me,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: c.id,
                                        participantId: c.participantId,
                                        participantName: c.participantName,
                                        participantAvatar: c.participantAvatar,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// One conversation row in the list.
class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final int myId;
  final VoidCallback onTap;
  const _ConversationTile({
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final other = conversation.participantName;
    final unread = conversation.hasUnread;
    final time = conversation.lastMessageAt != null
        ? _shortTime(conversation.lastMessageAt!)
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: unread ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: other,
              avatar: conversation.participantAvatar,
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (time != null)
                        Text(
                          time,
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (conversation.itemTitle != null)
                        PillTag(
                          text: conversation.itemTitle!,
                          icon: Icons.shopping_bag_outlined,
                          bg: AppColors.secondaryLight,
                          fg: AppColors.secondary,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread
                                ? AppColors.textDark
                                : AppColors.textGrey,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.done_all,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (msgDay == today) return '$h:$m';
    final diff = today.difference(msgDay).inDays;
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}
