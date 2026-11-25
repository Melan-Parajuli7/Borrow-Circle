import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../viewmodels/app_session.dart';
import '../../core/constants/colors.dart';
import '../utils/format.dart';
import '../../core/constants/app_static.dart';
import '../utils/validators.dart';
import '../widgets/app_widgets.dart';
import '../../data/models/user_model.dart';
import '../viewmodels/account_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/fingerprint_viewmodel.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/item_viewmodel.dart';
import '../viewmodels/loan_viewmodel.dart';
import '../viewmodels/password_viewmodel.dart';
import '../viewmodels/review_viewmodel.dart';
import './calendar_screen.dart';
import './profile_screen.dart';
import './groups_screen.dart';
import './my_listings_screen.dart';
import './loans_screen.dart';
import './notifications_screen.dart';

// =====================================================================
//  ACCOUNT SETTINGS SCREEN
// =====================================================================

/// Account settings: profile, security (password, fingerprint), preferences,
/// and logout.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  static Future<void> _editHandoverSpot(
    BuildContext context,
    AccountViewModel account,
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
    AccountViewModel account,
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
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final account = context.watch<AccountViewModel>();
    final fingerprint = context.watch<FingerprintViewModel>();
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
                            builder: (_) => const EditProfileScreen(),
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
                            builder: (_) => const ChangePasswordScreen(),
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
                                  final enabled =
                                      await fingerprint.setEnabled(value);
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
                        onTap: () => AccountSettingsScreen._editHandoverSpot(context, account),
                      ),
                      _SettingsRow(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle:
                            '${account.themeMode[0].toUpperCase()}${account.themeMode.substring(1)} theme',
                        onTap: () => AccountSettingsScreen._chooseTheme(context, account),
                      ),
                      _SettingsRow(
                        icon: Icons.image_outlined,
                        title: 'Storage & cache',
                        subtitle: 'Clear temporary item and profile images',
                        onTap: () {
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

/// Form for changing the account password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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

    final email = context.read<AuthViewModel>().user?.email ?? '';
    final password = context.read<PasswordViewModel>();
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
    final password = context.watch<PasswordViewModel>();

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
