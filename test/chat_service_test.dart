import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:borrowcircle/data/services/chat_service.dart';

void main() {
  late ChatService chatService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    chatService = ChatService(await SharedPreferences.getInstance());
  });

  test(
    'admin support messages persist and can be replied to locally',
    () async {
      final conversation = await chatService.startAdminConversation(
        currentUserId: '5',
        userName: 'Alex User',
      );
      await chatService.sendMessage(
        conversationId: conversation.id,
        currentUserId: '5',
        senderName: 'Alex User',
        text: 'I need help with my handover.',
      );

      final adminInbox = await chatService.conversations(
        currentUserId: '1',
        role: 'admin',
      );
      expect(adminInbox, hasLength(1));
      expect(adminInbox.single.participantName, 'Alex User');
      await chatService.markRead(
        conversationId: conversation.id,
        currentUserId: '1',
        role: 'admin',
      );

      await chatService.sendMessage(
        conversationId: conversation.id,
        currentUserId: '1',
        senderName: 'Admin',
        text: 'How can I help?',
        role: 'admin',
      );
      final userInbox = await chatService.conversations(currentUserId: '5');
      expect(userInbox.single.unreadCount, 1);

      final messages = await chatService.messages(
        conversationId: conversation.id,
        currentUserId: '5',
      );
      expect(messages.map((message) => message.text), [
        'I need help with my handover.',
        'How can I help?',
      ]);

      await chatService.markRead(
        conversationId: conversation.id,
        currentUserId: '5',
      );
      final refreshedAdminInbox = await chatService.conversations(
        currentUserId: '1',
        role: 'admin',
      );
      expect(refreshedAdminInbox.single.unreadCount, 0);
    },
  );

  test(
    'loan chat is shared by participants and blocked for outsiders',
    () async {
      final conversation = await chatService.startLoanConversation(
        loanId: 20,
        currentUserId: '5',
        userName: 'Borrower',
        otherUserId: 8,
        otherUserName: 'Owner',
        itemId: 14,
        itemTitle: 'Camera',
      );
      await chatService.sendMessage(
        conversationId: conversation.id,
        currentUserId: '5',
        senderName: 'Borrower',
        text: 'Can we meet at noon?',
      );

      final ownerInbox = await chatService.conversations(currentUserId: '8');
      expect(ownerInbox.single.participantName, 'Borrower');
      expect(ownerInbox.single.itemTitle, 'Camera');
      expect(
        (await chatService.messages(
          conversationId: conversation.id,
          currentUserId: '8',
        )).single.text,
        'Can we meet at noon?',
      );

      expect(
        chatService.messages(
          conversationId: conversation.id,
          currentUserId: '3',
        ),
        throwsStateError,
      );
    },
  );
}
