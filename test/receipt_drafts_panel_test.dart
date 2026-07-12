import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_draft_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/home/expenses_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('receipt drafts show in a compact dedicated panel', (
    tester,
  ) async {
    final controller = ExpenseDraftController.memory();
    await controller.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-1',
        receiptDate: DateTime(2026, 7, 8),
        updatedAt: DateTime(2026, 7, 8, 9, 24),
        merchantName: 'Lowes',
        enteredTotal: 18.42,
      ),
    );

    await tester.pumpWidget(
      ExpenseDraftScope(
        controller: controller,
        child: const MaterialApp(home: Scaffold(body: ReceiptDraftsPanel())),
      ),
    );

    expect(find.text('Receipt Drafts'), findsOneWidget);
    expect(find.text('1 saved draft | Latest 7/8/2026'), findsOneWidget);
    expect(find.text('Lowes'), findsNothing);

    await tester.tap(find.text('Receipt Drafts'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Drafts'), findsNWidgets(2));
    expect(find.text('Lowes'), findsOneWidget);
    expect(find.text('Unfinished receipts'), findsNothing);
  });
}
