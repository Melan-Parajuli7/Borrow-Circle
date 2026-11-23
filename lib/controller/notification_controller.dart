import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/notification_model.dart';
import 'package:borrowcircle/services/notification_service.dart';

/// Frontend notification feature state, separate from account settings.
class NotificationController extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> notifications = [];
  bool isLoading = false;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    notifications = await _service.load();
    isLoading = false;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    notifications = notifications
        .map(
          (notification) => NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            isRead: true,
            createdAt: notification.createdAt,
          ),
        )
        .toList();
    notifyListeners();
    await _service.save(notifications);
  }

  Future<void> markRead(String id) async {
    notifications = notifications
        .map(
          (notification) => notification.id == id
              ? NotificationModel(
                  id: notification.id,
                  title: notification.title,
                  message: notification.message,
                  isRead: true,
                  createdAt: notification.createdAt,
                )
              : notification,
        )
        .toList();
    notifyListeners();
    await _service.save(notifications);
  }

  Future<void> clear() async {
    notifications = [];
    notifyListeners();
    await _service.save(notifications);
  }
}
