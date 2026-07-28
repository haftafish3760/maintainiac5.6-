// Regression coverage for conservative Active Day ledger attribution.
// Protects paid-income timing, vehicle/profile boundaries, and fuel totals.
// It does not test storage, navigation, or any GPS distance behavior.
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_financial_snapshot.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';

final day = DateTime(2026, 7, 28);

void main() {
  test(
    'counts only payments received today for the active vehicle and profile',
    () {
      final snapshot = ActiveWorkdayFinancialSnapshot.forSession(
        day: day,
        vehicleId: 'truck-1',
        workProfileId: 'gig',
        invoices: [
          _invoice(
            payments: [
              InvoicePaymentRecord(id: 'today', amount: 25.50, paidAt: day),
              InvoicePaymentRecord(
                id: 'yesterday',
                amount: 14,
                paidAt: DateTime(2026, 7, 27),
              ),
            ],
          ),
          _invoice(
            vehicleId: 'truck-2',
            payments: [
              InvoicePaymentRecord(id: 'wrong', amount: 99, paidAt: day),
            ],
          ),
          _invoice(
            profileId: '',
            vehicleId: '',
            payments: [
              InvoicePaymentRecord(id: 'unscoped', amount: 77, paidAt: day),
            ],
          ),
        ],
        expenses: const [],
      );

      expect(snapshot.receivedCents, 2550);
    },
  );

  test(
    'uses only saved attributed business expenses and fuel line portions',
    () {
      final snapshot = ActiveWorkdayFinancialSnapshot.forSession(
        day: day,
        vehicleId: 'truck-1',
        workProfileId: 'gig',
        invoices: const [],
        expenses: [
          _expense(
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'fuel',
                description: 'Gas',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 1,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
              ),
              ExpenseReceiptLineRecord(
                id: 'personal',
                description: 'Snack',
                category: 'Food',
                use: ExpenseLineUse.personal,
                quantity: 1,
                unitsPerPackage: 1,
                unit: 'each',
                subtotal: 5,
              ),
            ],
          ),
          _expense(
            vehicleId: 'truck-2',
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'other',
                description: 'Gas',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 1,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 60,
              ),
            ],
          ),
        ],
      );

      expect(snapshot.spentCents, 4000);
      expect(snapshot.fuelCents, 4000);
      expect(snapshot.expenseReceiptCount, 1);
    },
  );

  test('does not count estimates, inactive receipts, or conflicting scope', () {
    final snapshot = ActiveWorkdayFinancialSnapshot.forSession(
      day: day,
      vehicleId: 'truck-1',
      workProfileId: 'gig',
      invoices: [
        _invoice(
          documentType: InvoiceDocumentType.estimate,
          payments: [
            InvoicePaymentRecord(id: 'estimate', amount: 100, paidAt: day),
          ],
        ),
        _invoice(
          profileId: 'contractor',
          payments: [
            InvoicePaymentRecord(id: 'profile', amount: 100, paidAt: day),
          ],
        ),
      ],
      expenses: [
        _expense(
          recordState: MaintainiacRecordState.deleted,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'deleted',
              description: 'Fuel',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'gallon',
              subtotal: 55,
            ),
          ],
        ),
      ],
    );

    expect(snapshot.receivedCents, 0);
    expect(snapshot.spentCents, 0);
  });
}

InvoiceRecord _invoice({
  String vehicleId = 'truck-1',
  String profileId = 'gig',
  InvoiceDocumentType documentType = InvoiceDocumentType.invoice,
  List<InvoicePaymentRecord> payments = const [],
}) => InvoiceRecord(
  id: 'invoice-$vehicleId-$profileId-${payments.length}',
  documentType: documentType,
  invoiceNumber: '1',
  numberMode: InvoiceNumberMode.automatic,
  status: InvoiceRecordStatus.paid,
  issueDate: day,
  vehicleId: vehicleId,
  profileId: profileId,
  payments: payments,
  meta: InvoiceSyncMetadata(createdAt: day, updatedAt: day),
);

ExpenseReceiptRecord _expense({
  String vehicleId = 'truck-1',
  String workProfileId = 'gig',
  List<ExpenseReceiptLineRecord> lines = const [],
  MaintainiacRecordState recordState = MaintainiacRecordState.active,
}) => ExpenseReceiptRecord(
  id: 'expense-$vehicleId-$workProfileId-${lines.length}',
  receiptDate: day,
  vehicleId: vehicleId,
  workProfileId: workProfileId,
  lines: lines,
  recordState: recordState,
);
