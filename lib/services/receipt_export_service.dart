import 'package:flutter/services.dart';

import 'package:borrowcircle/model/loan_model.dart';

class ReceiptExportService {
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

  static Future<void> copy(LoanModel loan) async {
    await Clipboard.setData(ClipboardData(text: receiptText(loan)));
  }
}
