import 'format.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/request_model.dart';

/// Builds local, on-device notifications from the user's borrow requests and
/// active loans.
///
/// The generated notifications cover:
/// - Incoming requests (someone wants to borrow one of your items).
/// - Status of the requests you sent (pending / approved / declined).
/// - Loans whose end date is near (within [dueSoonDays]) or already overdue.
///
/// Each notification has a stable [NotificationModel.id] so the
/// [NotificationViewModel] can merge them without creating duplicates and
/// without resetting the read state of existing ones.
class NotificationGenerator {
  NotificationGenerator._();

  /// How many days before the end date a "due soon" notification is raised.
  static const int dueSoonDays = 3;

  /// Generates the current set of notifications from the given data.
  static List<NotificationModel> generate({
    required List<RequestModel> sent,
    required List<RequestModel> received,
    required List<LoanModel> activeBorrowing,
    required List<LoanModel> activeLending,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <NotificationModel>[];

    // Incoming requests: someone wants to borrow one of your items.
    for (final r in received) {
      final when = r.createdAt ?? now;
      if (r.isPending) {
        result.add(NotificationModel(
          id: 'req_in_${r.id}_pending',
          title: 'Borrow request',
          message: '${r.requesterName} wants to borrow "${r.itemTitle}".',
          isRead: false,
          createdAt: when,
        ));
      } else if (r.isApproved) {
        result.add(NotificationModel(
          id: 'req_in_${r.id}_approved',
          title: 'Request accepted',
          message: "You approved ${r.requesterName}'s request for \"${r.itemTitle}\".",
          isRead: false,
          createdAt: when,
        ));
      }
    }

    // Requests you sent.
    for (final r in sent) {
      final when = r.createdAt ?? now;
      switch (r.status) {
        case 'pending':
          result.add(NotificationModel(
            id: 'req_out_${r.id}_pending',
            title: 'Request sent',
            message: 'Your request for "${r.itemTitle}" is awaiting approval.',
            isRead: false,
            createdAt: when,
          ));
        case 'approved':
          result.add(NotificationModel(
            id: 'req_out_${r.id}_approved',
            title: 'Request approved',
            message: 'Your request for "${r.itemTitle}" was approved.',
            isRead: false,
            createdAt: when,
          ));
        case 'rejected':
          result.add(NotificationModel(
            id: 'req_out_${r.id}_rejected',
            title: 'Request declined',
            message: 'Your request for "${r.itemTitle}" was declined.',
            isRead: false,
            createdAt: when,
          ));
      }
    }

    // Near / overdue due dates on active loans.
    for (final l in [...activeBorrowing, ...activeLending]) {
      final due = Fmt.parseDay(l.endDate);
      if (due == null) continue;
      final days = due.difference(today).inDays;
      if (days < 0) {
        result.add(NotificationModel(
          id: 'loan_${l.id}_overdue',
          title: 'Overdue',
          message: '"${l.itemTitle}" was due on ${Fmt.day(l.endDate)}.',
          isRead: false,
          createdAt: now,
        ));
      } else if (days <= dueSoonDays) {
        final whenText = days == 0 ? 'today' : 'in ${Fmt.daysText(days)}';
        result.add(NotificationModel(
          id: 'loan_${l.id}_due_${l.endDate}',
          title: 'Due soon',
          message: '"${l.itemTitle}" is due $whenText (${Fmt.day(l.endDate)}).',
          isRead: false,
          createdAt: now,
        ));
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Generates notifications for unread chat messages sent by others.
  ///
  /// Only messages whose sender is not [myId] and that are not yet read are
  /// included, so the user gets one notification per new incoming message.
  static List<NotificationModel> chatMessages({
    required List<ChatMessage> messages,
    required int myId,
  }) {
    final result = <NotificationModel>[];
    for (final m in messages) {
      if (m.senderId == myId || m.isRead) continue;
      result.add(NotificationModel(
        id: 'chat_${m.id}',
        title: 'New message from ${m.senderName}',
        message: m.text,
        isRead: false,
        createdAt: m.createdAt,
      ));
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}