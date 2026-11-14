import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/controller/request_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/request_model.dart';
import 'package:borrowcircle/pages/handover.dart';

/// "My requests" tab: Sent | Received.
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  int _tab = 0; // 0 = sent, 1 = received

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RequestController>();
    final list = _tab == 0 ? ctrl.sent : ctrl.received;

    return SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'My requests', showBack: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SegmentedTabs(
              labels: ['Sent \u00b7 ${ctrl.sent.length}', 'Received \u00b7 ${ctrl.received.length}'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: ctrl.isLoading && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ctrl.error != null && list.isEmpty
                    ? ErrorState(message: ctrl.error!, onRetry: ctrl.load)
                    : RefreshIndicator(
                        onRefresh: ctrl.load,
                        child: list.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 60),
                                  EmptyState(
                                    icon: Icons.inbox_outlined,
                                    title: _tab == 0 ? 'No requests sent' : 'Nobody asked yet',
                                    message: _tab == 0
                                        ? 'Find something you need on Home and tap Request to borrow.'
                                        : 'When someone asks for your items, it will show up here.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 14),
                                itemBuilder: (context, i) =>
                                    _RequestCard(request: list[i], isReceived: _tab == 1),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final bool isReceived;
  const _RequestCard({required this.request, required this.isReceived});

  // Owner starts the loan for an approved request -> opens the handover screen.
  Future<void> _startLoan(BuildContext context) async {
    final loans = context.read<LoanController>();
    final loan = await loans.createLoan(request.id);
    if (!context.mounted) return;
    if (loan != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HandoverPage(loanId: loan.id)));
    } else {
      // e.g. "A loan already exists" -> send the user to the Loans tab
      showSnack(context, loans.actionError ?? 'Could not start the loan', isError: true);
      AppNav.tabIndex.value = 2;
    }
  }

  Future<void> _run(BuildContext context, Future<bool> Function() action, String okMessage) async {
    final ctrl = context.read<RequestController>();
    final ok = await action();
    if (!context.mounted) return;
    showSnack(context, ok ? okMessage : (ctrl.actionError ?? 'Something went wrong'), isError: !ok);
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.itemTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 12),
              _detail('Requested by', request.requesterName),
              _detail('Owner', request.ownerName),
              _detail('Dates', '${Fmt.day(request.startDate)} \u2013 ${Fmt.day(request.endDate)}'),
              _detail('Duration', Fmt.daysText(Fmt.totalDays(request.startDate, request.endDate))),
              _detail('Status', AppStatic.pretty(request.status)),
              if ((request.message ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('\u201c${request.message}\u201d',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textGrey, fontSize: 16)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey)),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<RequestController>().isBusy;
    final ctrl = context.read<RequestController>();
    final who = isReceived ? request.requesterName : request.ownerName;
    final days = Fmt.totalDays(request.startDate, request.endDate);
    final statusText = (isReceived && request.isPending) ? 'Needs approval' : null;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PillTag(
                text: isReceived ? 'Received' : 'Sent',
                icon: isReceived ? Icons.move_to_inbox_outlined : Icons.send_outlined,
              ),
              StatusChip(status: request.status, textOverride: statusText),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              NetImage(url: AppStatic.imageUrl(request.itemImage), width: 84, height: 84, radius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.itemTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(who,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textGrey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${Fmt.range(request.startDate, request.endDate)} \u00b7 ${Fmt.daysText(days)}',
                        style: const TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),

          if (isReceived && (request.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('\u201c${request.message}\u201d',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 15)),
          ],

          const SizedBox(height: 12),

          // ----- actions / footer text -----
          if (isReceived && request.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDetails(context),
                    child: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error, padding: EdgeInsets.zero),
                    onPressed: busy ? null : () => _run(context, () => ctrl.reject(request.id), 'Request rejected'),
                    child: const Icon(Icons.close),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Approve',
                    icon: Icons.check,
                    isLoading: busy,
                    onPressed: () => _run(context, () => ctrl.approve(request.id), 'Request approved'),
                  ),
                ),
              ],
            )
          else if (isReceived && request.isApproved)
            PrimaryButton(
              text: 'Start handover',
              icon: Icons.handshake_outlined,
              onPressed: () => _startLoan(context),
            )
          else if (!isReceived && request.isPending)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Waiting for ${request.ownerName}\u2019s approval \u00b7 Sent ${Fmt.ago(request.createdAt)}',
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : () => _run(context, () => ctrl.cancel(request.id), 'Request cancelled'),
                  child: const Text('Cancel'),
                ),
              ],
            )
          else if (!isReceived && request.isApproved)
            Text(
              'Approved \u00b7 ${request.ownerName} will start the handover. Check the Loans tab.',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            )
          else
            Text(
              request.status == 'rejected'
                  ? 'This request was rejected.'
                  : 'This request was cancelled.',
              style: const TextStyle(color: AppColors.textGrey),
            ),
        ],
      ),
    );
  }
}
