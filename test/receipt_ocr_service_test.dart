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

  test(
    'ocr result carries accepted photo handoff signals without receipt content',
    () async {
      final result = await const ReceiptOcrService().recognizeTextFromAttachments([
        ReceiptAttachmentRecord(
          id: 'handoff-text',
          path: '',
          kind: ReceiptAttachmentKind.emailText,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 29),
          importedText: 'LOWES\nTOTAL 3.24',
          documentSignals: const [
            'receipt_ocr_source_photo',
            'receipt_handoff_ready_for_receipt_review',
            'receipt_handoff_warning_saved_photo_dimmer_than_preview',
            'receipt_handoff_stitch_stitched',
            'stitched_ocr_source',
            'stitch_overlap_all_pairs_have_overlap_evidence',
            'stitch_source_original_sections_preserved_derived_stitched_ocr_artifact',
            'ocr_source_first_prepared_receipt_source_before_saved_proof',
            'ocr_source_first_outcome_prepared_source_ready',
            'scanner_decision_ocr_source_enhanced_selected',
            'native_capture_source_maintainiac_native_camera',
            'native_capture_surface_maintainiac_native_android',
            'native_capture_surface_verified_maintainiac_custom_surface_verified',
            'native_capture_identity_maintainiac_in_app_receipt_camera',
            'receipt_coverage_status_likelycomplete',
            'receipt_coverage_framing_ok_readable',
            'receipt_coverage_evidence_single_signal_or_manual_coverage_review',
            'receipt_coverage_contract_standard_receipt_section_review',
          ],
          riskFlags: const ['ocr_source_saved_photo_dimmer_than_preview'],
        ),
      ]);

      final summary = result.sourceHandoffSummary;
      final diagnostics = result.diagnostics;

      expect(summary.status, 'stitched_ocr_source');
      expect(summary.handoffSignalCounts, {
        'receipt_handoff_ready_for_receipt_review': 1,
        'receipt_handoff_warning_saved_photo_dimmer_than_preview': 1,
        'receipt_handoff_stitch_stitched': 1,
      });
      expect(summary.handoffWarningProfileCounts, {
        'receipt_handoff_warning_saved_photo_dimmer_than_preview': 1,
      });
      expect(
        summary.warningProfileStatus,
        'receipt_handoff_warning_saved_photo_dimmer_than_preview',
      );
      expect(summary.reviewCueStatus, 'saved_photo_dimmer_than_preview');
      expect(summary.sourceFirstDecisionCounts, {
        'ocr_source_first_prepared_receipt_source_before_saved_proof': 1,
      });
      expect(summary.sourceFirstOutcomeCounts, {
        'ocr_source_first_outcome_prepared_source_ready': 1,
      });
      expect(
        summary.sourceFirstDecisionStatus,
        'ocr_source_first_prepared_receipt_source_before_saved_proof',
      );
      expect(diagnostics.ocrSourceHandoffWarningProfileCounts, {
        'receipt_handoff_warning_saved_photo_dimmer_than_preview': 1,
      });
      expect(summary.stitchSignalCounts, {
        'receipt_handoff_stitch_stitched': 1,
        'stitched_ocr_source': 1,
        'stitch_overlap_all_pairs_have_overlap_evidence': 1,
        'stitch_source_original_sections_preserved_derived_stitched_ocr_artifact':
            1,
      });
      expect(summary.scannerDecisionCounts, {
        'scanner_decision_ocr_source_enhanced_selected': 1,
      });
      expect(summary.captureSourceSignalCounts, {
        'native_capture_source_maintainiac_native_camera': 1,
        'native_capture_surface_maintainiac_native_android': 1,
        'native_capture_surface_verified_maintainiac_custom_surface_verified':
            1,
        'native_capture_identity_maintainiac_in_app_receipt_camera': 1,
      });
      expect(summary.coverageSignalCounts, {
        'receipt_coverage_status_likelycomplete': 1,
        'receipt_coverage_framing_ok_readable': 1,
        'receipt_coverage_evidence_single_signal_or_manual_coverage_review': 1,
        'receipt_coverage_contract_standard_receipt_section_review': 1,
      });
      expect(diagnostics.ocrSourceCoverageSignalCounts, {
        'receipt_coverage_status_likelycomplete': 1,
        'receipt_coverage_framing_ok_readable': 1,
        'receipt_coverage_evidence_single_signal_or_manual_coverage_review': 1,
        'receipt_coverage_contract_standard_receipt_section_review': 1,
      });
      expect(diagnostics.ocrSourceCaptureSourceSignalCounts, {
        'native_capture_source_maintainiac_native_camera': 1,
        'native_capture_surface_maintainiac_native_android': 1,
        'native_capture_surface_verified_maintainiac_custom_surface_verified':
            1,
        'native_capture_identity_maintainiac_in_app_receipt_camera': 1,
      });
      expect(summary.photoQualityRiskCounts, {
        'ocr_source_saved_photo_dimmer_than_preview': 1,
      });
      expect(diagnostics.ocrSourceHandoffStatus, 'stitched_ocr_source');
      expect(
        diagnostics.ocrSourceHandoffContract['schema'],
        'receipt_ocr_source_handoff_v1',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['warningProfileStatus'],
        'receipt_handoff_warning_saved_photo_dimmer_than_preview',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['reviewCueStatus'],
        'saved_photo_dimmer_than_preview',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['sourceQualityReviewStatus'],
        'saved_dark_exposure_review',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['sourceQualityReviewAction'],
        'retake_or_raise_brightness',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['sourceFirstDecisionStatus'],
        'ocr_source_first_prepared_receipt_source_before_saved_proof',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['captureSourceSignalCounts'],
        {
          'native_capture_source_maintainiac_native_camera': 1,
          'native_capture_surface_maintainiac_native_android': 1,
          'native_capture_surface_verified_maintainiac_custom_surface_verified':
              1,
          'native_capture_identity_maintainiac_in_app_receipt_camera': 1,
        },
      );
      expect(
        diagnostics.ocrSourceHandoffContract.toString().toLowerCase(),
        isNot(contains('lowes')),
      );
      expect(
        diagnostics.ocrSourceHandoffContract.toString(),
        isNot(contains('3.24')),
      );
    },
  );

  test('source handoff reports bottom saved-photo quality review', () {
    final summary = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'bottom-soft',
        path: '/tmp/bottom-soft.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 1),
        riskFlags: const [
          'ocr_source_saved_photo_bottom_soft',
          'ocr_source_action_check_bottom_or_retake',
        ],
      ),
    ]);

    expect(summary.status, 'scanner_prep_review_needed');
    expect(summary.sourceQualityReviewStatus, 'saved_bottom_quality_review');
    expect(summary.sourceQualityReviewAction, 'check_bottom_or_add_photo');
    expect(
      summary.privacySafeContract['sourceQualityReviewStatus'],
      'saved_bottom_quality_review',
    );
    expect(
      summary.privacySafeContract['sourceQualityReviewAction'],
      'check_bottom_or_add_photo',
    );
  });

  test('source handoff reports dark saved-photo exposure review', () {
    final summary = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'dark-proof',
        path: '/tmp/dark-proof.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 1),
        riskFlags: const [
          'ocr_source_saved_photo_darker_than_preview',
          'ocr_source_action_retake_with_more_light',
        ],
      ),
    ]);

    expect(summary.status, 'scanner_prep_review_needed');
    expect(summary.sourceQualityReviewStatus, 'saved_dark_exposure_review');
    expect(summary.sourceQualityReviewAction, 'retake_or_raise_brightness');
    expect(
      summary.privacySafeContract['sourceQualityReviewStatus'],
      'saved_dark_exposure_review',
    );
    expect(
      summary.privacySafeContract['sourceQualityReviewAction'],
      'retake_or_raise_brightness',
    );
  });

  test('source handoff reports glare saved-photo review', () {
    final summary = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'glare-proof',
        path: '/tmp/glare-proof.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 1),
        riskFlags: const [
          'ocr_source_saved_photo_glare_risk',
          'ocr_source_action_reduce_glare_or_retake',
        ],
      ),
    ]);

    expect(summary.status, 'scanner_prep_review_needed');
    expect(summary.sourceQualityReviewStatus, 'saved_glare_review');
    expect(summary.sourceQualityReviewAction, 'reduce_glare_or_retake');
    expect(
      summary.privacySafeContract['sourceQualityReviewStatus'],
      'saved_glare_review',
    );
    expect(
      summary.privacySafeContract['sourceQualityReviewAction'],
      'reduce_glare_or_retake',
    );
  });

  test('source handoff reports dirty lens saved-photo review', () {
    final summary = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'hazy-proof',
        path: '/tmp/hazy-proof.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 1),
        riskFlags: const [
          'ocr_source_saved_photo_dirty_lens_or_haze',
          'ocr_source_action_wipe_lens_or_retake',
        ],
      ),
    ]);

    expect(summary.status, 'scanner_prep_review_needed');
    expect(summary.sourceQualityReviewStatus, 'saved_hazy_lens_review');
    expect(summary.sourceQualityReviewAction, 'wipe_lens_or_retake');
    expect(
      summary.privacySafeContract['sourceQualityReviewStatus'],
      'saved_hazy_lens_review',
    );
    expect(
      summary.privacySafeContract['sourceQualityReviewAction'],
      'wipe_lens_or_retake',
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
}
