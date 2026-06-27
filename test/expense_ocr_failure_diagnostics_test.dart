import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ocr_failure_diagnostics.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  group('ExpenseOcrFailureDiagnostics', () {
    test('uses photo quality as the confirmed OCR failure cause', () {
      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(
          source: ReceiptProcessingSource.photo,
          warnings: const [
            'Receipt photo quality needs review: image is blurry.',
            'No readable receipt text was found.',
          ],
        ),
      );

      expect(diagnostic.workflowStep, ExpenseWorkflowStep.receiptOcr);
      expect(diagnostic.failedAt, 'during_photo_ocr_read');
      expect(diagnostic.confirmedCause, 'receipt_photo_quality_needs_review');
      expect(diagnostic.causeStatus, ExpenseFailureCauseStatus.confirmed);
      expect(diagnostic.evidence, contains('warning_photoQuality'));
      expect(diagnostic.evidence, contains('source_photo'));
    });

    test('uses PDF safety as a stronger cause than unreadable text', () {
      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(
          source: ReceiptProcessingSource.pdf,
          warnings: const [
            'This PDF contains embedded JavaScript and cannot be read safely.',
            'No readable receipt text was found.',
          ],
        ),
      );

      expect(diagnostic.failedAt, 'during_pdf_ocr_read');
      expect(diagnostic.confirmedCause, 'pdf_safety_blocked');
      expect(diagnostic.evidence, contains('warning_pdfSafety'));
    });

    test(
      'falls back to no readable text when OCR gives no better evidence',
      () {
        final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
          _ocrResult(source: ReceiptProcessingSource.photo),
        );

        expect(diagnostic.failedAt, 'after_attachment_read_before_parser');
        expect(diagnostic.confirmedCause, 'no_readable_text');
        expect(diagnostic.evidence, contains('warning_none'));
      },
    );

    test('uses section gap when receipt photos may be missing a section', () {
      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(
          source: ReceiptProcessingSource.photo,
          warnings: const [
            'Found 1 receipt section break with no repeated receipt text between sections. Possible missing receipt section; check photo order and line items before saving.',
          ],
        ),
      );

      expect(diagnostic.confirmedCause, 'possible_missing_receipt_section');
      expect(diagnostic.failedAt, 'after_attachment_read_before_parser');
      expect(diagnostic.evidence, contains('warning_sectionGap'));
    });
  });
}

ReceiptOcrResult _ocrResult({
  required ReceiptProcessingSource source,
  List<String> warnings = const [],
}) {
  return ReceiptOcrResult(
    rawText: '',
    parserText: '',
    textByAttachmentId: const {},
    source: source,
    stats: const ReceiptOcrReadStats(photosRead: 1),
    warnings: warnings,
  );
}
