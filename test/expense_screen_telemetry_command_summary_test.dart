import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_command_center_summary_expectations.dart';
import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test(
    'builds command center summary without private receipt details',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = expenseTelemetryContextFixture();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.screenOpened,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.timeSpentOnScreen,
          context: context,
          durationMs: 120000,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseStarted,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseAbandoned,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          context: context,
          metadata: const {
            'photoCoverageStatuses': {'likelyCutOff': 1, 'likelyComplete': 1},
            'photoCoverageReasons': {
              'native_cut_off_risk': 1,
              'framing_ok_readable': 1,
            },
            'photoCoverageNeedsMoreCount': 1,
            'savedPhotoWarningCounts': {'saved_photo_dimmer_than_preview': 1},
            'savedPhotoWarningCauseCounts': {
              'saved_photo_dim_or_live_to_saved_mismatch': 1,
            },
            'savedPhotoWarningSeverityCounts': {'warning': 1},
            'savedPhotoWarningActionCounts': {'review_or_add_light': 1},
            'savedPhotoParserRiskCounts': {'ocr_text_may_need_review': 1},
            'receiptRequiredBaseFootprintStatusCounts': {'review': 1},
            'receiptRequiredBaseFootprintCanShipCounts': {'true': 1},
            'receiptRequiredBaseFootprintReviewCounts': {'true': 1},
            'receiptRequiredBaseFootprintBlockingReasonCounts': <String, int>{},
            'receiptRequiredBaseFootprintReviewReasonCounts': {
              'full_offline_brain_over_100mb_optional_only': 1,
            },
            'hasSavedPhotoQualityWarning': true,
            'preCaptureExposureDecisionBuckets': {
              'brightening_before_capture': 1,
            },
            'preCaptureExposureAdjustmentTotal': 1,
            'preCaptureExposureAbortTotal': 1,
            'preCaptureExposureAbortReasonBuckets': {
              'camera_surface_inactive': 1,
            },
            'autoExposureDecisionBuckets': {'brightened_preview': 1},
            'autoExposureBrightnessBuckets': {'preview_dim': 1},
            'autoExposureCandidateBuckets': {'stable_receipt_text': 1},
            'exposureAssistStatuses': {'active': 1},
            'autoExposureCandidateFrameTotal': 4,
            'manualBrightnessChangeTotal': 1,
            'tapFocusControlExpectedCount': 0,
            'continuousFocusExpectedCount': 1,
            'pinchZoomControlExpectedCount': 1,
            'exposureSliderControlExpectedCount': 1,
            'exposureResetControlExpectedCount': 1,
            'settingsControlExpectedCount': 1,
            'backControlExpectedCount': 1,
            'torchControlExpectedCount': 1,
            'settingsOpenTotal': 2,
            'backDispatchPathBuckets': {'top_bar_back_button': 1},
            'zoomGestureStartTotal': 2,
            'zoomChangeTotal': 1,
            'zoomUnavailableTotal': 1,
            'captureReadinessCodeCounts': {'manual_only_quality_review': 1},
            'zoomStatusBuckets': {'zoom_changed': 2, 'camera_unavailable': 1},
            'acceptedPhotoQualityOutcomeCounts': {'needs_review_before_ocr': 1},
            'acceptedPhotoHandoffOutcome': 'needs_review_before_ocr',
            'capturedPhotoBrightnessBuckets': {'captured_dim': 1},
            'capturedPhotoSharpnessBuckets': {'captured_sharp': 1},
            'capturedPhotoExposureMismatches': {'live_ok_capture_dim': 1},
            'capturedPhotoQualitySignals': {'review_before_saving': 1},
            'capturedPhotoBottomBrightnessBuckets': {'bottom_dim': 1},
            'capturedPhotoBottomEdgeScoreBuckets': {'bottom_edge_usable': 1},
            'capturedPhotoVerticalQualitySignals': {
              'bottom_darker_than_upper': 1,
            },
            'nativeCameraEngineBuckets': {'cameraX': 1},
            'nativeReceiptCameraSurfaceActualBuckets': {
              'maintainiac_native_android': 1,
            },
            'nativeReceiptCameraSurfaceVerificationBuckets': {
              'maintainiac_custom_surface_verified': 1,
            },
            'nativeCameraIdentityBuckets': {
              'maintainiac_in_app_receipt_camera': 1,
            },
            'nativeControlContractVersionBuckets': {
              'receipt_native_controls_v1': 1,
            },
            'settingsContractVersion': 'receipt_native_camera_settings_v1',
            'cloudAssistPlan': 'local_ocr_cloud_ocr_cloud_inventory_optional',
            'cloudAssistPlanBuckets': {'local_only': 2},
            'localOcrMode': 'lean_local_ocr',
            'localOcrModeBuckets': {'full_local_ocr': 2},
            'parserDepth': 'detailed',
            'parserDepthBuckets': {'price_only': 2},
            'parserPackCodes': [
              'core_receipt_text_v1',
              'general_expense_lines_v1',
              'materials_inventory_regional_v1',
            ],
            'optionalLocalParserPackCodes': ['general_expense_lines_v1'],
            'cloudFallbackParserPackCodes': [
              'materials_inventory_regional_v1',
              'cloud_ocr_assist_v1',
            ],
            'parserPackAccuracyBands': {
              'core_receipt_text_v1': 'ocr_text_95_99_when_photo_readable',
              'general_expense_lines_v1':
                  'parser_line_items_90_97_by_vendor_pattern',
              'materials_inventory_regional_v1':
                  'inventory_match_80_99_by_installed_trade_pack',
            },
            'estimatedOptionalLocalPackBytes': 25165824,
            'userFacingPackDisclosureLabel':
                'Optional local parser add-ons use about 24.0 MB. '
                'Cloud OCR/parser fallback needs internet and must be chosen by '
                'the user. Accuracy disclosures: core_receipt_text_v1: '
                'ocr_text_95_99_when_photo_readable; general_expense_lines_v1: '
                'parser_line_items_90_97_by_vendor_pattern; '
                'materials_inventory_regional_v1: '
                'inventory_match_80_99_by_installed_trade_pack.',
            'cloudOcrOptional': true,
            'cloudOcrOptionalCount': 2,
            'cloudInventoryOptional': true,
            'cloudInventoryOptionalCount': 2,
            'nativeDevicePolicyBuckets': {'storage_saver_receipt_camera': 1},
            'nativeCameraWorkloadTierBuckets': {'light': 1},
            'nativeCameraResolutionTierBuckets': {'medium': 1},
            'nativeRecoveryResumeStatusBuckets': {'resume_review_started': 1},
            'nativeRecoveryFreshnessBuckets': {'stale': 1},
            'nativeRecoveryStorageStatusBuckets': {
              'partial_photos_available': 1,
            },
            'nativeRecoveryRecoveredPhotoTotal': 2,
            'nativeRecoveryMultipleSectionCount': 1,
            'capabilityPolicyCodeCounts': {
              'storage_constrained_small_proofs': 1,
            },
            'nativeCaptureSourcePolicyCounts': {'storage_saver_native': 1},
            'stitchStatus': 'stitched',
            'stitchFallbackReason': 'stitched',
            'stitchConfidenceBucket': 'high',
            'stitchPairDiagnosticCounts': {'zoom_adjusted': 1},
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrFailed,
          context: context,
          failureKind: 'no_readable_text',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptOcr,
            failedAt: 'after_attachment_read_before_parser',
            confirmedCause: 'no_readable_text',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'ocr_zero_lines',
            missingEvidence: 'none',
          ),
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.userCorrectedVendor,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.cloudBackupFailure,
          context: context,
          failureKind: 'quota_limit',
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.syncFailed,
          context: context,
          failureKind: 'offline',
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expectExpenseCommandCenterSummaryTelemetry(snapshot, map, encoded);
    },
  );
}
