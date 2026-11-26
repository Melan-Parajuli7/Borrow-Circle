import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../data/models/conversation_model.dart';
import 'app_widgets.dart';

/// One row in the conversation list: partner, last message preview, time.
///
/// Tapping opens the chat page for this conversation.
class ConversationTile extends StatelessWidget {
  /// Creates a [ConversationTile] for [conversation].
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUid,
    required this.onTap,
  });

  /// The conversation to show.
  final ConversationModel conversation;

  /// Stringified ID of the current user (used to find the partner).
  final String currentUid;

  /// Callback fired when the tile is tapped.
  final VoidCallback onTap;

  /// "hh:mm" for today, otherwise "d/M".
  static String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final name = conversation.otherParticipantName(currentUid);
    final time = _formatTime(conversation.lastMessageAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: UserAvatar(name: name),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage ?? conversation.itemTitle ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.hasMessages
              ? AppColors.textGrey
              : AppColors.primaryLightActive,
          fontSize: 14,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
