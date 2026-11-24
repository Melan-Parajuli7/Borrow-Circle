import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/app_static.dart';
import '../../widgets/app_widgets.dart';
import '../../../data/models/item_model.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../items/add_item_screen.dart';
import '../items/item_details_screen.dart';

/// "My listings" - items I listed (tap to open, menu to edit or delete).
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  Future<void> _setAvailability(
    BuildContext context,
    ItemModel item,
    bool available,
  ) async {
    final itemViewModel = context.read<ItemViewModel>();
    final updated = await itemViewModel.updateItem(
      item.id,
      title: item.title,
      description: item.description,
      category: item.category,
      condition: item.condition,
      isGroupItem: item.isGroupItem,
      groupName: item.groupName,
      isAvailable: available,
    );
    if (!context.mounted) return;
    showSnack(
      context,
      updated == null
          ? (itemViewModel.error ?? 'Could not update availability')
          : (available ? 'Listing is available' : 'Listing hidden'),
      isError: updated == null,
    );
  }

  Future<void> _updateCondition(BuildContext context, ItemModel item) async {
    final conditions = const ['new', 'like_new', 'good', 'fair', 'poor'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: conditions
              .map(
                (value) => ListTile(
                  title: Text(value.replaceAll('_', ' ')),
                  trailing: item.condition == value
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, value),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected == null || selected == item.condition) return;
    if (!context.mounted) return;
    final itemViewModel = context.read<ItemViewModel>();
    final updated = await itemViewModel.updateItem(
      item.id,
      title: item.title,
      description: item.description,
      category: item.category,
      condition: selected,
      isGroupItem: item.isGroupItem,
      groupName: item.groupName,
      isAvailable: item.isAvailable,
    );
    if (!context.mounted) return;
    showSnack(
      context,
      updated == null
          ? (itemViewModel.error ?? 'Could not update condition')
          : 'Condition updated',
      isError: updated == null,
    );
  }

  Future<void> _delete(BuildContext context, int id) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final itemViewModel = context.read<ItemViewModel>();
    final ok = await itemViewModel.deleteItem(id);
    if (!context.mounted) return;
    showSnack(
      context,
      ok ? 'Item deleted' : (itemViewModel.error ?? 'Could not delete'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemViewModel = context.watch<ItemViewModel>();
    final items = itemViewModel.myItems;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'My listings',
              trailing: SquareIconButton(
                icon: Icons.add,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemScreen()),
                ),
              ),
            ),
            Expanded(
              child: itemViewModel.isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : itemViewModel.error != null && items.isEmpty
                      ? ErrorState(message: itemViewModel.error!, onRetry: itemViewModel.loadMine)
                      : items.isEmpty
                          ? const EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No listings yet',
                              message: 'Tap + to list your first item.',
                            )
                          : RefreshIndicator(
                              onRefresh: itemViewModel.loadMine,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final item = items[i];
                                  return AppCard(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ItemDetailsScreen(item: item),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        NetImage(
                                          url: AppStatic.imageUrl(item.imageUrl),
                                          width: 72,
                                          height: 72,
                                          radius: 14,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.isGroupItem
                                                    ? 'Group \u00b7 ${item.groupName ?? ''}'
                                                    : 'Individual',
                                                style: const TextStyle(color: AppColors.textGrey),
                                              ),
                                              const SizedBox(height: 6),
                                              PillTag(
                                                text: item.isAvailable ? 'Available' : 'On loan',
                                                bg: item.isAvailable
                                                    ? AppColors.primaryLight
                                                    : AppColors.tertiaryLight,
                                                fg: item.isAvailable ? AppColors.primary : AppColors.tertiaryDark,
                                              ),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: () => _updateCondition(context, item),
                                                child: PillTag(
                                                  text: item.condition.replaceAll('_', ' '),
                                                  icon: Icons.tune,
                                                  bg: AppColors.surface,
                                                  fg: AppColors.textGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: item.isAvailable,
                                          onChanged: (value) => _setAvailability(context, item, value),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AddItemScreen(editItem: item),
                                                ),
                                              );
                                            } else if (v == 'duplicate') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AddItemScreen(editItem: item),
                                                ),
                                              );
                                            } else if (v == 'delete') {
                                              _delete(context, item.id);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                                            PopupMenuItem(value: 'duplicate', child: Text('Duplicate listing')),
                                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                                          ],
                                        ),
                                      ],
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