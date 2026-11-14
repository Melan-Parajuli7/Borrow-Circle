import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/controller/review_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/loan_model.dart';
import 'package:borrowcircle/pages/handover.dart';
import 'package:borrowcircle/pages/return_item.dart';
import 'package:borrowcircle/pages/review.dart';

/// "Active loans" tab.
class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  int _tab = 0; // 0 = all active, 1 = borrowing, 2 = lending

  Future<void> _refresh() async {
    await context.read<LoanController>().load();
    if (mounted) await context.read<ReviewController>().loadGiven();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<LoanController>();
    final me = context.watch<AuthController>().user?.id ?? 0;

    final borrowing = ctrl.activeBorrowing;
    final lending = ctrl.activeLending;
    final active = _tab == 0 ? [...borrowing, ...lending] : (_tab == 1 ? borrowing : lending);
    final completed = _tab == 0
        ? [...ctrl.completedBorrowing, ...ctrl.completedLending]
        : (_tab == 1 ? ctrl.completedBorrowing : ctrl.completedLending);

    return SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Active loans', showBack: false),
          Expanded(
            child: ctrl.isLoading && ctrl.borrowing.isEmpty && ctrl.lending.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ctrl.error != null && ctrl.borrowing.isEmpty && ctrl.lending.isEmpty
                    ? ErrorState(message: ctrl.error!, onRetry: ctrl.load)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _SummaryCard(
                                        label: 'Borrowing',
                                        count: borrowing.length,
                                        sub: 'Items you hold')),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _SummaryCard(
                                        label: 'Lending', count: lending.length, sub: 'Items you lent out')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SegmentedTabs(
                              labels: const ['All active', 'Borrowing', 'Lending'],
                              selected: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const SizedBox(height: 16),
                            if (active.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: EmptyState(
                                  icon: Icons.repeat,
                                  title: 'No active loans',
                                  message: 'Approved requests turn into loans after the handover.',
                                ),
                              )
                            else
                              for (final loan in active) ...[
                                LoanCard(loan: loan, myId: me),
                                const SizedBox(height: 14),
                              ],
                            if (completed.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Completed',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                              const SizedBox(height: 12),
                              for (final loan in completed) ...[
                                LoanCard(loan: loan, myId: me),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final String sub;
  const _SummaryCard({required this.label, required this.count, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 16)),
          const SizedBox(height: 4),
          Text(count.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

/// One loan card. Also used by the "Borrowing history" screen.
class LoanCard extends StatelessWidget {
  final LoanModel loan;
  final int myId;
  const LoanCard({super.key, required this.loan, required this.myId});

  bool get _iAmOwner => loan.ownerId == myId;

  // text + color for the chip in the top right corner
  (String, String) get _chip {
    switch (loan.stage) {
      case 'awaiting_handover':
        return ('awaiting_handover', 'Awaiting handover');
      case 'overdue':
        return ('overdue', 'Overdue');
      case 'returned':
        return ('returned', 'Returned');
      default:
        final left = Fmt.daysLeft(loan.endDate);
        return ('on_loan', left <= 0 ? 'Due today' : (left == 1 ? '1 day left' : '$left days left'));
    }
  }

  double get _progress {
    final s = Fmt.parseDay(loan.startDate);
    final e = Fmt.parseDay(loan.endDate);
    if (s == null || e == null) return 0;
    final total = e.difference(s).inDays + 1;
    final used = Fmt.today().difference(s).inDays + 1;
    return (used / total).clamp(0.0, 1.0);
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final (chipStatus, chipText) = _chip;
    final other = _iAmOwner ? loan.borrowerName : loan.ownerName;
    final reviewed = context.watch<ReviewController>().reviewedLoanIds.contains(loan.id);

    Widget? action;
    if (loan.awaitingHandover) {
      action = PrimaryButton(
        text: _iAmOwner ? 'Confirm handover' : 'Show handover code',
        icon: _iAmOwner ? Icons.check : Icons.qr_code_2,
        onPressed: () => _open(context, HandoverPage(loanId: loan.id)),
      );
    } else if (loan.isOut) {
      action = _iAmOwner
          ? PrimaryButton(
              text: 'Confirm return',
              icon: Icons.repeat,
              onPressed: () => _open(context, ReturnPage(loan: loan)),
            )
          : OutlinedButton(
              onPressed: () => _open(context, ReturnPage(loan: loan)),
              child: const Text('How to return'),
            );
    } else if (loan.isReturned && !reviewed) {
      action = OutlinedButton(
        onPressed: () => _open(context, ReviewPage(loan: loan)),
        child: const Text('Leave a review'),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PillTag(
                text: _iAmOwner ? 'Lending' : 'Borrowing',
                icon: _iAmOwner ? Icons.north_east : Icons.south_west,
              ),
              StatusChip(status: chipStatus, textOverride: chipText),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              NetImage(url: AppStatic.imageUrl(loan.itemImage), width: 84, height: 84, radius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.itemTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(other,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_iAmOwner ? 'You\u2019re lending' : 'Borrowing'} \u00b7 ${Fmt.range(loan.startDate, loan.endDate)}',
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (loan.isOut) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 7,
                backgroundColor: AppColors.surface,
                color: loan.isOverdue ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Return by ${Fmt.dayWithWeekday(loan.endDate)}',
                style: const TextStyle(color: AppColors.textGrey)),
          ],
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }
}
