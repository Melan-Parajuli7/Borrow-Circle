import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/conversation_viewmodel.dart';
import '../widgets/app_widgets.dart';
import '../widgets/conversation_tile.dart';

/// The conversation list: the user's existing chats and a way to start one.
///
/// Reached from the dashboard. Tapping a conversation opens the chat page;
/// the floating action button starts a new conversation with another user.
///
/// Observes [ConversationViewModel] and never calls Firestore directly.
class ConversationListPage extends StatefulWidget {
  /// Creates a [ConversationListPage] with an optional [key].
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  bool _loaded = false;

  /// Starts (or opens) a conversation with [otherUid] and navigates to it.
  Future<void> _startConversation(String otherUid) async {
    otherUid = otherUid.trim();
    if (otherUid.isEmpty) return;
    final vm = context.read<ConversationViewModel>();
    final me = context.read<AuthViewModel>().user?.id.toString() ?? '';
    if (vm.currentUid == null) {
      await vm.load(me, context.read<AuthViewModel>().user?.fullName ?? '');
    }
    final conv = await vm.startConversation(otherUid);
    if (!mounted || conv == null) return;
    Navigator.pushNamed(context, AppRoutes.chat, arguments: conv);
  }

  /// Shows a dialog asking for the other user's ID, then starts the chat.
  Future<void> _showStartConversationDialog() async {
    final controller = TextEditingController();
    final otherUid = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Start conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Other user's ID",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(dialog, text);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (!mounted || otherUid == null || otherUid.isEmpty) return;
    await _startConversation(otherUid);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final meId = auth.user?.id.toString() ?? '';
    final meName = auth.user?.fullName ?? '';

    if (!_loaded && meId.isNotEmpty) {
      _loaded = true;
      context.read<ConversationViewModel>().load(meId, meName);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: const ScreenHeader(title: 'Messages'),
      ),
      body: Consumer<ConversationViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null && vm.conversations.isEmpty) {
            return ErrorState(
              message: vm.error!,
              onRetry: () => vm.load(meId, meName),
            );
          }
          if (vm.conversations.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              message: 'Start a conversation from the list above, or message '
                  'someone from their loans.',
            );
          }
          return ListView.builder(
            itemCount: vm.conversations.length,
            itemBuilder: (context, i) => ConversationTile(
              conversation: vm.conversations[i],
              currentUid: meId,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: vm.conversations[i],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Start conversation',
        onPressed: _showStartConversationDialog,
        child: const Icon(Icons.message),
      ),
    );
  }
}
