import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'review exits are owned by one guarded Expense route transaction',
    () async {
      final attachmentPanel = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
      ).readAsString();
      final lifecycle = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_lifecycle_helpers.dart',
      ).readAsString();
      final exitActions = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_exit_actions.dart',
      ).readAsString();
      final manualFlow = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
      ).readAsString();
      final screen = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
      ).readAsString();

      expect(
        attachmentPanel,
        contains(
          'onReceiptPhotoReviewExitRequested: '
          '_handleReceiptPhotoReviewExitRequested',
        ),
      );
      expect(attachmentPanel, contains('await _saveReceiptDraftAndExit();'));
      expect(attachmentPanel, contains('await _discardReceiptAndExit();'));
      expect(manualFlow, contains('await _saveReceiptDraftAndExit();'));
      expect(manualFlow, contains('await _discardReceiptAndExit();'));
      expect(exitActions, contains('if (_receiptReviewExitInFlight)'));
      expect(exitActions, contains('_draftTimer?.cancel();'));
      expect(exitActions, contains('final saved = await _saveDraftNow();'));
      final draftDeleteIndex = exitActions.indexOf(
        'await _drafts?.deleteDraft(_draftId)',
      );
      final artifactDiscardIndex = exitActions.indexOf(
        '_manualReceiptAttachmentController.discardReceiptSession()',
      );
      expect(draftDeleteIndex, greaterThanOrEqualTo(0));
      expect(draftDeleteIndex, greaterThan(artifactDiscardIndex));
      expect(
        exitActions,
        contains('_manualReceiptAttachmentController.discardReceiptSession()'),
      );
      expect(exitActions, contains('await _drafts?.deleteDraft(_draftId)'));
      expect(exitActions, contains('_receiptReviewExitInFlight = false;'));
      expect(exitActions, contains('_receiptExitResolved = true'));
      expect(
        exitActions,
        contains('openAppSectionRoot(context, AppSection.expenses);'),
      );
      expect(exitActions, isNot(contains('Navigator.of(context).maybePop()')));
      expect(manualFlow, contains('_returnToExpensesHome();'));
      expect(screen, contains('var _receiptReviewExitInFlight = false;'));
      expect(screen, contains('var _receiptExitResolved = false;'));
      expect(lifecycle, contains('!_receiptReviewExitInFlight'));
    },
  );

  test('manual acceptance advances without claiming OCR is running', () async {
    final helpers = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_core_helpers.dart',
    ).readAsString();

    expect(helpers, contains('final assistedReceiptFill ='));
    expect(helpers, contains("'Receipt proof ready'"));
    expect(helpers, contains("'Reading receipt'"));
    expect(helpers, contains('_scrollToReceiptReview();'));
  });
}
