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

  test('saved receipt recovery routes preserve detail before edit', () async {
    final calendarActions = await File(
      'lib/screens/expenses/calendar/expense_calendar_actions.dart',
    ).readAsString();
    final dayEntries = await File(
      'lib/screens/expenses/calendar/expense_day_entries.dart',
    ).readAsString();
    final homeNavigation = await File(
      'lib/screens/expenses/home/expenses_home_navigation_actions.dart',
    ).readAsString();
    final detailInfo = await File(
      'lib/screens/expenses/calendar/expense_receipt_detail_info.dart',
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
    expect(detailInfo, contains('_openReceiptPhotoProof'));
    expect(detailInfo, contains('_ReceiptPhotoProofViewerScreen'));
    expect(detailInfo, contains('InteractiveViewer'));
    expect(detailInfo, contains('proofAccessLabel'));
    expect(calendarModels, contains('totalForLine(line)'));
    expect(
      calendarActions,
      isNot(contains('ExpenseReceiptEntryScreen(\n        initialCategory')),
    );
  });
}
