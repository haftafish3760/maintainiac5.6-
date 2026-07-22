import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_firestore_documents.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_scope_filter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';

void main() {
  const context = ExpenseReceiptContextSnapshot(
    workProfileId: 'delivery',
    workProfileName: 'Evening Delivery',
    vehicleId: 'van-7',
    vehicleLabel: 'Cargo Van',
    jobId: 'job-42',
    jobLabel: 'Kitchen repair',
  );

  test('receipt and draft preserve their historical operating context', () {
    final receipt = ExpenseReceiptRecord.fromMap(
      ExpenseReceiptRecord(
        id: 'EXP-context',
        receiptDate: DateTime(2026, 7, 14),
        contextSnapshot: context,
        lines: const [],
      ).toMap(),
    );
    final draft = ExpenseReceiptDraftRecord.fromMap(
      ExpenseReceiptDraftRecord(
        id: 'DRAFT-context',
        receiptDate: DateTime(2026, 7, 14),
        updatedAt: DateTime(2026, 7, 14),
        contextSnapshot: context,
      ).toMap(),
    );

    expect(receipt.contextSnapshot.workProfileName, 'Evening Delivery');
    expect(receipt.contextSnapshot.vehicleId, 'van-7');
    expect(receipt.contextSnapshot.jobId, 'job-42');
    expect(receipt.vehicleId, 'van-7');
    expect(receipt.workProfileId, 'delivery');
    expect(draft.contextSnapshot.jobLabel, 'Kitchen repair');
  });

  test('scopes filter historical work, vehicle, and job identifiers', () async {
    final ledger = ExpenseLedgerController.memory();
    final day = DateTime(2026, 7, 14);
    Future<void> save(
      String id,
      double total,
      ExpenseReceiptContextSnapshot receiptContext,
    ) => ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: id,
        receiptDate: day,
        contextSnapshot: receiptContext,
        lines: [
          ExpenseReceiptLineRecord(
            id: '$id-line',
            description: 'Receipt total',
            category: 'Tools',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: total,
          ),
        ],
      ),
    );
    await save('delivery-van', 12.50, context);
    await save(
      'repair-truck',
      8,
      const ExpenseReceiptContextSnapshot(
        workProfileId: 'repair',
        vehicleId: 'truck',
        jobId: 'job-99',
      ),
    );
    final range = ExpenseDateRange(start: day, end: day);

    expect(ledger.summaryForRange(range).totalCents, 2050);
    expect(
      ledger
          .summaryForRange(
            range,
            scope: const ExpenseLedgerScopeFilter(jobId: 'job-42'),
          )
          .totalCents,
      1250,
    );
    expect(
      ledger
          .summaryForRange(
            range,
            scope: const ExpenseLedgerScopeFilter(vehicleId: 'truck'),
          )
          .totalCents,
      800,
    );
  });

  test('cloud receipt payload preserves privacy-safe historical context', () {
    final draft = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
      orgId: 'org-1',
      uid: 'owner-1',
      deviceId: 'device-1',
      nowUtc: DateTime.utc(2026, 7, 14),
      receipt: ExpenseReceiptRecord(
        id: 'EXP-cloud-context',
        receiptDate: DateTime(2026, 7, 14),
        contextSnapshot: context,
        lines: const [],
      ),
    );

    final cloudContext = draft.data['context'] as Map<String, Object?>;
    expect(cloudContext['workProfileName'], 'Evening Delivery');
    expect(cloudContext['vehicleLabel'], 'Cargo Van');
    expect(cloudContext['jobId'], 'job-42');
  });
}
