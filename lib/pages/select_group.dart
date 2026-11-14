import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/request_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/services/group_service.dart';

/// Step 2 of 2: pick which campus group should receive the request.
class SelectGroupPage extends StatefulWidget {
  final ItemModel item;
  final String startDate;
  final String endDate;
  final String message;

  const SelectGroupPage({
    super.key,
    required this.item,
    required this.startDate,
    required this.endDate,
    required this.message,
  });

  @override
  State<SelectGroupPage> createState() => _SelectGroupPageState();
}

class _SelectGroupPageState extends State<SelectGroupPage> {
  bool _loading = true;
  String? _error;

  // group name -> items of that group with the same title
  Map<String, List<ItemModel>> _byGroup = {};
  String? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = context.read<AuthController>().user?.id;
      final alts = await GroupService().findGroupAlternatives(widget.item.title);
      final map = <String, List<ItemModel>>{};
      for (final i in alts) {
        if (i.ownerId == me) continue; // you cannot request your own item
        map.putIfAbsent(i.groupName ?? 'Group', () => []).add(i);
      }
      if (!mounted) return;
      setState(() {
        _byGroup = map;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // The first free kit of the chosen group
  ItemModel? get _chosenItem {
    if (_selected == null) return null;
    final list = _byGroup[_selected] ?? [];
    for (final i in list) {
      if (i.isAvailable) return i;
    }
    return null;
  }

  Future<void> _send() async {
    final chosen = _chosenItem;
    if (chosen == null) return;

    final ctrl = context.read<RequestController>();
    final created = await ctrl.createRequest(
      itemId: chosen.id,
      startDate: widget.startDate,
      endDate: widget.endDate,
      message: widget.message,
    );
    if (!mounted) return;
    if (created != null) {
      Navigator.popUntil(context, (route) => route.isFirst);
      AppNav.tabIndex.value = 1;
      showSnack(context, 'Group request sent!');
    } else {
      showSnack(context, ctrl.actionError ?? 'Could not send the request', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<RequestController>().isBusy;
    final days = Fmt.totalDays(widget.startDate, widget.endDate);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Choose a group'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _load)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SELECT GROUP  /  2 OF 2',
                                  style: TextStyle(color: AppColors.textGrey, letterSpacing: 0.5)),
                              const SizedBox(height: 12),
                              AppCard(
                                child: Row(
                                  children: [
                                    NetImage(
                                        url: AppStatic.imageUrl(widget.item.imageUrl),
                                        width: 76,
                                        height: 76,
                                        radius: 14),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.item.title,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textDark)),
                                          const SizedBox(height: 4),
                                          Text('${_byGroup.length} campus groups \u00b7 Group',
                                              style: const TextStyle(color: AppColors.textGrey)),
                                          Text(
                                              'Requested dates: ${Fmt.range(widget.startDate, widget.endDate)} (${Fmt.daysText(days)})',
                                              style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_byGroup.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: EmptyState(
                                    icon: Icons.groups_outlined,
                                    title: 'No groups lend this item',
                                    message: 'Go back and choose Peer-to-Peer instead.',
                                  ),
                                )
                              else ...[
                                const Text('These campus groups lend this item. Choose one to send your request to.',
                                    style: TextStyle(fontSize: 16, height: 1.4)),
                                const SizedBox(height: 14),
                                for (final entry in _byGroup.entries) ...[
                                  _GroupChoice(
                                    name: entry.key,
                                    items: entry.value,
                                    selected: _selected == entry.key,
                                    onTap: () {
                                      if (entry.value.any((i) => i.isAvailable)) {
                                        setState(() => _selected = entry.key);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                const InfoBanner(
                                  icon: Icons.groups_outlined,
                                  text:
                                      'Group loans work just like peer loans. A coordinator approves the request and arranges pickup.',
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                text: 'Send Group Request',
                icon: Icons.send_outlined,
                isLoading: busy,
                onPressed: _chosenItem == null ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChoice extends StatelessWidget {
  final String name;
  final List<ItemModel> items;
  final bool selected;
  final VoidCallback onTap;

  const _GroupChoice({required this.name, required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final available = items.where((i) => i.isAvailable).length;
    final coordinator = items.first.ownerName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightActive.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text('Coordinator: $coordinator', style: const TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                ),
                Icon(selected ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                    color: available == 0 ? AppColors.border : AppColors.primary, size: 30),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PillTag(text: 'Group lender', icon: Icons.groups_outlined, bg: Colors.transparent),
                available > 0
                    ? PillTag(text: '$available available')
                    : const PillTag(text: 'All on loan', bg: AppColors.surface, fg: AppColors.textGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
