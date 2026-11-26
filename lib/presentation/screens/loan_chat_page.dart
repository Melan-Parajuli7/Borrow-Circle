import 'package:flutter/material.dart';

import '../../data/models/conversation_model.dart';
import '../../data/models/loan_model.dart';
import './chat_page.dart';

/// Loan-specific chat page for coordinating handover and verification details.
class LoanChatPage extends StatelessWidget {
  const LoanChatPage({
    super.key,
    required this.conversation,
    required this.loan,
  });

  final ConversationModel conversation;
  final LoanModel loan;

  @override
  Widget build(BuildContext context) {
    return ChatPage(
      conversation: conversation,
      contextNote:
          'Loan conversation for ${loan.itemTitle}. Use this local preview to coordinate handover and verification details.',
    );
  }
}
