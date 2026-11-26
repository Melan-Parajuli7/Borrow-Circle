import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../utils/format.dart';
import '../../core/constants/app_static.dart';
import '../widgets/app_widgets.dart';
import '../../data/models/loan_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/conversation_viewmodel.dart';
import '../viewmodels/loan_viewmodel.dart';
import '../viewmodels/review_viewmodel.dart';
import './handover_screen.dart';
import './return_item_screen.dart';
import './review_screen.dart';
import './loan_chat_page.dart';
import '../utils/receipt_export_service.dart';

/// "Active loans" screen.
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  int _tab = 0; // 0 = all active, 1 = borrowing, 2 = lending

  Future<void> _refresh() async {
    await context.read<LoanViewModel>().load();
    if (mounted) await context.read<ReviewViewModel>().loadGiven();
  }

  @override
  Widget build(BuildContext context) {
    final loanViewModel = context.watch<LoanViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final me = authViewModel.user?.id ?? 0;

    final borrowing = loanViewModel.activeBorrowing;
    final lending = loanViewModel.activeLending;
    final active = _tab == 0
        ? [...borrowing, ...lending]
        : (_tab == 1 ? borrowing : lending);
    final completed = _tab == 0
        ? [
            ...loanViewModel.completedBorrowing,
            ...loanViewModel.completedLending,
          ]
        : (_tab == 1
              ? loanViewModel.completedBorrowing
              : loanViewModel.completedLending);

    return SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Active loans', showBack: false),
          Expanded(
            child:
                loanViewModel.isLoading &&
                    loanViewModel.borrowing.isEmpty &&
                    loanViewModel.lending.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : loanViewModel.error != null &&
                      loanViewModel.borrowing.isEmpty &&
                      loanViewModel.lending.isEmpty
                ? ErrorState(
                    message: loanViewModel.error!,
                    onRetry: loanViewModel.load,
                  )
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
                                sub: 'Items you hold',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: 'Lending',
                                count: lending.length,
                                sub: 'Items you lent out',
                              ),
                            ),
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
                          const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
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
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.primary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
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
        return (
          'on_loan',
          left <= 0
              ? 'Due today'
              : (left == 1 ? '1 day left' : '$left days left'),
        );
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

  Future<void> _showReceipt(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Digital return certificate'),
        content: SingleChildScrollView(
          child: Text(
            ReceiptExportService.receiptText(loan),
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ReceiptExportService.copy(loan);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copy receipt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewViewModel = context.watch<ReviewViewModel>();
    final (chipStatus, chipText) = _chip;
    final other = _iAmOwner ? loan.borrowerName : loan.ownerName;
    final reviewed = reviewViewModel.reviewedLoanIds.contains(loan.id);

    Widget? action;
    if (loan.awaitingHandover) {
      action = PrimaryButton(
        text: _iAmOwner ? 'Confirm handover' : 'Show handover code',
        icon: _iAmOwner ? Icons.check : Icons.qr_code_2,
        onPressed: () => _open(context, HandoverScreen(loanId: loan.id)),
      );
    } else if (loan.isOut) {
      action = _iAmOwner
          ? PrimaryButton(
              text: 'Confirm return',
              icon: Icons.repeat,
              onPressed: () => _open(context, ReturnItemScreen(loan: loan)),
            )
          : OutlinedButton(
              onPressed: () => _open(context, ReturnItemScreen(loan: loan)),
              child: const Text('How to return'),
            );
    } else if (loan.isReturned && !reviewed) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: () => _open(context, ReviewScreen(loan: loan)),
            child: const Text('Leave a review'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              AppNav.tabIndex.value = 0;
            },
            icon: const Icon(Icons.replay),
            label: const Text('Borrow again'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showReceipt(context),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View return receipt'),
          ),
        ],
      );
    } else if (loan.isReturned) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              AppNav.tabIndex.value = 0;
            },
            icon: const Icon(Icons.replay),
            label: const Text('Borrow again'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showReceipt(context),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View return receipt'),
          ),
        ],
      );
    }

    final canMessage =
        (loan.isOut || loan.awaitingHandover) &&
        loan.borrowerId != 0 &&
        loan.ownerId != 0;
    final messageButton = OutlinedButton.icon(
      onPressed: () async {
        final vm = context.read<ConversationViewModel>();
        final conv = await vm.startLoanConversation(loan.id);
        if (!context.mounted) return;
        if (conv == null) {
          showSnack(
            context,
            vm.error ?? 'Could not open this conversation',
            isError: true,
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoanChatPage(conversation: conv, loan: loan),
          ),
        );
      },
      icon: const Icon(Icons.message, size: 18),
      label: const Text('Message'),
    );

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
              NetImage(
                url: AppStatic.imageUrl(loan.itemImage),
                width: 84,
                height: 84,
                radius: 16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.itemTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            other,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textGrey),
                          ),
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
            Text(
              'Return by ${Fmt.dayWithWeekday(loan.endDate)}',
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
          if (loan.awaitingHandover && canMessage && action != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: messageButton),
                const SizedBox(width: 8),
                Expanded(child: action),
              ],
            ),
          ] else ...[
            if (canMessage) ...[
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: messageButton),
            ],
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ],
      ),
    );
  }
}
