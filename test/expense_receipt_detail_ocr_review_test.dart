import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/calendar/expense_calendar.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  testWidgets('saved receipt detail shows OCR review metadata', (tester) async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-ocr-detail',
        receiptDate: DateTime(2026, 6, 23),
        merchantName: 'Lowes',
        rawOcrText: 'LOWES\nPVC GLUE 7.99\nTOTAL 7.99',
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'review',
          source: 'mixed',
          warningKinds: ['duplicateText'],
          warningLabels: ['Duplicate lines ignored'],
          primaryWarningKind: 'duplicateText',
          primaryWarningLabelOverride: 'Duplicate lines ignored',
          primaryWarningTargetLabel: 'Check long receipt overlap',
          primaryWarningTargetInstruction:
              'Check the stitch/overlap area and make sure the same charge was not counted twice.',
          recoveryAction: 'review_overlap',
          recoveryTarget: 'receipt_overlap',
          recoverySummary: 'Check the long-receipt overlap before saving.',
          warningCount: 1,
          reviewWarningCount: 1,
          attachmentsRead: 2,
          rawLineCount: 4,
          parserLineCount: 3,
          hadDuplicateOrOverlapText: true,
        ),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'line-1',
            description: 'PVC Glue',
            category: 'Materials',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 7.99,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: ExpenseLedgerScope(
              controller: ledger,
              child: const ExpenseReceiptDetailScreen(
                receiptId: 'EXP-ocr-detail',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Receipt breakdown'), findsOneWidget);
    expect(find.text('BUSINESS'), findsOneWidget);
    expect(find.text('PERSONAL'), findsOneWidget);
    expect(find.text('Read needs review'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Receipt read review'),
      220,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Receipt read review'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.textContaining('Duplicate lines ignored'), findsOneWidget);
    expect(find.textContaining('Check long receipt overlap'), findsOneWidget);
    expect(
      find.textContaining('same charge was not counted twice'),
      findsOneWidget,
    );
    expect(find.text('Recovery'), findsOneWidget);
    expect(find.text('Check overlap'), findsOneWidget);
    expect(find.text('Check area'), findsOneWidget);
    expect(find.text('Long receipt overlap'), findsOneWidget);
    expect(find.textContaining('review_overlap'), findsNothing);
    expect(find.textContaining('receipt_overlap'), findsNothing);
    expect(find.text('2 read'), findsOneWidget);
    expect(find.text('3 receipt lines ready'), findsOneWidget);
    expect(find.textContaining('parser'), findsNothing);
    expect(find.text('1 OCR warning'), findsOneWidget);
  });

  testWidgets('saved receipt detail hides OCR review when no metadata exists', (
    tester,
  ) async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-manual-detail',
        receiptDate: DateTime(2026, 6, 23),
        merchantName: 'Manual Receipt',
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'line-1',
            description: 'Manual Item',
            category: 'Uncategorized',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 12,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: ExpenseLedgerScope(
              controller: ledger,
              child: const ExpenseReceiptDetailScreen(
                receiptId: 'EXP-manual-detail',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Receipt read review'), findsNothing);
  });

  testWidgets('calendar day entry shows privacy-safe OCR recovery summary', (
    tester,
  ) async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-calendar-ocr',
        receiptDate: DateTime(2026, 6, 23),
        receiptTimeMinutes: 13 * 60,
        merchantName: 'Receipt',
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'review',
          source: 'mixed',
          warningKinds: ['duplicateText'],
          warningLabels: ['Duplicate lines ignored'],
          primaryWarningKind: 'duplicateText',
          primaryWarningLabelOverride: 'Duplicate lines ignored',
          primaryWarningTargetLabel: 'Check long receipt overlap',
          primaryWarningTargetInstruction:
              'Check the stitch/overlap area and make sure the same charge was not counted twice.',
          recoveryAction: 'review_overlap',
          recoveryTarget: 'receipt_overlap',
          recoverySummary: 'Check the long-receipt overlap before saving.',
          warningCount: 1,
          reviewWarningCount: 1,
          attachmentsRead: 2,
          rawLineCount: 4,
          parserLineCount: 3,
          hadDuplicateOrOverlapText: true,
        ),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'line-1',
            description: 'PVC Glue',
            category: 'Materials',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 7.99,
          ),
        ],
      ),
    );

    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-calendar-clean-read',
        receiptDate: DateTime(2026, 6, 24),
        receiptTimeMinutes: 9 * 60,
        merchantName: 'Receipt',
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'good',
          source: 'photo',
          attachmentsRead: 1,
          rawLineCount: 8,
          parserLineCount: 4,
          usedLocalOcr: true,
        ),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'line-2',
            description: 'Shop supplies',
            category: 'Supplies',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 5,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: ExpenseLedgerScope(
              controller: ledger,
              child: ExpenseDayScreen(day: DateTime(2026, 6, 23)),
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Read needs review: Check long receipt overlap'),
      findsOneWidget,
    );
    expect(find.text('Receipt read health'), findsOneWidget);
    expect(find.text('1 need review'), findsWidgets);
    expect(
      find.text(
        '1 read saved | 1 need review | Top check: Check long receipt overlap',
      ),
      findsWidgets,
    );
    await tester.scrollUntilVisible(
      find.text('Weekly'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Read Summary'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        '2 reads saved | 1 need review | 1 saved clean | Top check: Check long receipt overlap',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('review_overlap'), findsNothing);
    expect(find.textContaining('receipt_overlap'), findsNothing);
    expect(find.textContaining('LOWES'), findsNothing);
    expect(find.textContaining('3.24'), findsNothing);
  });

  test('saved receipt recovery routes preserve detail before edit', () async {
    final calendarActions = await File(
      'lib/screens/expenses/calendar/expense_calendar_actions.dart',
    ).readAsString();
    final dayEntries = await File(
      'lib/screens/expenses/calendar/expense_day_entries.dart',
    ).readAsString();
    final daySummarySections = await File(
      'lib/screens/expenses/calendar/expense_day_summary_sections.dart',
    ).readAsString();
    final daySummaryRecapPanels = await File(
      'lib/screens/expenses/calendar/expense_day_summary_recap_panels.dart',
    ).readAsString();
    final homeNavigation = await File(
      'lib/screens/expenses/home/expenses_home_navigation_actions.dart',
    ).readAsString();
    final detailInfo = await File(
      'lib/screens/expenses/calendar/expense_receipt_detail_info.dart',
    ).readAsString();
    final detailProofPreview = await File(
      'lib/screens/expenses/calendar/expense_receipt_detail_proof_preview.dart',
    ).readAsString();
    final detailOcrReview = await File(
      'lib/screens/expenses/calendar/expense_receipt_detail_ocr_review.dart',
    ).readAsString();
    final calendarModels = await File(
      'lib/screens/expenses/calendar/expense_calendar_models.dart',
    ).readAsString();

    expect(calendarActions, contains('_openReceiptDetailFromEntry'));
    expect(calendarActions, contains('ExpenseReceiptDetailScreen'));
    expect(calendarActions, contains('calendar_delete_receipt_failed'));
    expect(calendarActions, contains('calendar_edit_line_failed'));
    expect(calendarActions, contains('calendar_copy_line_failed'));
    expect(calendarActions, contains('calendar_delete_line_failed'));
    expect(calendarActions, contains('That receipt could not be deleted.'));
    expect(calendarActions, contains('That receipt line could not be saved.'));
    expect(calendarActions, contains('That receipt line could not be copied.'));
    expect(
      calendarActions,
      contains('That receipt line could not be deleted.'),
    );
    expect(dayEntries, contains('_openReceiptDetailFromEntry(context, entry)'));
    expect(homeNavigation, contains('ExpenseReceiptDetailScreen'));
    expect(detailInfo, contains('_ReceiptAllocationPanel'));
    expect(detailInfo, contains('Receipt breakdown'));
    expect(detailProofPreview, contains('_openReceiptPhotoProof'));
    expect(detailProofPreview, contains('_ReceiptPhotoProofViewerScreen'));
    expect(detailProofPreview, contains('InteractiveViewer'));
    expect(detailProofPreview, contains('proofAccessLabel'));
    expect(detailOcrReview, contains('_recoveryActionLabel'));
    expect(detailOcrReview, contains('_recoveryTargetLabel'));
    expect(detailOcrReview, contains('Recovery'));
    expect(detailOcrReview, contains('Check area'));
    expect(detailOcrReview, contains('Long receipt overlap'));
    expect(detailInfo, contains('Read needs review'));
    expect(calendarModels, contains('totalForLine(line)'));
    expect(calendarModels, contains('_calendarOcrStatusLabel'));
    expect(calendarModels, contains('_calendarOcrRecoveryHintLabel'));
    expect(calendarModels, contains('ocrSummaryLabel'));
    expect(calendarModels, contains('_CalendarOcrDayRecap'));
    expect(calendarModels, contains('fromLedgerRange'));
    expect(calendarModels, contains('fromReceipts'));
    expect(calendarModels, contains('_topCalendarOcrHint'));
    expect(calendarModels, contains('Read needs review'));
    expect(dayEntries, contains('entry.ocrSummaryLabel'));
    expect(dayEntries, contains('Read saved'));
    expect(daySummarySections, contains('_CalendarOcrDayRecapPanel'));
    expect(daySummarySections, contains('Receipt read health'));
    expect(daySummaryRecapPanels, contains('Receipt Read Status'));
    expect(daySummaryRecapPanels, contains('Read Summary'));
    expect(daySummaryRecapPanels, contains('Top Check'));
    expect(
      calendarActions,
      isNot(contains('ExpenseReceiptEntryScreen(\n        initialCategory')),
    );
  });
}
