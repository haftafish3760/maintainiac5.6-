import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('ocr result promotes strongest warning into user action copy', () {
    const result = ReceiptOcrResult(
      rawText: '',
      parserText: '',
      textByAttachmentId: {},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'Repeated receipt text was ignored.',
        'No readable receipt text was found.',
      ],
    );

    expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.noReadableText);
    expect(result.strongestActionMessage, contains('No readable text'));
    expect(result.strongestActionMessage, contains('Retake the photo'));
    expect(
      result.reviewMessage(successMessage: 'Receipt photo was read.'),
      contains('No readable text'),
    );
    expect(
      result.reviewMessage(successMessage: 'Receipt photo was read.'),
      isNot(contains('Repeated receipt text was ignored.')),
    );
  });

  test('ocr result explains warning review burden before saving', () {
    const result = ReceiptOcrResult(
      rawText: 'LOWES\nTOTAL 3.24',
      parserText: 'LOWES\nTOTAL 3.24',
      textByAttachmentId: {'photo-1': 'LOWES\nTOTAL 3.24'},
      source: ReceiptProcessingSource.photo,
      stats: ReceiptOcrReadStats(photosRead: 1),
      warnings: ['Repeated receipt text was ignored.'],
    );

    final message = result.reviewMessage(
      successMessage: 'Receipt photo was read.',
    );

    expect(result.hasText, isTrue);
    expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.duplicateText);
    expect(message, contains('Receipt photo was read.'));
    expect(message, contains('Read 1 receipt photo.'));
    expect(message, contains('Duplicate lines ignored.'));
    expect(
      message,
      contains('Compare the filled form with the receipt proof before saving.'),
    );
  });

  test('ocr warnings target the exact receipt area to review', () {
    final overlap = ReceiptOcrWarning.fromMessage(
      'Repeated receipt text was ignored.',
    );
    final missingSection = ReceiptOcrWarning.fromMessage(
      'Possible missing receipt section between photos.',
    );
    final photoQuality = ReceiptOcrWarning.fromMessage(
      'Receipt photo quality warning: bottom section may be soft.',
    );

    expect(overlap.reviewTargetLabel, 'Check long receipt overlap');
    expect(
      overlap.reviewTargetInstruction,
      contains('same charge was not counted twice'),
    );
    expect(missingSection.reviewTargetLabel, 'Check missing receipt section');
    expect(
      missingSection.reviewTargetInstruction,
      contains('receipt photos from top to bottom'),
    );
    expect(photoQuality.reviewTargetLabel, 'Check photo proof');
    expect(
      photoQuality.reviewTargetInstruction,
      contains('store, date, total, tax, and item prices'),
    );
  });

  test('ocr warning priority puts blockers before review warnings', () {
    const result = ReceiptOcrResult(
      rawText: 'LOWES\nTOTAL 3.24',
      parserText: 'LOWES\nTOTAL 3.24',
      textByAttachmentId: {'photo-1': 'LOWES\nTOTAL 3.24'},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'Repeated receipt text was ignored.',
        'Receipt photo quality warning: bottom section may be soft.',
        'PDF receipt assistance could not find text in one PDF.',
      ],
    );

    expect(
      result.structuredWarnings.first.kind,
      ReceiptOcrWarningKind.duplicateText,
    );
    expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.pdfReadFailure);
    expect(
      result.diagnostics.primaryWarningKind,
      ReceiptOcrWarningKind.pdfReadFailure.name,
    );
    expect(result.diagnostics.primaryWarningLabel, 'PDF read failed');
    expect(result.diagnostics.primaryWarningTargetLabel, 'Check receipt PDF');
    expect(
      result.diagnostics.primaryWarningTargetInstruction,
      contains('Attach a clearer PDF'),
    );
    expect(result.prioritizedWarnings.map((warning) => warning.kind), [
      ReceiptOcrWarningKind.pdfReadFailure,
      ReceiptOcrWarningKind.duplicateText,
      ReceiptOcrWarningKind.photoQuality,
    ]);
  });
}
