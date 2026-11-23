import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/pages/add_item.dart';
import 'package:borrowcircle/pages/item_details.dart';

/// "My listings" - items I listed (tap to open, menu to edit or delete).
class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  Future<void> _setAvailability(
    BuildContext context,
    ItemModel item,
    bool available,
  ) async {
    final ctrl = context.read<ItemController>();
    final updated = await ctrl.updateItem(
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
          ? (ctrl.actionError ?? 'Could not update availability')
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
    final ctrl = context.read<ItemController>();
    final updated = await ctrl.updateItem(
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
          ? (ctrl.actionError ?? 'Could not update condition')
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final ctrl = context.read<ItemController>();
    final ok = await ctrl.deleteItem(id);
    if (!context.mounted) return;
    showSnack(
      context,
      ok ? 'Item deleted' : (ctrl.actionError ?? 'Could not delete'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ItemController>();
    final items = ctrl.myItems;

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
                  MaterialPageRoute(builder: (_) => const AddItemPage()),
                ),
              ),
            ),
            Expanded(
              child: ctrl.isLoadingMine && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.mineError != null && items.isEmpty
                  ? ErrorState(message: ctrl.mineError!, onRetry: ctrl.loadMine)
                  : items.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No listings yet',
                      message: 'Tap + to list your first item.',
                    )
                  : RefreshIndicator(
                      onRefresh: ctrl.loadMine,
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
                                builder: (_) => ItemDetailsPage(item: item),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: const TextStyle(
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      PillTag(
                                        text: item.isAvailable
                                            ? 'Available'
                                            : 'On loan',
                                        bg: item.isAvailable
                                            ? AppColors.primaryLight
                                            : AppColors.tertiaryLight,
                                        fg: item.isAvailable
                                            ? AppColors.primary
                                            : AppColors.tertiaryDark,
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () =>
                                            _updateCondition(context, item),
                                        child: PillTag(
                                          text: item.condition.replaceAll(
                                            '_',
                                            ' ',
                                          ),
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
                                  onChanged: (value) =>
                                      _setAvailability(context, item, value),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddItemPage(editItem: item),
                                        ),
                                      );
                                    } else if (v == 'duplicate') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddItemPage(duplicateItem: item),
                                        ),
                                      );
                                    } else if (v == 'delete') {
                                      _delete(context, item.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text('Duplicate listing'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
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
