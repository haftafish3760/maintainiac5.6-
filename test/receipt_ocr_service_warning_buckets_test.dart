import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('ocr diagnostics separates long receipt overlap warning task buckets', () {
    const result = ReceiptOcrResult(
      rawText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
      parserText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'Ignored 2 repeated receipt lines for app-assisted fill. Original receipt text was kept; review line items before saving.',
        'Found 1 possible overlapping receipt line. Nothing was changed automatically; review line items before saving.',
        'Found 1 receipt section break with no repeated receipt text between sections. Possible missing receipt section; check photo order and line items before saving.',
      ],
    );

    final diagnostics = result.diagnostics;

    expect(
      diagnostics.countForWarningKind(ReceiptOcrWarningKind.duplicateText),
      1,
    );
    expect(
      diagnostics.countForWarningKind(ReceiptOcrWarningKind.probableOverlap),
      1,
    );
    expect(
      diagnostics.countForWarningKind(ReceiptOcrWarningKind.sectionGap),
      1,
    );
    expect(diagnostics.parserTaskCounts['long_receipt_duplicate_text'], 1);
    expect(diagnostics.parserTaskCounts['long_receipt_probable_overlap'], 1);
    expect(diagnostics.parserTaskCounts['long_receipt_section_gap'], 1);
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('parser task buckets ready'),
    );
  });

  test('ocr diagnostics separates photo readability warning task buckets', () {
    const result = ReceiptOcrResult(
      rawText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
''',
      parserText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'No readable receipt text was found.',
        'Receipt photo quality warning: item text is too small. Add another closer photo instead of squeezing a long receipt into one shot.',
        'Receipt proof copy is small for section 1. OCR used the prepared source first, but review the saved proof image before saving.',
        'Receipt photo assistance failed for one photo.',
      ],
    );

    final diagnostics = result.diagnostics;

    expect(
      diagnostics.countForWarningKind(ReceiptOcrWarningKind.noReadableText),
      1,
    );
    expect(
      diagnostics.countForWarningKind(ReceiptOcrWarningKind.photoQuality),
      2,
    );
    expect(
      diagnostics.countForWarningKind(ReceiptOcrWarningKind.photoReadFailure),
      1,
    );
    expect(diagnostics.parserTaskCounts['ocr_no_readable_text'], 1);
    expect(diagnostics.parserTaskCounts['photo_tiny_text_review'], 1);
    expect(diagnostics.parserTaskCounts['photo_small_proof_review'], 1);
    expect(diagnostics.parserTaskCounts['photo_read_failed'], 1);
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('parser task buckets ready'),
    );
  });
}
