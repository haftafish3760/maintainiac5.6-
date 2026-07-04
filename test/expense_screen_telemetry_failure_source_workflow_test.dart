import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test(
    'summarizes OCR source handoff buckets for Command One without content',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = expenseTelemetryContextFixture();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrCompleted,
          context: context,
          metadata: const {
            'ocrSourceHandoffStatus': 'stitched_ocr_source',
            'ocrSourceHandoffSignalCounts': {
              'receipt_handoff_ready_for_receipt_review': 1,
            },
            'ocrSourceStitchSignalCounts': {'stitched_ocr_source': 1},
            'ocrSourceScannerDecisionCounts': {
              'scanner_decision_ocr_source_enhanced_selected': 1,
            },
            'ocrSourceCaptureSourceSignalCounts': {
              'native_capture_source_maintainiac_native_camera': 1,
            },
            'ocrSourcePhotoQualityRiskCounts': {
              'ocr_source_saved_photo_dimmer_than_preview': 1,
            },
            'ocrSourceQualityReviewStatus': 'saved_dark_exposure_review',
            'ocrSourceQualityReviewAction': 'retake_or_raise_brightness',
            'clientProofRedactionStatus': 'ready_for_client_proof',
            'clientProofVisibilityCounts': {
              'review_for_client_proof': 4,
              'redact_by_default': 2,
            },
            'selectedReceiptLinePurpose': 'client_proof',
            'selectedReceiptLineCount': 4,
            'excludedReceiptLineCount': 2,
            'clientProofReviewLineCount': 4,
            'redactedReceiptLineCount': 2,
            'clientProofRedactionPlanStatus': 'review_required',
            'clientProofVisibleLineCount': 0,
            'clientProofHiddenLineCount': 2,
            'clientProofPlanReviewLineCount': 4,
            'clientProofLayoutRedactionStatus': 'ignored_unknown_lines',
            'clientProofLayoutVisibleLineCount': 1,
            'clientProofLayoutHiddenLineCount': 4,
            'clientProofLayoutIgnoredLineCount': 2,
            'clientProofLayoutProtectedTypeCount': 2,
            'clientProofLayoutKeepsMerchantContext': true,
            'clientProofLayoutKeepsTotalsContext': false,
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserCompleted,
          context: context,
          metadata: const {
            'ocrSourceHandoffStatus': 'stitched_ocr_source',
            'ocrSourceHandoffSignalCounts': {
              'receipt_handoff_ready_for_receipt_review': 1,
            },
            'ocrSourceStitchSignalCounts': {'stitched_ocr_source': 1},
            'ocrSourceScannerDecisionCounts': {
              'scanner_decision_ocr_source_enhanced_selected': 1,
            },
            'ocrSourceCaptureSourceSignalCounts': {
              'native_capture_source_maintainiac_native_camera': 1,
            },
            'ocrSourcePhotoQualityRiskCounts': {
              'ocr_source_saved_photo_dimmer_than_preview': 1,
            },
            'ocrSourceQualityReviewStatus': 'saved_dark_exposure_review',
            'ocrSourceQualityReviewAction': 'retake_or_raise_brightness',
            'parserReviewRootCauseCode': 'camera_source_quality',
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserNeedsReview,
          context: context,
          metadata: const {
            'ocrSourceHandoffStatus': 'possible_partial_receipt',
            'ocrSourceHandoffSignalCounts': {
              'receipt_handoff_possible_partial_receipt': 1,
            },
            'ocrSourceStitchSignalCounts': {'multiple_ocr_sources_fallback': 1},
            'ocrSourceScannerDecisionCounts': {
              'scanner_decision_ocr_source_original_selected_quality_guard': 1,
            },
            'ocrSourceCaptureSourceSignalCounts': {
              'native_capture_source_phone_camera_backup': 1,
            },
            'ocrSourcePhotoQualityRiskCounts': {
              'ocr_source_saved_photo_soft_blur_risk': 1,
            },
            'ocrSourceQualityReviewStatus': 'saved_soft_blur_review',
            'ocrSourceQualityReviewAction': 'retake_hold_steady',
            'parserReviewRootCauseCode': 'ocr_required_fields',
            'clientProofRedactionStatus': 'needs_client_redaction_review',
            'clientProofVisibilityCounts': {
              'review_for_client_proof': 2,
              'review_before_client_share': 1,
            },
            'selectedReceiptLinePurpose': 'invoice',
            'selectedReceiptLineCount': 3,
            'excludedReceiptLineCount': 1,
            'clientProofReviewLineCount': 1,
            'redactedReceiptLineCount': 1,
            'clientProofRedactionPlanStatus': 'ready_to_share',
            'clientProofVisibleLineCount': 2,
            'clientProofHiddenLineCount': 1,
            'clientProofPlanReviewLineCount': 0,
            'clientProofLayoutRedactionStatus': 'ready_to_share',
            'clientProofLayoutVisibleLineCount': 3,
            'clientProofLayoutHiddenLineCount': 1,
            'clientProofLayoutIgnoredLineCount': 0,
            'clientProofLayoutProtectedTypeCount': 1,
            'clientProofLayoutKeepsMerchantContext': false,
            'clientProofLayoutKeepsTotalsContext': true,
          },
        ),
      );

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrCompleted,
          context: context,
          metadata: const {
            'ocrSourceHandoffStatus': 'scanner_prep_review_needed',
            'ocrSourceHandoffSignalCounts': {
              'receipt_handoff_ready_for_receipt_review': 1,
            },
            'ocrSourceScannerDecisionCounts': {
              'scanner_decision_cleanup_skipped_quality_guard': 1,
            },
            'ocrSourceCaptureSourceSignalCounts': {
              'native_capture_source_imported_photo': 1,
            },
            'ocrSourcePhotoQualityRiskCounts': {
              'ocr_source_cleanup_skipped_quality_guard': 1,
            },
            'ocrSourceQualityReviewStatus': 'scanner_prep_review_needed',
            'ocrSourceQualityReviewAction': 'review_scanner_preparation',
          },
        ),
      );

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          context: context,
          metadata: const {
            'ocrSourceHandoffStatus': 'saved_proof_fallback',
            'ocrSourceHandoffSignalCounts': {
              'ocr_source_fallback_saved_proof': 1,
            },
            'ocrSourceCaptureSourceSignalCounts': {
              'native_capture_source_recovery_photo': 1,
            },
            'ocrSourcePhotoQualityRiskCounts': {
              'ocr_source_fallback_saved_proof_review_required': 1,
            },
            'ocrSourceQualityReviewStatus': 'saved_bottom_quality_review',
            'ocrSourceQualityReviewAction': 'check_bottom_or_add_photo',
          },
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 29, 12),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(snapshot.ocrSourceHandoffStatusCounts, {
        'stitched_ocr_source': 2,
        'possible_partial_receipt': 1,
        'scanner_prep_review_needed': 1,
        'saved_proof_fallback': 1,
      });
      expect(snapshot.ocrSourceHandoffSignalCounts, {
        'receipt_handoff_ready_for_receipt_review': 3,
        'receipt_handoff_possible_partial_receipt': 1,
        'ocr_source_fallback_saved_proof': 1,
      });
      expect(snapshot.ocrSourceStitchSignalCounts, {
        'stitched_ocr_source': 2,
        'multiple_ocr_sources_fallback': 1,
      });
      expect(snapshot.ocrSourceScannerDecisionCounts, {
        'scanner_decision_ocr_source_enhanced_selected': 2,
        'scanner_decision_ocr_source_original_selected_quality_guard': 1,
        'scanner_decision_cleanup_skipped_quality_guard': 1,
      });
      expect(snapshot.ocrSourceCaptureSourceSignalCounts, {
        'native_capture_source_maintainiac_native_camera': 2,
        'native_capture_source_phone_camera_backup': 1,
        'native_capture_source_imported_photo': 1,
        'native_capture_source_recovery_photo': 1,
      });
      expect(snapshot.ocrSourcePhotoQualityRiskCounts, {
        'ocr_source_saved_photo_dimmer_than_preview': 2,
        'ocr_source_saved_photo_soft_blur_risk': 1,
        'ocr_source_cleanup_skipped_quality_guard': 1,
        'ocr_source_fallback_saved_proof_review_required': 1,
      });
      expect(snapshot.ocrSourceQualityReviewStatusCounts, {
        'saved_dark_exposure_review': 2,
        'saved_soft_blur_review': 1,
        'scanner_prep_review_needed': 1,
        'saved_bottom_quality_review': 1,
      });
      expect(snapshot.ocrSourceQualityReviewActionCounts, {
        'retake_or_raise_brightness': 2,
        'retake_hold_steady': 1,
        'review_scanner_preparation': 1,
        'check_bottom_or_add_photo': 1,
      });
      expect(snapshot.parserReviewRootCauseCounts, {
        'camera_source_quality': 1,
        'ocr_required_fields': 1,
      });
      expect(snapshot.clientProofRedactionStatusCounts, {
        'ready_for_client_proof': 1,
        'needs_client_redaction_review': 1,
      });
      expect(snapshot.clientProofVisibilityCounts, {
        'review_for_client_proof': 6,
        'redact_by_default': 2,
        'review_before_client_share': 1,
      });
      expect(snapshot.receiptSelectedLinePurposeCounts, {
        'client_proof': 1,
        'invoice': 1,
      });
      expect(snapshot.receiptSelectedLineCountTotal, 7);
      expect(snapshot.receiptExcludedLineCountTotal, 3);
      expect(snapshot.receiptClientProofReviewLineCountTotal, 5);
      expect(snapshot.receiptRedactedLineCountTotal, 3);
      expect(snapshot.clientProofRedactionPlanStatusCounts, {
        'review_required': 1,
        'ready_to_share': 1,
      });
      expect(snapshot.clientProofVisibleLineCountTotal, 2);
      expect(snapshot.clientProofHiddenLineCountTotal, 3);
      expect(snapshot.clientProofPlanReviewLineCountTotal, 4);
      expect(snapshot.clientProofLayoutRedactionStatusCounts, {
        'ignored_unknown_lines': 1,
        'ready_to_share': 1,
      });
      expect(snapshot.clientProofLayoutVisibleLineCountTotal, 4);
      expect(snapshot.clientProofLayoutHiddenLineCountTotal, 5);
      expect(snapshot.clientProofLayoutIgnoredLineCountTotal, 2);
      expect(snapshot.clientProofLayoutProtectedTypeCountTotal, 3);
      expect(snapshot.clientProofLayoutMerchantContextCountTotal, 1);
      expect(snapshot.clientProofLayoutTotalsContextCountTotal, 1);
      expect(snapshot.topOcrSourceHandoffStatus, 'stitched_ocr_source');
      expect(
        snapshot.topOcrSourceHandoffSignal,
        'receipt_handoff_ready_for_receipt_review',
      );
      expect(snapshot.topOcrSourceStitchSignal, 'stitched_ocr_source');
      expect(
        snapshot.topOcrSourceScannerDecision,
        'scanner_decision_ocr_source_enhanced_selected',
      );
      expect(
        snapshot.topOcrSourceCaptureSourceSignal,
        'native_capture_source_maintainiac_native_camera',
      );
      expect(
        snapshot.topOcrSourcePhotoQualityRisk,
        'ocr_source_saved_photo_dimmer_than_preview',
      );
      expect(
        snapshot.topOcrSourceQualityReviewStatus,
        'saved_dark_exposure_review',
      );
      expect(
        snapshot.topOcrSourceQualityReviewAction,
        'retake_or_raise_brightness',
      );
      expect(snapshot.topParserReviewRootCause, 'camera_source_quality');
      expect(
        snapshot.topClientProofRedactionStatus,
        'needs_client_redaction_review',
      );
      expect(snapshot.topClientProofVisibility, 'review_for_client_proof');
      expect(snapshot.topReceiptSelectedLinePurpose, 'client_proof');
      expect(snapshot.topClientProofRedactionPlanStatus, 'ready_to_share');
      expect(
        map['ocrSourceHandoffStatusCounts'],
        snapshot.ocrSourceHandoffStatusCounts,
      );
      expect(
        map['ocrSourceHandoffSignalCounts'],
        snapshot.ocrSourceHandoffSignalCounts,
      );
      expect(
        map['ocrSourceStitchSignalCounts'],
        snapshot.ocrSourceStitchSignalCounts,
      );
      expect(
        map['ocrSourceScannerDecisionCounts'],
        snapshot.ocrSourceScannerDecisionCounts,
      );
      expect(
        map['ocrSourceCaptureSourceSignalCounts'],
        snapshot.ocrSourceCaptureSourceSignalCounts,
      );
      expect(
        map['ocrSourcePhotoQualityRiskCounts'],
        snapshot.ocrSourcePhotoQualityRiskCounts,
      );
      expect(
        map['ocrSourceQualityReviewStatusCounts'],
        snapshot.ocrSourceQualityReviewStatusCounts,
      );
      expect(
        map['ocrSourceQualityReviewActionCounts'],
        snapshot.ocrSourceQualityReviewActionCounts,
      );
      expect(
        map['parserReviewRootCauseCounts'],
        snapshot.parserReviewRootCauseCounts,
      );
      expect(
        map['clientProofRedactionStatusCounts'],
        snapshot.clientProofRedactionStatusCounts,
      );
      expect(
        map['clientProofVisibilityCounts'],
        snapshot.clientProofVisibilityCounts,
      );
      expect(
        map['receiptSelectedLinePurposeCounts'],
        snapshot.receiptSelectedLinePurposeCounts,
      );
      expect(map['receiptSelectedLineCountTotal'], 7);
      expect(map['receiptExcludedLineCountTotal'], 3);
      expect(map['receiptClientProofReviewLineCountTotal'], 5);
      expect(map['receiptRedactedLineCountTotal'], 3);
      expect(
        map['clientProofRedactionPlanStatusCounts'],
        snapshot.clientProofRedactionPlanStatusCounts,
      );
      expect(map['clientProofVisibleLineCountTotal'], 2);
      expect(map['clientProofHiddenLineCountTotal'], 3);
      expect(map['clientProofPlanReviewLineCountTotal'], 4);
      expect(
        map['clientProofLayoutRedactionStatusCounts'],
        snapshot.clientProofLayoutRedactionStatusCounts,
      );
      expect(map['clientProofLayoutVisibleLineCountTotal'], 4);
      expect(map['clientProofLayoutHiddenLineCountTotal'], 5);
      expect(map['clientProofLayoutIgnoredLineCountTotal'], 2);
      expect(map['clientProofLayoutProtectedTypeCountTotal'], 3);
      expect(map['clientProofLayoutMerchantContextCountTotal'], 1);
      expect(map['clientProofLayoutTotalsContextCountTotal'], 1);
      expect(map['topOcrSourceHandoffStatus'], 'stitched_ocr_source');
      expect(
        map['topOcrSourceHandoffSignal'],
        'receipt_handoff_ready_for_receipt_review',
      );
      expect(map['topOcrSourceStitchSignal'], 'stitched_ocr_source');
      expect(
        map['topOcrSourceScannerDecision'],
        'scanner_decision_ocr_source_enhanced_selected',
      );
      expect(
        map['topOcrSourceCaptureSourceSignal'],
        'native_capture_source_maintainiac_native_camera',
      );
      expect(
        map['topOcrSourcePhotoQualityRisk'],
        'ocr_source_saved_photo_dimmer_than_preview',
      );
      expect(
        map['topOcrSourceQualityReviewStatus'],
        'saved_dark_exposure_review',
      );
      expect(
        map['topOcrSourceQualityReviewAction'],
        'retake_or_raise_brightness',
      );
      expect(map['topParserReviewRootCause'], 'camera_source_quality');
      expect(
        map['topClientProofRedactionStatus'],
        'needs_client_redaction_review',
      );
      expect(map['topClientProofVisibility'], 'review_for_client_proof');
      expect(map['topReceiptSelectedLinePurpose'], 'client_proof');
      expect(map['topClientProofRedactionPlanStatus'], 'ready_to_share');
      expect(
        map['topClientProofLayoutRedactionStatus'],
        'ignored_unknown_lines',
      );
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('3.24')));
      expect(encoded, isNot(contains('/tmp')));
    },
  );
}
