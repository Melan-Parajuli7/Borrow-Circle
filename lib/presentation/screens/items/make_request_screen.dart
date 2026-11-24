import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../utils/format.dart';
import '../../../core/constants/app_static.dart';
import '../../widgets/app_widgets.dart';
import '../../../data/models/item_model.dart';
import '../../viewmodels/request_viewmodel.dart';

/// Screen for creating a borrow request for an item.
class MakeRequestScreen extends StatefulWidget {
  final ItemModel item;
  const MakeRequestScreen({super.key, required this.item});

  @override
  State<MakeRequestScreen> createState() => _MakeRequestScreenState();
}

class _MakeRequestScreenState extends State<MakeRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _message = TextEditingController();

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: AppStatic.maxBorrowDays)),
    );
    if (date != null && mounted) {
      controller.text = Fmt.toApi(date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final requestViewModel = context.read<RequestViewModel>();
    final ok = await requestViewModel.createRequest(
      itemId: widget.item.id,
      startDate: _startDate.text,
      endDate: _endDate.text,
      message: _message.text.isEmpty ? null : _message.text,
    );
    if (!mounted) return;
    if (ok != null) {
      Navigator.pop(context);
      showSnack(context, 'Request sent!');
    } else {
      showSnack(context, requestViewModel.error ?? 'Failed to send request', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestViewModel = context.watch<RequestViewModel>();
    final loading = requestViewModel.isBusy;
    final item = widget.item;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(title: 'Request to borrow'),
                const SizedBox(height: 8),
                Text('Borrow "${item.title}" for:',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 24),

                // Start date
                AppTextField(
                  controller: _startDate,
                  label: 'Start date',
                  hint: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: () => _pickDate(_startDate),
                  suffixIcon: Icons.calendar_today,
                  validator: (v) => v == null || v.isEmpty ? 'Start date is required' : null,
                ),
                const SizedBox(height: 16),

                // End date
                AppTextField(
                  controller: _endDate,
                  label: 'End date',
                  hint: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: () => _pickDate(_endDate),
                  suffixIcon: Icons.calendar_today,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'End date is required';
                    final start = Fmt.parseDay(_startDate.text);
                    final end = Fmt.parseDay(v);
                    if (start != null && end != null && end.isBefore(start)) {
                      return 'End date must be after start date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Message
                AppTextField(
                  controller: _message,
                  label: 'Message (optional)',
                  hint: 'Tell the owner why you need this...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                if (item.isGroupItem)
                  InfoBanner(
                    icon: Icons.groups_outlined,
                    text: 'This is a group item. Your request will go to the group coordinator.',
                  ),

                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Send Request',
                  icon: Icons.arrow_forward,
                  isLoading: loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}