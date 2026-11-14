import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/loan_model.dart';

/// Handover confirmation.
///  - BORROWER sees the one-time 6-digit code (+ QR) and shows it to the owner.
///  - OWNER types that code and confirms the handover.
class HandoverPage extends StatefulWidget {
  final int loanId;
  const HandoverPage({super.key, required this.loanId});

  @override
  State<HandoverPage> createState() => _HandoverPageState();
}

class _HandoverPageState extends State<HandoverPage> {
  final _code = TextEditingController();
  LoanModel? _loan;
  bool _loading = true;
  String? _error;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ctrl = context.read<LoanController>();
    final loan = await ctrl.fetchLoan(widget.loanId);
    if (!mounted) return;
    setState(() {
      _loan = loan;
      _error = loan == null ? (ctrl.actionError ?? 'Could not load this loan') : null;
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      showSnack(context, 'Enter the 6-digit code', isError: true);
      return;
    }
    final ctrl = context.read<LoanController>();
    final ok = await ctrl.handover(widget.loanId, code);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      AppNav.tabIndex.value = 2;
      showSnack(context, 'Handover confirmed. The loan has started.');
    } else {
      showSnack(context, ctrl.actionError ?? 'Wrong code', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.id;
    final busy = context.watch<LoanController>().isBusy;
    final loan = _loan;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Confirm handover'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null || loan == null)
                      ? ErrorState(message: _error ?? 'Not found', onRetry: _load)
                      : _body(loan, me == loan.ownerId, busy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(LoanModel loan, bool isOwner, bool busy) {
    final started = !loan.awaitingHandover; // already handed over

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PillTag(text: 'Loan \u00b7 ${Fmt.loanCode(loan.id)}', icon: Icons.repeat),
                const SizedBox(height: 14),
                Text(
                  started
                      ? 'Handover done'
                      : (isOwner ? 'Ready to hand it over?' : 'Ready for your next project?'),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  started
                      ? 'This loan has already started.'
                      : (isOwner
                          ? 'Meet ${loan.borrowerName}, check the item together, then enter the code they show you.'
                          : 'Meet ${loan.ownerName} and check the item together before confirming.'),
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
                            Text(
                                '${Fmt.range(loan.startDate, loan.endDate)} \u00b7 ${Fmt.daysText(Fmt.totalDays(loan.startDate, loan.endDate))}',
                                style: const TextStyle(color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (!started && !isOwner) _borrowerCode(loan),
                if (!started && isOwner) _ownerCodeEntry(),
                if (started)
                  const InfoBanner(
                    icon: Icons.check_circle_outline,
                    text: 'Handover confirmed. The item is on loan.',
                  ),

                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      _row('Borrower', loan.borrowerName),
                      _row('Owner', loan.ownerName),
                      _row('Pickup', Fmt.day(loan.startDate)),
                      _row('Return by', Fmt.day(loan.endDate)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: started
              ? PrimaryButton(text: 'Done', onPressed: () => Navigator.pop(context))
              : isOwner
                  ? PrimaryButton(
                      text: 'Confirm handover',
                      icon: Icons.check,
                      isLoading: busy,
                      onPressed: _checked ? _confirm : null,
                    )
                  : OutlinedButton(onPressed: _load, child: const Text('Refresh status')),
        ),
      ],
    );
  }

  // ---------- borrower: shows the code ----------
  Widget _borrowerCode(LoanModel loan) {
    final code = loan.handoverCode ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(26)),
      child: Column(
        children: [
          const Text('YOUR ONE-TIME HANDOVER CODE',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 6; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 56,
                  width: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(i < code.length ? code[i] : '-',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (code.length == 6)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: code, size: 140, padding: EdgeInsets.zero),
            ),
          const SizedBox(height: 12),
          Text('Show this code to ${loan.ownerName}.',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }

  // ---------- owner: types the code ----------
  Widget _ownerCodeEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Enter the borrower's 6-digit code",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textDark)),
        const SizedBox(height: 10),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, letterSpacing: 10, fontWeight: FontWeight.w800),
          decoration: const InputDecoration(hintText: '------', counterText: ''),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => _checked = !_checked),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _checked,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _checked = v ?? false),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('I handed over the complete item and checked that everything is in working condition.',
                      style: TextStyle(fontSize: 15, height: 1.35)),
                ),
              ),
            ],
          ),
        ),
        const Text('Only confirm after you gave the item. This starts the loan and records a safe handover.',
            style: TextStyle(color: AppColors.textGrey)),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ],
        ),
      );
}
