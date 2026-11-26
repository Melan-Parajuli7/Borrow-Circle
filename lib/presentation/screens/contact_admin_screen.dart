import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../data/services/chat_service.dart';
import '../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/conversation_viewmodel.dart';
import '../widgets/app_widgets.dart';
import '../widgets/chat_input_field.dart';

/// Support entry page that opens an in-app conversation with an admin.
class ContactAdminScreen extends StatefulWidget {
  const ContactAdminScreen({super.key});

  @override
  State<ContactAdminScreen> createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> {
  bool _isSending = false;
  String? _error;

  Future<bool> _sendMessage(String text) async {
    if (_isSending) return false;
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final user = context.read<AuthViewModel>().user;
      if (user == null) {
        setState(() => _error = 'Sign in to contact the admin.');
        return false;
      }

      final conversations = context.read<ConversationViewModel>();
      final conversation = await conversations.startAdminConversation(
        currentUserId: user.id.toString(),
        userName: user.fullName,
      );
      if (!mounted) return false;

      if (conversation == null) {
        setState(() {
          _error = conversations.error ?? 'Could not open admin support.';
        });
        return false;
      }

      await context.read<ChatService>().sendMessage(
        conversationId: conversation.id,
        currentUserId: user.id.toString(),
        senderName: user.fullName,
        text: text,
      );
      if (!mounted) return false;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.chat,
        arguments: conversation,
      );
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
      return false;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(68),
        child: ScreenHeader(title: 'Contact admin'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.support_agent_outlined,
                        size: 72,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Message the admin team',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ask about a handover code, your account, or anything else you need help with. Messages are stored on this device only and are not delivered to an admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ChatInputField(onSend: _sendMessage),
          ],
        ),
      ),
    );
  }
}
