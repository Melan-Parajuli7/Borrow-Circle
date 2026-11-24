import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/app_static.dart';
import '../../utils/validators.dart';
import '../../widgets/app_widgets.dart';
import '../../../data/models/group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../items/add_item_screen.dart';
import '../items/item_details_screen.dart';

/// "My groups" screen.
///
/// The backend has no group memberships, so:
///  - "Your groups"   = groups where the user listed at least one item (admin)
///  - "Campus groups" = every other group that lends items on campus
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  // Asks for a name, then opens "List a New Item" with that group preselected.
  Future<void> _createGroup(BuildContext context) async {
    final name = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create group'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: name,
            maxLength: 100,
            decoration: const InputDecoration(hintText: 'e.g. Robotics Club'),
            validator: Validators.groupName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(ctx, name.text.trim());
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
    name.dispose();
    if (result == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddItemScreen(presetGroupName: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupViewModel>();
    final me = context.watch<AuthViewModel>().user?.id ?? 0;
    final pending = context.watch<RequestViewModel>().pendingReceived;
    final loans = context.watch<LoanViewModel>();

    final mine = ctrl.managedBy(me);
    final others = ctrl.othersFor(me);

    // active loans of a group = loans whose item belongs to it (matched by item id)
    int activeLoans(GroupModel g) {
      final ids = g.items.map((i) => i.id).toSet();
      return loans.activeLending.where((l) => ids.contains(l.itemId)).length +
          loans.activeBorrowing.where((l) => ids.contains(l.itemId)).length;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'My groups'),
            Expanded(
              child: ctrl.isLoading && ctrl.groups.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.error != null && ctrl.groups.isEmpty
                  ? ErrorState(message: ctrl.error!, onRetry: ctrl.load)
                  : RefreshIndicator(
                      onRefresh: ctrl.load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          const Text(
                            'Shared tools, shared possibilities. Manage your college groups and their lending inventory.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: 'Create group',
                            icon: Icons.add,
                            onPressed: () => _createGroup(context),
                          ),
                          const SizedBox(height: 20),

                          if (ctrl.groups.isEmpty)
                            const EmptyState(
                              icon: Icons.groups_outlined,
                              title: 'No groups yet',
                              message:
                                  'Create a group by listing a shared item for your club.',
                            ),

                          if (mine.isNotEmpty) ...[
                            SectionHeader(
                              title: 'Your groups',
                              actionText: '${mine.length} groups',
                            ),
                            const SizedBox(height: 12),
                            for (final g in mine) ...[
                              _GroupCard(
                                group: g,
                                isAdmin: true,
                                activeLoans: activeLoans(g),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (others.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SectionHeader(
                              title: 'Campus groups',
                              actionText: '${others.length} groups',
                            ),
                            const SizedBox(height: 12),
                            for (final g in others) ...[
                              _GroupCard(
                                group: g,
                                isAdmin: false,
                                activeLoans: activeLoans(g),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],

                          if (pending > 0) ...[
                            const SizedBox(height: 8),
                            AppCard(
                              color: AppColors.primaryLight,
                              borderColor: AppColors.primaryLight,
                              onTap: () {
                                Navigator.popUntil(context, (r) => r.isFirst);
                                AppNav.tabIndex.value = 1;
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.inbox_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$pending request${pending == 1 ? '' : 's'} to review. Tap to open.',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;
  final int activeLoans;
  const _GroupCard({
    required this.group,
    required this.isAdmin,
    required this.activeLoans,
  });

  void _showJoinRequests(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${group.name} join requests'),
        content: const Text('No pending join requests.'),
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
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupInventoryScreen(group: group)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightActive.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      isAdmin ? 'Club Coordinator · Admin' : 'Student Member',
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              PillTag(
                text: isAdmin ? 'Admin' : 'Member',
                bg: isAdmin ? AppColors.primaryLight : AppColors.surface,
                fg: isAdmin ? AppColors.primary : AppColors.textGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${group.availableCount} free · $activeLoans loaned',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: group.itemCount == 0
                  ? 0
                  : group.availableCount / group.itemCount,
              minHeight: 7,
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${group.itemCount} items · ${group.availableCount} available',
                style: const TextStyle(color: AppColors.textGrey),
              ),
              Text(
                isAdmin ? 'Manage group →' : 'View inventory →',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddItemScreen(presetGroupName: group.name),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinRequests(context),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Requests'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// All items of one group.
class GroupInventoryScreen extends StatelessWidget {
  final GroupModel group;
  const GroupInventoryScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: group.name),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 278,
                ),
                itemCount: group.items.length,
                itemBuilder: (context, i) => ItemCard(
                  item: group.items[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(item: group.items[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}