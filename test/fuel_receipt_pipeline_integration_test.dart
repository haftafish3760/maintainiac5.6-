import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_firestore_documents.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/reports/expense_recap_models.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  test(
    'keeps parsed Spanish diesel fills accurate through recap and export',
    () async {
      final ledger = ExpenseLedgerController.memory();
      final receipts = [
        _receipt(
          id: 'start',
          date: DateTime(2026, 7, 1),
          text: '''
ESTACION
DIESEL 10.000 GAL @ 4.000 40.00
LLENO
TOTAL 40.00
ODOMETRO 10000
''',
        ),
        _receipt(
          id: 'partial',
          date: DateTime(2026, 7, 5),
          text: '''
SERVICENTRO
GASOIL 5.000 GAL @ 4.200 21.00
CARGA PARCIAL
TOTAL 21.00
ODOMETRO 10100
''',
        ),
        _receipt(
          id: 'finish',
          date: DateTime(2026, 7, 10),
          text: '''
ESTACION
DIESEL 12.000 GAL @ 4.500 54.00
LLENO
TOTAL 54.00
ODOMETRO 10300
''',
        ),
      ];
      for (final receipt in receipts) {
        await ledger.saveReceipt(receipt);
      }

      final report = ExpenseRecapReport.fromLedger(
        ledger,
        ExpenseDateRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 31),
        ),
        vehicleId: 'truck_1',
      );
      expect(report.fuelExpense, 115);
      expect(report.completedLiquidFillMiles, 300);
      expect(report.completedLiquidFillGallons, 17);
      expect(report.averageMpg, closeTo(17.647, .001));
      expect(report.fuelCostPerMile, closeTo(.3833, .0001));

      final document = ExpenseFirestoreDocumentBuilder.expenseReceiptDocument(
        orgId: 'org_1',
        uid: 'user_1',
        deviceId: 'device_1',
        receipt: receipts.last,
        nowUtc: DateTime.utc(2026, 7, 10),
      );
      final line =
          (document.data['lines'] as List).single as Map<String, Object?>;
      expect(line['fuelType'], 'diesel');
      expect(line['fillType'], 'full_fill-up');
      expect(line['odometerReading'], 10300);
      expect(document.data.toString(), isNot(contains('DIESEL 12.000')));
      MaintainiacFirestoreUploadPolicy.validateDraft(document);
    },
  );
}

ExpenseReceiptRecord _receipt({
  required String id,
  required DateTime date,
  required String text,
}) {
  final parsed = parseExpenseReceiptText(text, targetCategory: 'Fuel');
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: date,
    merchantName: parsed.merchantName ?? 'Fuel station',
    vehicleId: 'truck_1',
    lines: parsed.lines,
  );
}
