import 'package:flutter/services.dart';

import '../../data/models/loan_model.dart';

/// Builds a plain-text return receipt for a completed loan and copies it to the
/// clipboard.
///
/// This is a pure presentation-side utility; it has no network or storage
/// dependencies.
class ReceiptExportService {
  ReceiptExportService._();

  /// Returns a human-readable receipt string for [loan].
  static String receiptText(LoanModel loan) {
    return 'BORROWCIRCLE DIGITAL RETURN RECEIPT\n'
        'Loan serial: BC-${loan.id.toString().padLeft(6, '0')}\n'
        'Item: ${loan.itemTitle}\n'
        'Borrower: ${loan.borrowerName}\n'
        'Owner: ${loan.ownerName}\n'
        'Loan period: ${loan.startDate} to ${loan.endDate}\n'
        'Handover: ${loan.handedOverAt?.toLocal().toString() ?? 'Not recorded'}\n'
        'Returned: ${loan.returnedAt?.toLocal().toString() ?? 'Not recorded'}\n'
        'Status: Verified return\n';
  }

  /// Copies the receipt text for [loan] to the system clipboard.
  static Future<void> copy(LoanModel loan) async {
    await Clipboard.setData(ClipboardData(text: receiptText(loan)));
  }
}