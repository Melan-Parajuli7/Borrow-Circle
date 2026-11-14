import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/model/review_model.dart';
import 'package:borrowcircle/pages/add_item.dart';
import 'package:borrowcircle/pages/make_request.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/group_service.dart';
import 'package:borrowcircle/services/item_service.dart';
import 'package:borrowcircle/services/review_service.dart';

/// Item details screen.
class ItemDetailsPage extends StatefulWidget {
  final ItemModel item;
  const ItemDetailsPage({super.key, required this.item});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  late ItemModel _item = widget.item;
  ReviewSummary? _ownerRating;
  List<ItemModel> _groupAlternatives = [];

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  // Fresh item data + owner rating + "group-owned kit" suggestion.
  Future<void> _loadExtras() async {
    try {
      final fresh = await ItemService().getItem(_item.id);
      if (mounted) setState(() => _item = fresh);
    } catch (_) {}

    try {
      final r = await ReviewService().getUserReviews(_item.ownerId, limit: 1);
      if (mounted) setState(() => _ownerRating = r.summary);
    } catch (_) {}

    if (!_item.isGroupItem) {
      try {
        final alts = await GroupService().findGroupAlternatives(_item.title);
        if (mounted) setState(() => _groupAlternatives = alts.where((i) => i.isAvailable).toList());
      } on ApiException {
        // optional info, ignore errors
      }
    }
  }

  Future<void> _delete() async {
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
    if (sure != true || !mounted) return;

    final ctrl = context.read<ItemController>();
    final ok = await ctrl.deleteItem(_item.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSnack(context, 'Item deleted');
    } else {
      showSnack(context, ctrl.actionError ?? 'Could not delete the item', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user;
    final isMine = me?.id == _item.ownerId;
    final item = _item;

    String ratingText = 'Verified student';
    if (_ownerRating != null && _ownerRating!.total > 0) {
      ratingText =
          'Verified student \u00b7 ${_ownerRating!.average.toStringAsFixed(1)} \u2605 (${_ownerRating!.total} reviews)';
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Item details'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NetImage(
                      url: AppStatic.imageUrl(item.imageUrl),
                      width: double.infinity,
                      height: 230,
                      radius: 22,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        PillTag(
                          text: item.isGroupItem ? 'Group item' : 'Peer item',
                          icon: item.isGroupItem ? Icons.groups_outlined : Icons.person_outline,
                        ),
                        PillTag(
                          text: item.isAvailable ? 'Available' : 'On loan',
                          bg: item.isAvailable ? AppColors.primaryLight : AppColors.tertiaryLight,
                          fg: item.isAvailable ? AppColors.primary : AppColors.tertiaryDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item.title,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text(
                      '${item.category ?? 'Other'} \u00b7 Free to borrow',
                      style: const TextStyle(fontSize: 16, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 16),

                    // Owner card
                    AppCard(
                      child: Row(
                        children: [
                          UserAvatar(name: item.ownerName, avatar: item.ownerAvatar, radius: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.ownerName,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(ratingText, style: const TextStyle(color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text('About this item',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text(
                      (item.description == null || item.description!.trim().isEmpty)
                          ? 'No description provided.'
                          : item.description!,
                      style: const TextStyle(fontSize: 16, height: 1.45, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(label: 'Condition', value: AppStatic.pretty(item.condition)),
                    if (item.isGroupItem && item.groupName != null)
                      _InfoRow(label: 'Group', value: item.groupName!),
                    const _InfoRow(label: 'Borrowing limit', value: 'Up to ${AppStatic.maxBorrowDays} days'),
                    const SizedBox(height: 14),

                    if (_groupAlternatives.isNotEmpty && !isMine)
                      InfoBanner(
                        icon: Icons.groups_outlined,
                        text:
                            'Need a group-owned kit instead?\n${_groupAlternatives.first.groupName ?? 'A group'} has ${_groupAlternatives.length} available. Choose Peer-to-Group when making your request.',
                      ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: isMine
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddItemPage(editItem: item)),
                              );
                              _loadExtras();
                            },
                            child: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            onPressed: _delete,
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    )
                  : PrimaryButton(
                      text: item.isAvailable ? 'Request to borrow' : 'Currently on loan',
                      icon: Icons.arrow_forward,
                      onPressed: item.isAvailable
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MakeRequestPage(item: item)),
                              )
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }
}
