import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/apicall.dart';
import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/group_controller.dart';
import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/controller/review_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/validators.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/groups.dart';
import 'package:borrowcircle/pages/loans.dart';
import 'package:borrowcircle/pages/my_listings.dart';

// =====================================================================
//  PROFILE TAB
// =====================================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & campus guidelines'),
        content: const Text(
          '\u2022 Only verified university emails can join.\n'
          '\u2022 You can borrow an item for up to ${AppStatic.maxBorrowDays} days.\n'
          '\u2022 The borrower shows a 6-digit code, the owner enters it to start the loan.\n'
          '\u2022 The owner confirms the return, then both can leave a review.\n'
          '\u2022 Return items in the same condition.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final loans = context.watch<LoanController>();
    final items = context.watch<ItemController>();
    final reviews = context.watch<ReviewController>();
    final groups = context.watch<GroupController>();

    if (user == null) return const SizedBox.shrink();

    final myGroups = groups.managedBy(user.id).length;
    final rating = reviews.summary.total == 0 ? '\u2014' : '${reviews.summary.average.toStringAsFixed(1)} \u2605';

    return SafeArea(
      child: Column(
        children: [
          ScreenHeader(
            title: 'My profile',
            showBack: false,
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
              onSelected: (v) {
                if (v == 'edit') _open(context, const EditProfilePage());
                if (v == 'logout') AppSession.logout(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit profile')),
                PopupMenuItem(value: 'logout', child: Text('Log out')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(child: UserAvatar(name: user.fullName, avatar: user.avatar, radius: 64)),
                const SizedBox(height: 14),
                Center(
                  child: Text(user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ),
                const SizedBox(height: 8),
                const Center(child: PillTag(text: 'Verified student')),
                const SizedBox(height: 10),
                Center(
                  child: Text(AppStatic.universityOf(user.email),
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
                ),
                Center(child: Text(user.email, style: const TextStyle(color: AppColors.textGrey, fontSize: 16))),
                Center(
                  child: TextButton(
                    onPressed: () => _open(context, const EditProfilePage()),
                    child: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 6),

                // stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    children: [
                      _Stat(value: '${loans.completedCount}', label: 'Completed loans'),
                      _Stat(value: '${items.myTotal}', label: 'Items listed'),
                      _Stat(value: rating, label: 'Peer rating'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Your circle',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 12),
                _MenuCard(children: [
                  _MenuRow(
                    icon: Icons.groups_outlined,
                    title: 'My groups',
                    trailing: '$myGroups groups',
                    onTap: () => _open(context, const GroupsPage()),
                  ),
                  _MenuRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'My listings',
                    trailing: '${items.myTotal} items',
                    onTap: () => _open(context, const MyListingsPage()),
                  ),
                  _MenuRow(
                    icon: Icons.history,
                    title: 'Borrowing history',
                    trailing: '${loans.completedBorrowing.length} completed',
                    onTap: () => _open(context, const HistoryPage()),
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 16),
                _MenuCard(children: [
                  _MenuRow(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () => showSnack(context, 'No new notifications.'),
                  ),
                  _MenuRow(
                    icon: Icons.help_outline,
                    title: 'Help & campus guidelines',
                    onTap: () => _showHelp(context),
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => AppSession.logout(context),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

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

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final bool isLast;
  const _MenuRow({required this.icon, required this.title, this.trailing, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
            if (trailing != null) Text(trailing!, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  EDIT PROFILE
// =====================================================================
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _newAvatarPath;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<AuthController>().user?.fullName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) setState(() => _newAvatarPath = picked.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.updateProfile(_name.text, avatarPath: _newAvatarPath);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSnack(context, 'Profile updated');
    } else {
      showSnack(context, auth.error ?? 'Could not update profile', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Edit profile'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pick,
                        child: Stack(
                          children: [
                            UserAvatar(name: user?.fullName ?? '', avatar: user?.avatar, radius: 60),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _newAvatarPath == null ? 'Tap to change your photo' : 'New photo selected',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _name,
                        label: 'Full name',
                        hint: 'Your full name',
                        maxLength: 100,
                        validator: Validators.fullName,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Email: ${user?.email ?? ''} (cannot be changed)',
                            style: const TextStyle(color: AppColors.textGrey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(text: 'Save changes', isLoading: auth.isLoading, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  BORROWING HISTORY
// =====================================================================
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanController>();
    final me = context.watch<AuthController>().user?.id ?? 0;
    final list = loans.completedBorrowing;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Borrowing history'),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      title: 'Nothing here yet',
                      message: 'Items you borrowed and returned will show up here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => LoanCard(loan: list[i], myId: me),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
