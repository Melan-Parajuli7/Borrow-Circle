import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/request_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/validators.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/pages/select_group.dart';

/// Step 1 of 2: choose Peer-to-Peer or Peer-to-Group, dates and a note.
class MakeRequestPage extends StatefulWidget {
  final ItemModel item;
  const MakeRequestPage({super.key, required this.item});

  @override
  State<MakeRequestPage> createState() => _MakeRequestPageState();
}

class _MakeRequestPageState extends State<MakeRequestPage> {
  final _note = TextEditingController();

  int _choice = 0; // 0 = Peer-to-Peer, 1 = Peer-to-Group
  late DateTime _start = Fmt.today();
  late DateTime _end = Fmt.today().add(const Duration(days: 2));

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _days => _end.difference(_start).inDays + 1;

  // The item itself belongs to a group -> it is always a group request.
  bool get _itemIsGroup => widget.item.isGroupItem;
  bool get _goesToGroupStep => !_itemIsGroup && _choice == 1;

  Future<void> _pickDate({required bool isStart}) async {
    final today = Fmt.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: isStart ? today : _start,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  // Checks dates + note. Returns an error text or null.
  String? _validate() {
    if (_days > AppStatic.maxBorrowDays) return 'You can borrow for up to ${AppStatic.maxBorrowDays} days.';
    return Validators.maxLength(_note.text, 500);
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      showSnack(context, error, isError: true);
      return;
    }

    // Peer-to-Group on a peer item -> go to step 2
    if (_goesToGroupStep) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectGroupPage(
            item: widget.item,
            startDate: Fmt.toApi(_start),
            endDate: Fmt.toApi(_end),
            message: _note.text,
          ),
        ),
      );
      return;
    }

    // Otherwise send the request right away
    final ctrl = context.read<RequestController>();
    final created = await ctrl.createRequest(
      itemId: widget.item.id,
      startDate: Fmt.toApi(_start),
      endDate: Fmt.toApi(_end),
      message: _note.text,
    );
    if (!mounted) return;
    if (created != null) {
      Navigator.popUntil(context, (route) => route.isFirst);
      AppNav.tabIndex.value = 1; // show My requests
      showSnack(context, 'Request sent!');
    } else {
      showSnack(context, ctrl.actionError ?? 'Could not send the request', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final busy = context.watch<RequestController>().isBusy;
    final stepLabel = _goesToGroupStep ? 'REQUEST DETAILS  /  1 OF 2' : 'REQUEST DETAILS';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Make a request'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stepLabel,
                        style: const TextStyle(color: AppColors.textGrey, letterSpacing: 0.5, fontSize: 14)),
                    const SizedBox(height: 12),

                    // Item summary
                    AppCard(
                      child: Row(
                        children: [
                          NetImage(url: AppStatic.imageUrl(item.imageUrl), width: 76, height: 76, radius: 14),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text(
                                  item.isGroupItem
                                      ? '${item.groupName ?? 'Group'} \u00b7 Group'
                                      : '${item.ownerName} \u00b7 Peer',
                                  style: const TextStyle(color: AppColors.textGrey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Who would you like to borrow from?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 12),

                    if (_itemIsGroup)
                      _ChoiceCard(
                        icon: Icons.groups_outlined,
                        title: 'Peer-to-Group',
                        subtitle: 'Borrow from ${item.groupName ?? 'a college group'}',
                        footer: 'The group coordinator (${item.ownerName}) will approve your request.',
                        selected: true,
                        onTap: () {},
                      )
                    else ...[
                      _ChoiceCard(
                        icon: Icons.person_outline,
                        title: 'Peer-to-Peer',
                        subtitle: 'Borrow from an individual student',
                        footer: '${item.ownerName} \u00b7 Verified student',
                        selected: _choice == 0,
                        onTap: () => setState(() => _choice = 0),
                      ),
                      const SizedBox(height: 12),
                      _ChoiceCard(
                        icon: Icons.groups_outlined,
                        title: 'Peer-to-Group',
                        subtitle: 'Borrow from a college group or club',
                        footer: 'A group coordinator will approve your request.',
                        selected: _choice == 1,
                        onTap: () => setState(() => _choice = 1),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: _DateBox(label: 'Pickup date', date: _start, onTap: () => _pickDate(isStart: true))),
                        const SizedBox(width: 12),
                        Expanded(child: _DateBox(label: 'Return date', date: _end, onTap: () => _pickDate(isStart: false))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _note,
                      label: 'Note to the lender',
                      hint: 'Why do you need it? I\u2019ll take good care of it!',
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${Fmt.daysText(_days)} \u00b7 No rental fee \u00b7 Return in the same condition',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _days > AppStatic.maxBorrowDays ? AppColors.error : AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                text: _goesToGroupStep ? 'Choose a group' : (_itemIsGroup ? 'Send Group Request' : 'Send request'),
                icon: _goesToGroupStep ? Icons.arrow_forward : Icons.send_outlined,
                isLoading: busy,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String footer;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: selected ? AppColors.primaryLightActive.withValues(alpha: 0.6) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text(subtitle, style: const TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                ),
                Icon(selected ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : AppColors.primaryLightActive, size: 30),
              ],
            ),
            const SizedBox(height: 10),
            Text(footer, style: const TextStyle(color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateBox({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(Fmt.dayLong(date), style: const TextStyle(fontSize: 15))),
                const Icon(Icons.calendar_month_outlined, color: AppColors.textGrey, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
