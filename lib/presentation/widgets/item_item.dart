import 'package:flutter/material.dart';

import '../../data/models/item_model.dart';
import '../../core/constants/colors.dart';

/// A single item row displayed in item lists.
///
/// Shows the item title, category, condition, and availability, plus an
/// avatar for the owner. Swiping dismisses the item (delete). Tapping the
/// row opens the item details screen.
class ItemItem extends StatelessWidget {
  /// The item to display.
  final ItemModel item;

  /// Callback invoked when the item is deleted (swipe or delete icon).
  final VoidCallback onDelete;

  /// Callback invoked when the item row is tapped.
  final VoidCallback onTap;

  /// Creates an [ItemItem] for the given [item] with the required callbacks.
  const ItemItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      // Background shown while swiping to delete.
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            item.isGroupItem ? Icons.group : Icons.inventory_2,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category ?? 'General',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.condition} • ${item.isAvailable ? 'Available' : 'Unavailable'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isAvailable
                        ? AppColors.secondary
                        : AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
