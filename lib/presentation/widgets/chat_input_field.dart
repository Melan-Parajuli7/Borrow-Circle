import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// Message input field with a send button.
///
/// Calls [onSend] with the trimmed, non-empty text when the user sends.
/// Keeps the text in the field if the send request fails.
class ChatInputField extends StatefulWidget {
  /// Creates a [ChatInputField] that notifies [onSend] of sent messages.
  const ChatInputField({super.key, required this.onSend});

  /// Fired with the message text the user just sent.
  final Future<bool> Function(String) onSend;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await widget.onSend(text);
      if (sent && mounted) _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_sending,
                maxLength: 5000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppColors.primary),
              onPressed: _sending ? null : _send,
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
