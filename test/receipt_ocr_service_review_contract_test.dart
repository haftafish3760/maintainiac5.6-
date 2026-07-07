import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_review_test_',
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

  test('source handoff reports backup capture review', () async {
    final serviceResult = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'backup-scan-proof',
            path: '',
            kind: ReceiptAttachmentKind.emailText,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 4),
            importedText: 'SUPPLY STORE\nTOTAL 14.20',
            riskFlags: const [
              'ocr_source_saved_photo_document_scanner_backup',
              'ocr_source_action_review_backup_scan_crop',
              'ocr_source_saved_photo_phone_camera_backup',
              'ocr_source_action_review_phone_backup_focus',
            ],
          ),
        ]);
    final summary = serviceResult.sourceHandoffSummary;

    expect(summary.status, 'scanner_prep_review_needed');
    expect(summary.sourceQualityReviewStatus, 'backup_capture_review');
    expect(
      summary.sourceQualityReviewAction,
      'check_backup_capture_crop_focus_totals',
    );
    expect(
      summary.privacySafeContract['sourceQualityReviewStatus'],
      'backup_capture_review',
    );
    expect(
      summary.privacySafeContract['sourceQualityReviewAction'],
      'check_backup_capture_crop_focus_totals',
    );
    expect(
      serviceResult.diagnostics.parserTaskCounts,
      containsPair('photo_backup_scan_crop_review', 1),
    );
    expect(
      serviceResult.diagnostics.parserTaskCounts,
      containsPair('photo_phone_backup_focus_review', 1),
    );
  });

  test('ocr service asks for a receipt photo before scanning', () async {
    final result = await const ReceiptOcrService().recognizeTextFromAttachments(
      const [],
    );

    expect(result.hasText, isFalse);
    expect(result.source, ReceiptProcessingSource.none);
    expect(result.processingSnapshot.stage, ReceiptProcessingStage.noSource);
    expect(result.stats.attachmentsRead, 0);
    expect(result.stats.attachmentsSkipped, 0);
    expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.blocked);
    expect(result.diagnostics.reviewSummaryLabel, contains('Blocked'));
    expect(result.diagnostics.textSummaryLabel, 'No readable text');
    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.noSource,
    );
    expect(result.structuredWarnings.single.isBlocking, isTrue);
    expect(result.structuredWarnings.single.label, 'No receipt attached');
    expect(
      result.structuredWarnings.single.actionLabel,
      contains('Attach a receipt'),
    );
    expect(result.diagnostics.hasBlockingWarnings, isTrue);
    expect(result.diagnostics.blockingWarningCount, 1);
    expect(result.diagnostics.warningSummaryLabel, '1 blocked OCR warning');
    expect(
      result.warnings.single,
      contains('Attach at least one receipt photo'),
    );
  });

  test(
    'source handoff requires review for invalid stitch OCR contract',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'stitch-contract-proof',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 7, 5),
              importedText: 'MARKET\nTOTAL 8.40',
              documentSignals: const [
                'receipt_ocr_source_photo',
                'receipt_handoff_ready_for_receipt_review',
                'receipt_handoff_stitch_stitched',
                'stitch_ocr_source_contract_stitched_ocr_source_path_mismatch',
                'stitch_ocr_source_contract_review_required',
              ],
              riskFlags: const [
                'ocr_source_stitch_contract_review_required',
                'ocr_source_stitch_contract_stitched_ocr_source_path_mismatch',
              ],
            ),
          ]);

      final summary = result.sourceHandoffSummary;

      expect(summary.status, 'stitch_contract_review_required');
      expect(
        summary.sourceReviewRiskStatus,
        'ocr_source_review_risk_stitch_ocr_source_contract_review_required',
      );
      expect(
        summary.sourceQualityReviewStatus,
        'stitch_contract_review_required',
      );
      expect(
        summary.sourceQualityReviewAction,
        'review_receipt_stitch_sources',
      );
      expect(
        summary.stitchSignalCounts,
        containsPair('stitch_ocr_source_contract_review_required', 1),
      );
      expect(
        summary.photoQualityRiskCounts,
        containsPair('ocr_source_stitch_contract_review_required', 1),
      );
    },
  );
}
