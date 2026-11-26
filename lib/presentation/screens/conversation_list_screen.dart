import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/conversation_viewmodel.dart';
import '../widgets/app_widgets.dart';
import '../widgets/conversation_tile.dart';

/// The conversation list: the user's existing chats.
///
/// Tapping a conversation opens the chat page. New chats are started from a
/// loan or the Contact admin entry in the profile.
///
/// Observes [ConversationViewModel] and never calls the API directly.
class ConversationListPage extends StatefulWidget {
  /// Creates a [ConversationListPage] with an optional [key].
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final meId = auth.user?.id.toString() ?? '';
    final isAdmin = auth.user?.role == 'admin';
    if (!_loaded && meId.isNotEmpty) {
      _loaded = true;
      context.read<ConversationViewModel>().load(meId, role: auth.user!.role);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: ScreenHeader(title: isAdmin ? 'Support inbox' : 'Messages'),
      ),
      body: Consumer<ConversationViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null && vm.conversations.isEmpty) {
            return ErrorState(message: vm.error!, onRetry: () => vm.refresh());
          }
          if (vm.conversations.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              title: isAdmin
                  ? 'No support messages yet'
                  : 'No conversations yet',
              message: isAdmin
                  ? 'Messages from users will appear here.'
                  : 'Message a lender or borrower from a loan, or contact '
                        'an admin from your profile.',
            );
          }
          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          );
        },
      ),
    );
  }
}
