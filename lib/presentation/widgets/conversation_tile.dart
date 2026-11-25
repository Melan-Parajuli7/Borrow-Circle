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
        conversation.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.hasMessages ? AppColors.textGrey : AppColors.primaryLightActive,
          fontSize: 14,
        ),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
      ),
      onTap: onTap,
    );
  }
}
