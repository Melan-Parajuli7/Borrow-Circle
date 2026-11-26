import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/conversation_model.dart';
import '../../data/services/chat_service.dart';
import '../../core/constants/colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/app_widgets.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';

/// The chat page for one conversation: message list + input field.
///
/// The route argument is the [ConversationModel]. The page scopes a
/// [ChatViewModel] to this conversation and never calls the API directly.
class ChatPage extends StatefulWidget {
  /// Creates a [ChatPage] with an optional [key].
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    final conversation =
        ModalRoute.of(context)!.settings.arguments as ConversationModel;
    final auth = context.read<AuthViewModel>();
    final currentUid = auth.user?.id.toString() ?? '';
    final partnerName = conversation.otherParticipantName(currentUid);

    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(
        chatService: context.read<ChatService>(),
        conversationId: conversation.id,
        currentUid: currentUid,
        otherUid: conversation.otherParticipantId(currentUid),
        otherName: conversation.otherParticipantName(currentUid),
      ),
      child: _ChatPageBody(conversation: conversation, partner: partnerName),
    );
  }
}

class _ChatPageBody extends StatefulWidget {
  /// Creates a [_ChatPageBody] showing [conversation] with [partner] name.
  const _ChatPageBody({required this.conversation, required this.partner});

  final ConversationModel conversation;
  final String partner;

  @override
  State<_ChatPageBody> createState() => _ChatPageBodyState();
}

class _ChatPageBodyState extends State<_ChatPageBody> {
  final _scroll = ScrollController();
  var _renderedMessageCount = -1;

  @override
  void initState() {
    super.initState();
    context.read<ChatViewModel>().load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final meId = context.read<AuthViewModel>().user?.id.toString() ?? '';

    if (_renderedMessageCount != vm.messages.length && vm.messages.isNotEmpty) {
      _renderedMessageCount = vm.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: ScreenHeader(title: widget.partner),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading && vm.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    reverse: false,
                    itemCount: vm.messages.length,
                    itemBuilder: (context, i) => MessageBubble(
                      message: vm.messages[i],
                      isMine: vm.messages[i].isSentBy(meId),
                    ),
                  ),
          ),
          if (vm.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                vm.error!,
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ChatInputField(onSend: context.read<ChatViewModel>().sendMessage),
        ],
      ),
    );
  }
}
