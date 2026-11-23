import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/account_controller.dart';
import 'package:borrowcircle/controller/apicall.dart';
import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/fingerprint_controller.dart';
import 'package:borrowcircle/controller/notification_controller.dart';
import 'package:borrowcircle/controller/password_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/validators.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/profile.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  static Future<void> _editHandoverSpot(
    BuildContext context,
    AccountController account,
  ) async {
    final controller = TextEditingController(text: account.handoverSpot);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Default handover spot'),
        content: AppTextField(
          controller: controller,
          label: 'Campus location',
          hint: 'e.g. Central Library North Desk',
          maxLength: 120,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await account.setHandoverSpot(result);
  }

  static Future<void> _chooseTheme(
    BuildContext context,
    AccountController account,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['system', 'light', 'dark'].map((value) {
            final label = '${value[0].toUpperCase()}${value.substring(1)}';
            return ListTile(
              leading: Icon(
                value == 'system'
                    ? Icons.phone_android
                    : value == 'light'
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              title: Text(label),
              trailing: account.themeMode == value
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, value),
            );
          }).toList(),
        ),
      ),
    );
    if (result != null) await account.setThemeMode(result);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final account = context.watch<AccountController>();
    final fingerprint = context.watch<FingerprintController>();
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Account settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: UserAvatar(
                      name: user?.fullName ?? '',
                      avatar: user?.avatar,
                      radius: 52,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      user?.fullName ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.person_outline,
                        title: 'Edit profile',
                        subtitle: 'Update your name and profile photo',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Receive in-app account notifications',
                        trailing: Switch.adaptive(
                          value: account.notificationsEnabled,
                          onChanged: account.setNotificationsEnabled,
                        ),
                        showChevron: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.lock_outline,
                        title: 'Change password',
                        subtitle: 'Update your account password',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        ),
                        showChevron: true,
                      ),
                      _SettingsRow(
                        icon: Icons.fingerprint,
                        title: 'Fingerprint login',
                        subtitle: fingerprint.available
                            ? 'Unlock BorrowCircle with biometrics'
                            : 'Fingerprint is unavailable on this device',
                        trailing: Switch.adaptive(
                          value: fingerprint.enabled,
                          onChanged: fingerprint.available
                              ? (value) async {
                                  final enabled = await fingerprint.setEnabled(
                                    value,
                                  );
                                  if (!enabled && context.mounted) {
                                    showSnack(
                                      context,
                                      fingerprint.error ??
                                          'Fingerprint setup failed',
                                      isError: true,
                                    );
                                  }
                                }
                              : null,
                        ),
                        showChevron: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.place_outlined,
                        title: 'Default handover spot',
                        subtitle: account.handoverSpot.isEmpty
                            ? 'Not set'
                            : account.handoverSpot,
                        onTap: () => _editHandoverSpot(context, account),
                      ),
                      _SettingsRow(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle:
                            '${account.themeMode[0].toUpperCase()}${account.themeMode.substring(1)} theme',
                        onTap: () => _chooseTheme(context, account),
                      ),
                      _SettingsRow(
                        icon: Icons.image_outlined,
                        title: 'Storage & cache',
                        subtitle: 'Clear temporary item and profile images',
                        onTap: () {
                          PaintingBinding.instance.imageCache.clear();
                          PaintingBinding.instance.imageCache.clearLiveImages();
                          showSnack(context, 'Image cache cleared');
                        },
                        isLast: false,
                      ),
                      _SettingsRow(
                        icon: Icons.visibility_off_outlined,
                        title: 'Privacy',
                        subtitle: account.hideContactInfo
                            ? 'Contact hidden from non-circle members'
                            : 'Contact visible to verified students',
                        trailing: Switch.adaptive(
                          value: account.hideContactInfo,
                          onChanged: account.setHideContactInfo,
                        ),
                        showChevron: false,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () => AppSession.logout(context),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final email = context.read<AuthController>().user?.email ?? '';
    final password = context.read<PasswordController>();
    final ok = await password.changePassword(
      email: email,
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSnack(context, 'Password changed successfully');
    } else {
      showSnack(
        context,
        password.error ?? 'Could not change password',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = context.watch<PasswordController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Change password'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_reset_outlined,
                        size: 72,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Create a strong new password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use at least 8 characters.',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _currentPassword,
                        label: 'Current password',
                        hint: 'Enter current password',
                        isPassword: true,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _newPassword,
                        label: 'New password',
                        hint: 'Enter new password',
                        isPassword: true,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPassword,
                        label: 'Confirm new password',
                        hint: 'Re-enter new password',
                        isPassword: true,
                        validator: Validators.confirmPassword(
                          () => _newPassword.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                text: 'Change password',
                icon: Icons.lock_outline,
                isLoading: password.isLoading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountController>();
    final notifications = context.watch<NotificationController>();

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
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = notifications.notifications[index];
                        return InkWell(
                          onTap: () => notifications.markRead(notification.id),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notification.isRead
                                  ? Colors.white
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && showChevron)
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
