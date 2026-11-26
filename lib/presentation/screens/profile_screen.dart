import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/group_viewmodel.dart';
import '../viewmodels/item_viewmodel.dart';
import '../viewmodels/loan_viewmodel.dart';
import '../viewmodels/review_viewmodel.dart';
import '../routes/app_routes.dart';
import './account_screen.dart';
import './calendar_screen.dart';
import './contact_admin_screen.dart';
import './groups_screen.dart';
import './my_listings_screen.dart';
import './loans_screen.dart';

// =====================================================================
//  PROFILE SCREEN
// =====================================================================

/// Profile tab: shows the user's stats, trust tier, and a menu of
/// account-related destinations.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _showQrPass(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My QR pass'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: 'BORROWCIRCLE:USER:${user.id}:${user.fullName}',
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & campus guidelines'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _GuidelineTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verified campus community',
                  text: 'Use a verified university email to join and lend responsibly.',
                ),
                _GuidelineTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Borrowing window',
                  text:
                      'You can borrow an item for up to ${AppStatic.maxBorrowDays} days.',
                ),
                _GuidelineTile(
                  icon: Icons.qr_code_2,
                  title: 'Secure handover',
                  text: 'The borrower shows the 6-digit code or QR; the owner confirms it.',
                ),
                _GuidelineTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Return and review',
                  text: 'The owner confirms the return, then both members can leave a review.',
                ),
                _GuidelineTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Care for shared items',
                  text: 'Return equipment clean, complete, and in the same condition.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final loans = context.watch<LoanViewModel>();
    final items = context.watch<ItemViewModel>();
    final reviews = context.watch<ReviewViewModel>();
    final groups = context.watch<GroupViewModel>();

    if (user == null) return const SizedBox.shrink();

    final myGroups = groups.managedBy(user.id).length;
    final rating = reviews.summary.total == 0
        ? '\u2014'
        : '${reviews.summary.average.toStringAsFixed(1)} \u2605';
    final completedCount = loans.completedCount;
    final trustTier = completedCount >= 20
        ? 'Tier 3 Trusted Campus Lender'
        : completedCount >= 5
        ? 'Tier 2 Campus Lender'
        : 'Tier 1 Campus Member';
    final recentLoans = [...loans.activeBorrowing, ...loans.completedBorrowing]
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    return SafeArea(
      child: Column(
        children: [
          ScreenHeader(
            title: 'My profile',
            showBack: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.primary),
                  onSelected: (v) {
                    if (v == 'edit') _open(context, const EditProfileScreen());
                    if (v == 'logout') AppSession.logout(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit profile')),
                    PopupMenuItem(value: 'logout', child: Text('Log out')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                  child: UserAvatar(
                    name: user.fullName,
                    avatar: user.avatar,
                    radius: 64,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: PillTag(text: 'Verified student')),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    AppStatic.universityOf(user.email),
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => _open(context, const EditProfileScreen()),
                    child: const Text('Edit profile'),
                  ),
                ),
                const SizedBox(height: 6),

                // stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      _Stat(
                        value: '${items.myTotal}',
                        label: 'Listings',
                        color: AppColors.textDark,
                      ),
                      Container(width: 1, height: 48, color: AppColors.border),
                      _Stat(
                        value: '${loans.completedCount}',
                        label: 'Loans',
                        color: AppColors.secondary,
                      ),
                      Container(width: 1, height: 48, color: AppColors.border),
                      _Stat(
                        value: '${reviews.summary.total}',
                        label: 'Reviews',
                        color: AppColors.tertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 38,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trustTier,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$completedCount verified loans · $rating',
                              style: const TextStyle(color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _ImpactStat(
                          icon: Icons.eco_outlined,
                          value: '0.0 kg',
                          label: 'CO2 estimated saved',
                        ),
                      ),
                      Container(height: 64, width: 1, color: AppColors.border),
                      Expanded(
                        child: _ImpactStat(
                          icon: Icons.savings_outlined,
                          value: '${completedCount * 250} NPR',
                          label: 'Estimated saved',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (recentLoans.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent activity',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${recentLoans.first.itemTitle} · ${recentLoans.first.isReturned ? 'Returned' : 'Borrowed'}',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                const Text(
                  'Your circle',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  children: [
                    _MenuRow(
                      icon: Icons.groups_outlined,
                      title: 'My groups',
                      trailing: '$myGroups groups',
                      onTap: () => _open(context, const GroupsScreen()),
                    ),
                    _MenuRow(
                      icon: Icons.inventory_2_outlined,
                      title: 'My listings',
                      trailing: '${items.myTotal} items',
                      onTap: () => _open(context, const MyListingsScreen()),
                    ),
                    _MenuRow(
                      icon: Icons.history,
                      title: 'Borrowing history',
                      trailing: '${loans.completedBorrowing.length} completed',
                      onTap: () => _open(context, const HistoryScreen()),
                    ),
                    _MenuRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Loan calendar',
                      onTap: () => _open(context, const CalendarScreen()),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuCard(
                  children: [
                    _MenuRow(
                      icon: Icons.settings_outlined,
                      title: 'Account settings',
                      onTap: () =>
                          _open(context, const AccountSettingsScreen()),
                    ),
                    if (user.role == 'admin')
                      _MenuRow(
                        icon: Icons.inbox_outlined,
                        title: 'Support inbox',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.conversations,
                        ),
                      )
                    else
                      _MenuRow(
                        icon: Icons.support_agent_outlined,
                        title: 'Contact admin',
                        onTap: () => _open(context, const ContactAdminScreen()),
                      ),
                    _MenuRow(
                      icon: Icons.help_outline,
                      title: 'Help & campus guidelines',
                      onTap: () => _showHelp(context),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GuidelineTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _GuidelineTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(color: AppColors.textGrey)),
              ],
            ),
          ),
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
  const _MenuRow({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
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
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: AppColors.textGrey),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  EDIT PROFILE SCREEN
// =====================================================================

/// Form for editing the user's profile details and avatar.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _uid;
  late final TextEditingController _email;
  final TextEditingController _address = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  String _gender = 'Not specified';
  String? _newAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _uid = TextEditingController(
      text: user == null ? '' : 'BC-${user.id.toString().padLeft(6, '0')}',
    );
    _email = TextEditingController(text: user?.email ?? '');
    _loadExtraDetails();
  }

  @override
  void dispose() {
    _name.dispose();
    _uid.dispose();
    _email.dispose();
    _address.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _loadExtraDetails() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _address.text = preferences.getString('profile_address') ?? '';
      _mobile.text = preferences.getString('profile_mobile') ?? '';
      _gender = preferences.getString('profile_gender') ?? 'Not specified';
    });
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) setState(() => _newAvatarPath = picked.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.updateProfile(_name.text, avatarPath: _newAvatarPath);
    if (!mounted) return;
    if (ok) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('profile_address', _address.text.trim());
      await preferences.setString('profile_mobile', _mobile.text.trim());
      await preferences.setString('profile_gender', _gender);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Profile updated');
    } else {
      showSnack(
        context,
        auth.error ?? 'Could not update profile',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
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
                      InkWell(
                        onTap: _pick,
                        customBorder: const CircleBorder(),
                        child: Stack(
                          children: [
                            UserAvatar(
                              name: user?.fullName ?? '',
                              avatar: user?.avatar,
                              radius: 60,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _newAvatarPath == null
                            ? 'Tap to change your photo'
                            : 'New photo selected',
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
                      AppTextField(
                        controller: _uid,
                        label: 'UID',
                        readOnly: true,
                        suffixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: ['Male', 'Female', 'Other'].map((gender) {
                          return Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(gender),
                              value: gender,
                              groupValue: _gender,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _gender = value);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        readOnly: true,
                        suffixIcon: Icons.lock_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _address,
                        label: 'Address',
                        hint: 'Your address',
                        maxLines: 3,
                        maxLength: 200,
                        validator: (value) => Validators.maxLength(value, 200),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _mobile,
                        label: 'Mobile no',
                        hint: 'Your mobile number',
                        suffixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 15,
                        validator: Validators.mobile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                text: 'Save changes',
                isLoading: auth.isLoading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  BORROWING HISTORY SCREEN
// =====================================================================

/// Completed loan history, filterable by role and year.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _role = 0;
  int _year = 0;

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanViewModel>();
    final me = context.watch<AuthViewModel>().user?.id ?? 0;
    var list = [...loans.completedBorrowing, ...loans.completedLending];
    if (_role == 1) list = list.where((l) => l.borrowerId == me).toList();
    if (_role == 2) list = list.where((l) => l.ownerId == me).toList();
    if (_year != 0) {
      list = list.where((l) {
        final date = Fmt.parseDay(l.endDate);
        return date != null && date.year == _year;
      }).toList();
    }
    list.sort((a, b) => b.endDate.compareTo(a.endDate));
    final years =
        list
            .map((l) => Fmt.parseDay(l.endDate)?.year)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Borrowing history'),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedTabs(
                          labels: const ['All', 'Borrowed by me', 'Lent by me'],
                          selected: _role,
                          onChanged: (value) => setState(() => _role = value),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('All years'),
                                selected: _year == 0,
                                onSelected: (_) => setState(() => _year = 0),
                              ),
                              const SizedBox(width: 8),
                              for (final year in years) ...[
                                ChoiceChip(
                                  label: Text('$year'),
                                  selected: _year == year,
                                  onSelected: (_) =>
                                      setState(() => _year = year),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, i) =>
                                LoanCard(loan: list[i], myId: me),
                          ),
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
