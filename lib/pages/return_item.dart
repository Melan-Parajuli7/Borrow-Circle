import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/loan_model.dart';
import 'package:borrowcircle/pages/review.dart';

/// Return confirmation.
///  - OWNER ticks the checklist and confirms the item came back.
///  - BORROWER only sees how to return it (the backend lets the owner confirm).
class ReturnPage extends StatefulWidget {
  final LoanModel loan;
  const ReturnPage({super.key, required this.loan});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final List<bool> _checks = [false, false, false];

  static const _labels = [
    'All parts and accessories are included',
    'No damage and everything works',
    'Item handed back to the owner',
  ];

  Future<void> _confirm() async {
    final ctrl = context.read<LoanController>();
    final updated = await ctrl.returnLoan(widget.loan.id);
    if (!mounted) return;
    if (updated != null) {
      showSnack(context, 'Item returned. The circle is closed!');
      // go straight to the review screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReviewPage(loan: updated)));
    } else {
      showSnack(context, ctrl.actionError ?? 'Could not confirm the return', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final me = context.watch<AuthController>().user?.id;
    final isOwner = me == loan.ownerId;
    final busy = context.watch<LoanController>().isBusy;
    final left = Fmt.daysLeft(loan.endDate);
    final dueText = left < 0
        ? 'Overdue since ${Fmt.day(loan.endDate)}'
        : (left == 0 ? 'Due today' : 'Due ${Fmt.dayWithWeekday(loan.endDate)}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Return your item'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillTag(text: 'Loan \u00b7 ${Fmt.loanCode(loan.id)}', icon: Icons.repeat),
                    const SizedBox(height: 14),
                    const Text('Closing the circle.',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text(
                      isOwner
                          ? 'Check the item with ${loan.borrowerName}, then confirm it is back.'
                          : 'Return the item to ${loan.ownerName}. They will confirm the return in their app.',
                      style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          NetImage(url: AppStatic.imageUrl(loan.itemImage), width: 76, height: 76, radius: 14),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loan.itemTitle,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text(dueText,
                                    style: TextStyle(
                                        color: left < 0 ? AppColors.error : AppColors.textGrey,
                                        fontWeight: left < 0 ? FontWeight.w700 : FontWeight.w400)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (isOwner) ...[
                      const Text('Before you confirm',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      for (var i = 0; i < _labels.length; i++)
                        InkWell(
                          onTap: () => setState(() => _checks[i] = !_checks[i]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _checks[i],
                                  activeColor: AppColors.primary,
                                  onChanged: (v) => setState(() => _checks[i] = v ?? false),
                                ),
                                Expanded(child: Text(_labels[i], style: const TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),
                    ] else
                      const InfoBanner(
                        icon: Icons.info_outline,
                        text: 'Meet the owner, hand the item back and let them confirm the return. Then you can leave a review.',
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: isOwner
                  ? PrimaryButton(
                      text: 'Confirm return',
                      icon: Icons.check,
                      isLoading: busy,
                      onPressed: _checks.every((c) => c) ? _confirm : null,
                    )
                  : PrimaryButton(text: 'Got it', onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }
}
