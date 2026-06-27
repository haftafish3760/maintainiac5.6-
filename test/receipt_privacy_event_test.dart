import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'OCR privacy event keeps warning categories but no receipt text',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: 'LOWES HOME IMPROVEMENT\nPVC GLUE 7.99',
            ),
            _textAttachment(id: 'bottom', text: 'PVC GLUE 7.99\nTOTAL 7.99'),
          ]);

      final event = PrivacySafeReceiptEvent.fromOcrResult(
        result: result,
        featureArea: 'materials inventory',
        capability: const ReceiptDeviceCapability.highCapacity(),
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(map['event'], PrivacySafeReceiptEventType.receiptOcrReview.name);
      expect(map['featureArea'], 'materials_inventory');
      expect(map['capabilityTier'], ReceiptCapabilityTier.heavyweight.name);
      expect(map['warningKinds'], [ReceiptOcrWarningKind.duplicateText.name]);
      expect(map['rawLineCount'], 4);
      expect(map['parserLineCount'], 3);
      expect(map['hadDuplicateOrOverlapText'], isTrue);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('pvc')));
      expect(encoded, isNot(contains('7.99')));
    },
  );

  test(
    'parser privacy event reports counts without merchant items or prices',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
COPPER ELBOW 7.48
Subtotal 14.46
Tax 1.01
Total 15.47
''', parserDepth: ReceiptParserDepth.lineItems);

      final event = PrivacySafeReceiptEvent.fromParseResult(
        result: parsed,
        featureArea: 'expenses',
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(
        map['event'],
        PrivacySafeReceiptEventType.inventoryCatalogMatchWeak.name,
      );
      expect(map['featureArea'], 'expenses');
      expect(map['parserDepth'], ReceiptParserDepth.lineItems.name);
      expect(map['parseQuality'], isIn(['high', 'medium', 'low']));
      expect(map['parserTrust'], isA<String>());
      expect(map['totalsMathStatus'], 'matched');
      expect(map['explicitTotalsComplete'], isTrue);
      expect(map['taxMathReconciled'], isTrue);
      expect(map['needsHeavyReview'], isTrue);
      expect(map['detectedLineCount'], greaterThanOrEqualTo(2));
      expect(map['materialLineCount'], greaterThanOrEqualTo(1));
      expect(map['unmatchedMaterialLineCount'], greaterThanOrEqualTo(1));
      expect(encoded, isNot(contains('lowe')));
      expect(encoded, isNot(contains('wood')));
      expect(encoded, isNot(contains('screws')));
      expect(encoded, isNot(contains('copper')));
      expect(encoded, isNot(contains('15.47')));
    },
  );

  test('parser privacy event reports total mismatch without amounts', () {
    final parsed = parseExpenseReceiptText('''
PRIVATE STORE
06/12/2026
SERVICE ITEM 10.00
Total 99.99
''');

    final event = PrivacySafeReceiptEvent.fromParseResult(result: parsed);
    final encoded = event.toMap().toString().toLowerCase();

    expect(event.type, PrivacySafeReceiptEventType.receiptTotalsMismatch);
    expect(encoded, isNot(contains('private store')));
    expect(encoded, isNot(contains('service item')));
    expect(encoded, isNot(contains('99.99')));
    expect(encoded, isNot(contains('10.00')));
  });

  test('parser privacy event reports tax math review without amounts', () {
    final parsed = parseExpenseReceiptText('''
PRIVATE STORE
06/12/2026
SERVICE ITEM 10.00
Subtotal 10.00
Tax 0.80
Total 12.80
''');

    final event = PrivacySafeReceiptEvent.fromParseResult(result: parsed);
    final map = event.toMap();
    final encoded = map.toString().toLowerCase();

    expect(event.type, PrivacySafeReceiptEventType.receiptTotalsMismatch);
    expect(map['explicitTotalsComplete'], isTrue);
    expect(map['taxMathReconciled'], isFalse);
    expect(map['needsHeavyReview'], isTrue);
    expect(map['parserTrust'], 'needs_receipt_math_review');
    expect(map['totalsMathStatus'], 'mismatch');
    expect(encoded, isNot(contains('private store')));
    expect(encoded, isNot(contains('service item')));
    expect(encoded, isNot(contains('12.80')));
    expect(encoded, isNot(contains('10.00')));
    expect(encoded, isNot(contains('0.80')));
  });

  test(
    'camera capture privacy event reports buckets without image content',
    () {
      const quality = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 15,
        brightness: 142,
        contrast: 38,
        cropScore: .76,
        textBandScore: 12,
        isLikelyReadable: true,
      );

      final event = PrivacySafeReceiptEvent.fromCapture(
        type: PrivacySafeReceiptEventType.receiptCaptureCompleted,
        featureArea: 'expense receipts',
        capability: const ReceiptDeviceCapability.standard(),
        captureMode: 'assisted_auto',
        captureOutcome: 'completed',
        quality: quality,
        photoSectionCount: 2,
        retakeCount: 1,
        captureDurationMs: 3200,
      );
      final map = event.toMap();
      final encoded = map.toString().toLowerCase();

      expect(
        map['event'],
        PrivacySafeReceiptEventType.receiptCaptureCompleted.name,
      );
      expect(map['featureArea'], 'expense_receipts');
      expect(map['capabilityTier'], ReceiptCapabilityTier.medium.name);
      expect(map['captureMode'], 'assisted_auto');
      expect(map['captureOutcome'], 'completed');
      expect(map['focusBucket'], 'sharp');
      expect(map['readabilityBucket'], 'high');
      expect(map['photoSectionCount'], 2);
      expect(map['retakeCount'], 1);
      expect(map['captureDurationMs'], 3200);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('/tmp')));
      expect(encoded, isNot(contains('.jpg')));
    },
  );
}

ReceiptAttachmentRecord _textAttachment({
  required String id,
  required String text,
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '',
    kind: ReceiptAttachmentKind.emailText,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 23),
    importedText: text,
  );
}
