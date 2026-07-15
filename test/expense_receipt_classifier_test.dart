import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_classifier.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('classifies fuel receipt with high confidence', () {
    final result = ExpenseReceiptClassifier.classifyText('''
SHEETZ
Pump 07
Regular Unleaded 12.250 GAL
Price/Gal 3.459
Total 42.37
''');

    expect(result.category, 'Fuel');
    expect(result.title, 'Fuel Receipt');
    expect(result.confidence, greaterThanOrEqualTo(.84));
    expect(result.confidenceLabel, 'High');
  });

  test('classifies cell phone receipt separately from generic expense', () {
    final result = ExpenseReceiptClassifier.classifyText('''
Verizon Wireless
Monthly phone service
Data plan
Total 86.42
''');

    expect(result.category, 'Cell Phone');
    expect(result.title, 'Cell Phone Receipt');
    expect(result.confidence, greaterThan(.70));
  });

  test(
    'separates repair from maintenance when receipt language is specific',
    () {
      final repair = ExpenseReceiptClassifier.classifyText('''
ADVANCE AUTO PARTS
Brake caliper
Core charge
Total 154.21
''');
      final maintenance = ExpenseReceiptClassifier.classifyText('''
TAKE 5 OIL CHANGE
Full synthetic oil change
Oil filter
Total 84.98
''');

      expect(repair.category, 'Repair');
      expect(repair.detail, contains('overlap'));
      expect(maintenance.category, 'Maintenance');
      expect(maintenance.title, 'Maintenance Receipt');
    },
  );

  test('classifies materials receipts for inventory review', () {
    final result = ExpenseReceiptClassifier.classifyText('''
THE HOME DEPOT
1/2 IN COPPER COUPLING
ROMEX 12/2 W/G
PVC PIPE
Total 51.74
''');

    expect(result.category, 'Materials');
    expect(result.title, 'Materials / Inventory Receipt');
    expect(result.detail, contains('inventory'));
  });

  test('leaves closely competing receipt categories for user review', () {
    final result = ExpenseReceiptClassifier.classifyText('''
PUMP 07
Diesel 12 GAL
THE HOME DEPOT
MATERIALS
PVC PIPE
TOTAL 51.74
''');

    expect(result.kind, ExpenseReceiptClassificationKind.ambiguous);
    expect(result.category, isNull);
    expect(result.title, 'Receipt Needs Category Review');
  });

  test('generic shared PDF falls back to receipt review', () {
    final result = ExpenseReceiptClassifier.classifySharedReceipt(
      attachments: [_pdfAttachment()],
      importedText: '',
      messages: const [],
    );

    expect(result.kind, ExpenseReceiptClassificationKind.expenseReceipt);
    expect(result.title, 'Receipt / Expense');
    expect(result.confidenceLabel, 'Low');
  });

  test('shared PDF document signals influence destination suggestion', () {
    final receipt = ExpenseReceiptClassifier.classifySharedReceipt(
      attachments: [
        _pdfAttachment(documentSignals: const ['subtotal', 'tax', 'total']),
      ],
      importedText: '',
      messages: const [],
    );
    final warranty = ExpenseReceiptClassifier.classifySharedReceipt(
      attachments: [
        _pdfAttachment(documentSignals: const ['warranty', 'manual', 'terms']),
      ],
      importedText: '',
      messages: const [],
    );

    expect(receipt.kind, ExpenseReceiptClassificationKind.expenseReceipt);
    expect(receipt.confidence, greaterThan(.45));
    expect(warranty.kind, ExpenseReceiptClassificationKind.otherDocument);
    expect(warranty.category, isNull);
  });

  test('non receipt document stays proof-oriented', () {
    final result = ExpenseReceiptClassifier.classifyText('''
Warranty policy manual
Terms and certificate
''');

    expect(result.kind, ExpenseReceiptClassificationKind.otherDocument);
    expect(result.category, isNull);
    expect(result.title, 'Other Document');
  });
}

ReceiptAttachmentRecord _pdfAttachment({
  List<String> documentSignals = const [],
}) {
  return ReceiptAttachmentRecord(
    id: 'shared-pdf',
    path: '/tmp/shared.pdf',
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime(2026, 6, 14),
    displayName: 'shared.pdf',
    mimeType: 'application/pdf',
    documentSignals: documentSignals,
  );
}
