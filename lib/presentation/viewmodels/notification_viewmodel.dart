import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for notification management.
///
/// Holds the list of in-app notifications and delegates persistence to
/// [NotificationRepository].
class NotificationViewModel extends BaseViewModel {
  /// Creates a [NotificationViewModel] backed by [repository].
  NotificationViewModel(this._repository);

  /// Repository used to load and save notifications.
  final NotificationRepository _repository;

  final List<NotificationModel> _notifications = [];
  /// All notifications for the current user.
  List<NotificationModel> get notifications => _notifications;

  /// Number of unread notifications.
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  /// Loads all notifications.
  Future<void> load() async {
    await runWithLoading(() async {
      _notifications
        ..clear()
        ..addAll(await _repository.load());
    });
  }

  /// Marks all notifications as read.
  Future<void> markAllRead() async {
    _notifications
      ..clear()
      ..addAll(_notifications.map((n) => n.copyWith(isRead: true)));
    notifyListeners();
    await _repository.save(_notifications);
  }

  /// Marks a specific notification as read.
  Future<void> markRead(String id) async {
    _notifications
      ..clear()
      ..addAll(_notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n));
    notifyListeners();
    await _repository.save(_notifications);
  }

  /// Clears all notifications.
  Future<void> clear() async {
    _notifications.clear();
    notifyListeners();
    await _repository.save(_notifications);
  }

  /// Merges [generated] notifications into the current list.
  ///
  /// Notifications are de-duplicated by [NotificationModel.id], so calling this
  /// repeatedly never creates duplicates. Read state of existing notifications
  /// is preserved because already-known ids are skipped.
  Future<void> mergeGenerated(List<NotificationModel> generated) async {
    if (generated.isEmpty) return;
    final known = {for (final n in _notifications) n.id};
    var changed = false;
    for (final n in generated) {
      if (known.add(n.id)) {
        _notifications.add(n);
        changed = true;
      }
    }
    if (!changed) return;
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    await _repository.save(_notifications);
  }
}
