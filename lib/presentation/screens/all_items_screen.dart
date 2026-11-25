import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/app_static.dart';
import '../widgets/app_widgets.dart';
import '../viewmodels/item_viewmodel.dart';
import './home_screen.dart';
import './item_details_screen.dart';
import './notifications_screen.dart';

/// Screen showing all items with search and filters.
class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({super.key});

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) context.read<ItemViewModel>().setSearch(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemViewModel = context.watch<ItemViewModel>();
    final items = itemViewModel.visibleItems;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: itemViewModel.load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'All Items',
                              style: const TextStyle(
                                fontSize: 28,
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (itemViewModel.isLoading && items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (itemViewModel.error != null && items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(message: itemViewModel.error!, onRetry: itemViewModel.load),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No items found',
                    message: 'Try adjusting your search or filters.',
                    action: SizedBox(
                      width: 180,
                      child: OutlinedButton(
                        onPressed: itemViewModel.load,
                        child: const Text('Clear filters'),
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
      ),
    );
  }
}

/// Bottom sheet for filtering the item feed by category, condition, and
/// availability. Shared by [HomeTab] and [AllItemsScreen].
Future<void> showItemFilterSheet(BuildContext context) async {
  final itemViewModel = context.read<ItemViewModel>();
  String? category = itemViewModel.category;
  String? condition = itemViewModel.condition;
  bool onlyAvailable = itemViewModel.onlyAvailable;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filters',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 16),
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in AppStatic.categories)
                      ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (v) => setSheet(() => category = v ? c : null),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Condition',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in AppStatic.conditions)
                      ChoiceChip(
                        label: Text(AppStatic.pretty(c)),
                        selected: condition == c,
                        onSelected: (v) => setSheet(() => condition = v ? c : null),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only available items',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  value: onlyAvailable,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setSheet(() => onlyAvailable = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          itemViewModel.applyFilters(
                              category: null, condition: null, onlyAvailable: false);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          itemViewModel.applyFilters(
                              category: category,
                              condition: condition,
                              onlyAvailable: onlyAvailable);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
