import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/app_static.dart';
import '../../widgets/app_widgets.dart';
import '../../viewmodels/account_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/fingerprint_viewmodel.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/request_viewmodel.dart';
import '../../viewmodels/review_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/calendar_viewmodel.dart';
import '../../utils/notification_generator.dart';
import '../../routes/app_routes.dart';
import '../items/add_item_screen.dart';
import '../items/all_items_screen.dart';
import '../items/item_details_screen.dart';
import '../loans/loans_screen.dart';
import '../requests/requests_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../calendar/calendar_screen.dart';

/// Main screen with bottom navigation bar (Home / Requests / Loans / Profile).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AppNav.tabIndex.value = 0;
    AppNav.tabIndex.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final account = context.read<AccountViewModel>();
      final notifications = context.read<NotificationViewModel>();
      final fingerprint = context.read<FingerprintViewModel>();
      await _loadEverything();
      if (!mounted) return;
      await account.loadPreferences();
      await notifications.load();
      await fingerprint.load();
      if (!mounted) return;
      _syncNotifications();
    });
  }

  @override
  void dispose() {
    AppNav.tabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  // Loads the data of all tabs once.
  Future<void> _loadEverything() async {
    final items = context.read<ItemViewModel>();
    final requests = context.read<RequestViewModel>();
    final loans = context.read<LoanViewModel>();
    final reviews = context.read<ReviewViewModel>();
    final groups = context.read<GroupViewModel>();
    await Future.wait([
      items.load(),
      items.loadMine(),
      requests.load(),
      loans.load(),
      reviews.loadReceived(),
      reviews.loadGiven(),
      groups.load(),
    ]);
  }

  // When the user opens a tab, refresh its data.
  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
    switch (AppNav.tabIndex.value) {
      case 0:
        context.read<ItemViewModel>().load();
        break;
      case 1:
        context.read<RequestViewModel>().load();
        break;
      case 2:
        context.read<LoanViewModel>().load();
        context.read<ReviewViewModel>().loadGiven();
        break;
      case 3:
        _refreshCalendar();
        break;
      case 4:
        _refreshNotifications();
        break;
      case 5:
        context.read<LoanViewModel>().load();
        context.read<ItemViewModel>().loadMine();
        context.read<ReviewViewModel>().loadReceived();
        context.read<GroupViewModel>().load();
        break;
    }
  }

  // Reloads the calendar events from the latest loans.
  Future<void> _refreshCalendar() async {
    final loans = context.read<LoanViewModel>();
    await loans.load();
    if (!mounted) return;
    context.read<CalendarViewModel>().load(loans.borrowing, loans.lending);
  }

  // Reloads requests/loans and regenerates local notifications.
  Future<void> _refreshNotifications() async {
    final requests = context.read<RequestViewModel>();
    final loans = context.read<LoanViewModel>();
    final notifications = context.read<NotificationViewModel>();
    await Future.wait([requests.load(), loans.load(), notifications.load()]);
    if (!mounted) return;
    await _syncNotifications();
  }

  // Generates notifications from the current requests/loans and merges them.
  Future<void> _syncNotifications() async {
    final requests = context.read<RequestViewModel>();
    final loans = context.read<LoanViewModel>();
    final notifications = context.read<NotificationViewModel>();
    final generated = NotificationGenerator.generate(
      sent: requests.sent,
      received: requests.received,
      activeBorrowing: loans.activeBorrowing,
      activeLending: loans.activeLending,
    );
    await notifications.mergeGenerated(generated);
  }

  @override
  Widget build(BuildContext context) {
    final index = AppNav.tabIndex.value;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeTab(),
          RequestsScreen(),
          LoansScreen(),
          CalendarScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => AppNav.tabIndex.value = i,
destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: 'Requests',
            ),
            NavigationDestination(icon: Icon(Icons.repeat), label: 'Loans'),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home tab (the item feed).
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // Wait until the user stops typing, then search.
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) context.read<ItemViewModel>().setSearch(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemViewModel = context.watch<ItemViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final firstName = (authViewModel.user?.fullName ?? '').trim().split(' ').first;
    final items = itemViewModel.visibleItems;
    const tabs = ['all', 'peer', 'group'];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: itemViewModel.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hello + bell
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hello, $firstName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        SquareIconButton(
                          icon: Icons.notifications_none,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SquareIconButton(
                          icon: Icons.message_outlined,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.conversations,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // University + "List an item"
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStatic.universityOf(authViewModel.user?.email ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddItemScreen()),
                          ),
                          child: const Text('+ List an item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search bar
                    TextField(
                      controller: _search,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'What do you need for campus?',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: itemViewModel.hasActiveFilters
                                ? AppColors.tertiary
                                : AppColors.primary,
                          ),
                          onPressed: () => showItemFilterSheet(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedTabs(
                      labels: const ['All items', 'Peer items', 'Group items'],
                      selected: tabs.indexOf(itemViewModel.typeFilter),
                      onChanged: (i) => itemViewModel.setType(tabs[i]),
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: 'Ready to borrow',
                      actionText: 'See all',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllItemsScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // The grid (or loading / error / empty)
            if (itemViewModel.isLoading && itemViewModel.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (itemViewModel.error != null && itemViewModel.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(message: itemViewModel.error!, onRetry: itemViewModel.load),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nothing here yet',
                  message: 'Be the first to list an item for your campus.',
                  action: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddItemScreen()),
                      ),
                      child: const Text('List an item'),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 278,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ItemCard(
                      item: items[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailsScreen(item: items[i]),
                        ),
                      ),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}