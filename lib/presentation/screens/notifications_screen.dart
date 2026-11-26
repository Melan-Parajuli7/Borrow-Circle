import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../widgets/app_widgets.dart';
import '../viewmodels/account_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';

/// Shows the user's in-app notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountViewModel>();
    final notifications = context.watch<NotificationViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Notifications',
              trailing: notifications.notifications.isEmpty
                  ? null
                  : TextButton(
                      onPressed: notifications.markAllRead,
                      child: const Text('Mark all read'),
                    ),
            ),
            Expanded(
              child: !account.notificationsEnabled
                  ? const EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'Notifications are paused',
                      message: 'Enable notifications in Account settings to receive updates.',
                    )
                  : notifications.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No new notifications',
                      message: 'Requests, approvals, handovers, and returns will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: notifications.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = notifications.notifications[index];
                        return InkWell(
                          onTap: () => notifications.markRead(notification.id),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: notification.isRead
                                  ? Colors.white
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    notification.isRead
                                        ? Icons.notifications_none
                                        : Icons.notifications_active_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(notification.message),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
