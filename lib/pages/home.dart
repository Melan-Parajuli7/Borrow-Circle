import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/group_controller.dart';
import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/controller/request_controller.dart';
import 'package:borrowcircle/controller/review_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/add_item.dart';
import 'package:borrowcircle/pages/all_items.dart';
import 'package:borrowcircle/pages/item_details.dart';
import 'package:borrowcircle/pages/loans.dart';
import 'package:borrowcircle/pages/profile.dart';
import 'package:borrowcircle/pages/requests.dart';

// =====================================================================
//  HomePage = the main screen with the bottom bar (Home / Requests / Loans / Profile)
// =====================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    AppNav.tabIndex.value = 0;
    AppNav.tabIndex.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEverything());
  }

  @override
  void dispose() {
    AppNav.tabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  // Loads the data of all tabs once.
  void _loadEverything() {
    context.read<ItemController>().load();
    context.read<ItemController>().loadMine();
    context.read<RequestController>().load();
    context.read<LoanController>().load();
    context.read<ReviewController>().loadReceived();
    context.read<ReviewController>().loadGiven();
    context.read<GroupController>().load();
  }

  // When the user opens a tab, refresh its data.
  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
    switch (AppNav.tabIndex.value) {
      case 0:
        context.read<ItemController>().load();
        break;
      case 1:
        context.read<RequestController>().load();
        break;
      case 2:
        context.read<LoanController>().load();
        context.read<ReviewController>().loadGiven();
        break;
      case 3:
        context.read<LoanController>().load();
        context.read<ItemController>().loadMine();
        context.read<ReviewController>().loadReceived();
        context.read<GroupController>().load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = AppNav.tabIndex.value;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [HomeTab(), RequestsPage(), LoansPage(), ProfilePage()],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => AppNav.tabIndex.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Requests'),
            NavigationDestination(icon: Icon(Icons.repeat), label: 'Loans'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  HOME TAB (the item feed)
// =====================================================================
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

  // Wait until the user stops typing, then search (so we don't call the API on every key).
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) context.read<ItemController>().setSearch(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ItemController>();
    final user = context.watch<AuthController>().user;
    final firstName = (user?.fullName ?? '').trim().split(' ').first;
    final items = ctrl.visibleItems;
    const tabs = ['all', 'peer', 'group'];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: ctrl.load,
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
                          child: Text('Hello, $firstName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        ),
                        SquareIconButton(
                          icon: Icons.notifications_none,
                          onTap: () => showSnack(context, 'No new notifications.'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // University + "List an item"
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(AppStatic.universityOf(user?.email ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const AddItemPage())),
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
                          icon: Icon(Icons.tune,
                              color: ctrl.hasActiveFilters ? AppColors.tertiary : AppColors.primary),
                          onPressed: () => showItemFilterSheet(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedTabs(
                      labels: const ['All items', 'Peer items', 'Group items'],
                      selected: tabs.indexOf(ctrl.typeFilter),
                      onChanged: (i) => ctrl.setType(tabs[i]),
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: 'Ready to borrow',
                      actionText: 'See all',
                      onAction: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AllItemsPage())),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ----- the grid (or loading / error / empty) -----
            if (ctrl.isLoading && ctrl.items.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
            else if (ctrl.error != null && ctrl.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(message: ctrl.error!, onRetry: ctrl.load),
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
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage())),
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
                        MaterialPageRoute(builder: (_) => ItemDetailsPage(item: items[i])),
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
