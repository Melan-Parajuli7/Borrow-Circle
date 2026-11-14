import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/item_details.dart';

/// "See all" - the full item feed with endless scrolling.
class AllItemsPage extends StatefulWidget {
  const AllItemsPage({super.key});

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // near the bottom -> load the next page
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        context.read<ItemController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ItemController>();
    final items = ctrl.visibleItems;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'All items',
              trailing: SquareIconButton(icon: Icons.tune, onTap: () => showItemFilterSheet(context)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? (ctrl.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const EmptyState(
                          icon: Icons.search_off,
                          title: 'No items found',
                          message: 'Try a different search or filter.',
                        ))
                  : RefreshIndicator(
                      onRefresh: ctrl.load,
                      child: GridView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 278,
                        ),
                        itemCount: items.length + (ctrl.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= items.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return ItemCard(
                            item: items[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ItemDetailsPage(item: items[i])),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with category / condition / availability filters.
Future<void> showItemFilterSheet(BuildContext context) async {
  final ctrl = context.read<ItemController>();
  String? category = ctrl.category;
  String? condition = ctrl.condition;
  bool onlyAvailable = ctrl.onlyAvailable;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 16),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
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
                const Text('Condition', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  title: const Text('Only available items', style: TextStyle(fontWeight: FontWeight.w700)),
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
                          ctrl.applyFilters(category: null, condition: null, onlyAvailable: false);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ctrl.applyFilters(category: category, condition: condition, onlyAvailable: onlyAvailable);
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
