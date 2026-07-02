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
      expect(diagnostic.evidence, contains('recovery_retake_or_review_photo'));
      expect(diagnostic.evidence, contains('target_receipt_photo'));
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
      expect(diagnostic.evidence, contains('recovery_attach_safe_pdf'));
      expect(diagnostic.evidence, contains('target_receipt_pdf'));
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
        expect(
          diagnostic.evidence,
          contains('recovery_retake_photo_or_add_section'),
        );
        expect(diagnostic.evidence, contains('target_receipt_photo'));
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
      expect(diagnostic.evidence, contains('recovery_add_missing_section'));
      expect(diagnostic.evidence, contains('target_receipt_sections'));
    });

    test('uses prioritized warnings instead of raw warning order', () {
      final result = _ocrResult(
        source: ReceiptProcessingSource.pdf,
        warnings: const [
          'Repeated receipt text was ignored.',
          'PDF receipt assistance could not find text in one PDF.',
        ],
      );

      expect(
        result.structuredWarnings.first.kind,
        ReceiptOcrWarningKind.duplicateText,
      );
      expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.pdfReadFailure);

      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(result);

      expect(diagnostic.failedAt, 'during_pdf_ocr_read');
      expect(diagnostic.confirmedCause, 'pdf_read_failed');
      expect(diagnostic.evidence, contains('warning_pdfReadFailure'));
      expect(diagnostic.evidence, contains('source_pdf'));
      expect(
        diagnostic.evidence,
        contains('recovery_scan_receipt_with_photos'),
      );
      expect(diagnostic.evidence, contains('target_receipt_pdf'));
    });

    test('photo read failures outrank review-only photo warnings', () {
      final result = _ocrResult(
        source: ReceiptProcessingSource.photo,
        warnings: const [
          'Receipt photo quality needs review: bottom section may be soft.',
          'Receipt photo assistance could not find text in one photo.',
          'Repeated receipt text was ignored.',
        ],
      );

      expect(
        result.structuredWarnings.first.kind,
        ReceiptOcrWarningKind.photoQuality,
      );
      expect(
        result.primaryWarning?.kind,
        ReceiptOcrWarningKind.photoReadFailure,
      );

      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(result);

      expect(diagnostic.failedAt, 'during_photo_ocr_read');
      expect(diagnostic.confirmedCause, 'receipt_photo_read_failed');
      expect(diagnostic.evidence, contains('warning_photoReadFailure'));
      expect(diagnostic.evidence, contains('recovery_retake_photo'));
      expect(diagnostic.evidence, contains('target_receipt_photo'));
    });

    test('uses source-specific recovery when warning kind is generic', () {
      final pdfDiagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(source: ReceiptProcessingSource.pdf),
      );
      final textDiagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(source: ReceiptProcessingSource.importedText),
      );
      final mixedDiagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(source: ReceiptProcessingSource.mixed),
      );

      expect(
        pdfDiagnostic.evidence,
        contains('recovery_scan_receipt_with_photos'),
      );
      expect(pdfDiagnostic.evidence, contains('target_receipt_pdf'));
      expect(textDiagnostic.evidence, contains('recovery_paste_cleaner_text'));
      expect(textDiagnostic.evidence, contains('target_receipt_text'));
      expect(
        mixedDiagnostic.evidence,
        contains('recovery_choose_clearest_source'),
      );
      expect(mixedDiagnostic.evidence, contains('target_receipt_sources'));
    });

    test('includes prepared source-first evidence for OCR failures', () {
      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(
          source: ReceiptProcessingSource.photo,
          warnings: const ['No readable receipt text was found.'],
          sourceHandoffSummary: ReceiptOcrSourceHandoffSummary.fromAttachments([
            ReceiptAttachmentRecord(
              id: 'prepared-source',
              path: '/tmp/prepared-source.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 30),
              documentSignals: const [
                'ocr_source_first_prepared_receipt_source_before_saved_proof',
                'ocr_source_first_outcome_prepared_source_ready',
              ],
            ),
          ]),
        ),
      );

      expect(
        diagnostic.evidence,
        contains(
          'sourceFirst_ocr_source_first_prepared_receipt_source_before_saved_proof',
        ),
      );
      expect(diagnostic.evidence, contains('target_receipt_photo'));
    });

    test('includes saved-proof fallback evidence for review-required OCR', () {
      final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
        _ocrResult(
          source: ReceiptProcessingSource.photo,
          warnings: const [
            'Receipt photo assistance could not find text in one photo.',
          ],
          sourceHandoffSummary: ReceiptOcrSourceHandoffSummary.fromAttachments([
            ReceiptAttachmentRecord(
              id: 'fallback-source',
              path: '/tmp/fallback-source.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.maximum,
              createdAt: DateTime(2026, 6, 30),
              documentSignals: const [
                'ocr_source_first_saved_proof_fallback_review_required',
                'ocr_source_first_outcome_fallback_saved_proof_review_required',
              ],
              riskFlags: const [
                'ocr_source_first_saved_proof_fallback_review_required',
              ],
            ),
          ]),
        ),
      );

      expect(diagnostic.confirmedCause, 'receipt_photo_read_failed');
      expect(
        diagnostic.evidence,
        contains(
          'sourceFirst_ocr_source_first_saved_proof_fallback_review_required',
        ),
      );
      expect(diagnostic.evidence, contains('recovery_retake_photo'));
    });
  });
}

ReceiptOcrResult _ocrResult({
  required ReceiptProcessingSource source,
  List<String> warnings = const [],
  ReceiptOcrSourceHandoffSummary sourceHandoffSummary =
      const ReceiptOcrSourceHandoffSummary.empty(),
}) {
  return ReceiptOcrResult(
    rawText: '',
    parserText: '',
    textByAttachmentId: const {},
    source: source,
    stats: const ReceiptOcrReadStats(photosRead: 1),
    sourceHandoffSummary: sourceHandoffSummary,
    warnings: warnings,
  );
}
