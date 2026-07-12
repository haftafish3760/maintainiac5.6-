import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fresh expense entry hides interrupted photos until opened from home',
    () {
      final entry = File(
        'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
      ).readAsStringSync();
      final attachment = File(
        'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
      ).readAsStringSync();
      final home = File(
        'lib/screens/expenses/home/expenses_home_screen.dart',
      ).readAsStringSync();
      final drafts = File(
        'lib/screens/expenses/home/expenses_home_activity_sections.dart',
      ).readAsStringSync();

      expect(entry, contains('this.showInterruptedCaptureRecovery = false'));
      expect(attachment, contains('widget.showInterruptedCaptureRecovery'));
      expect(home, contains('const ReceiptDraftsPanel()'));
      expect(drafts, contains('Receipt Drafts'));
      expect(drafts, contains('Continue or delete saved receipt work.'));
      expect(drafts, contains('_continuePhotoDraft(context, draft)'));
      expect(drafts, isNot(contains('Review Interrupted Receipt')));
      expect(drafts, isNot(contains('Receipt photo draft')));
    },
  );
}
