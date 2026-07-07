import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_result_frozen_fixture.dart';

void main() {
  test('accepted review freezes privacy-safe route storage and local metadata', () {
    final fixture = frozenReceiptCameraDiagnosticsFixture();
    final result = fixture.result;
    final handoffMetadata = result.privacySafeReceiptReaderHandoffMetadata;

    expect(
      handoffMetadata,
      containsPair('receiptBrainLocalFirstReadinessActionCounts', {
        'keep_capture_and_basic_reader_available': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainLocalFirstReadinessActionOutcome',
        'keep_capture_and_basic_reader_available',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptBrainLocalFirstReadinessSummaryCounts', {
        'present': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptLocalOnlyAcceptanceStatusCounts', {
        'ready_local_first_optional_packs_deferred': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptLocalOnlyAcceptanceStatusOutcome',
        'ready_local_first_optional_packs_deferred',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptLocalOnlyAcceptanceActionCounts', {
        'ship_base_capture_save_review_before_optional_packs': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptLocalOnlyAcceptanceActionOutcome',
        'ship_base_capture_save_review_before_optional_packs',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptLocalOnlyBaseFlowCanRunCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptLocalOnlyBlocksLowStorageCounts', {'false': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptLocalOnlyEvidenceCounts', {
        'capture_available_in_base': 1,
        'proof_save_available_in_base': 1,
        'basic_local_review_available_in_base': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('nativeLocalOnlyCapturePolicyCounts', {
        'capture_save_basic_review_now_optional_packs_later': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'nativeLocalOnlyCapturePolicyOutcome',
        'capture_save_basic_review_now_optional_packs_later',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('nativeLocalOnlyBaseFlowCanRunCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('nativeLocalOnlyHeavyPacksMayBlockCaptureCounts', {
        'false': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('nativeLocalOnlyCloudAssistMayBlockCaptureCounts', {
        'false': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('receiptRequiredBaseFootprintStatusCounts', {'review': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptRequiredBaseFootprintStatusOutcome', 'review'),
    );
    expect(
      handoffMetadata,
      containsPair('receiptRequiredBaseFootprintCanShipCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptRequiredBaseFootprintReviewCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('receiptRequiredBaseFootprintReviewReasonCounts', {
        'full_offline_brain_over_100mb_optional_only': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair('ocrStoragePolicyCounts', {
        'ocr_clear_source_before_saved_proof_copy': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'ocrStoragePolicyOutcome',
        'ocr_clear_source_before_saved_proof_copy',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptProofStoragePolicyCounts', {
        'saved_proof_kept_for_receipt_record': 1,
        'ocr_source_used_for_reading_before_saved_proof': 1,
        'temporary_ocr_source_separate_from_saved_proof': 1,
        'clear_ocr_source_read_before_saved_proof_copy': 1,
        'normal_record_uses_data_saver_proof': 1,
        'accepted_review_allows_temporary_ocr_cleanup': 1,
      }),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptProofStoragePolicyOutcome',
        'temporary_ocr_source_saved_data_saver_proof',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('ocrUsesPreparedSourceBeforeSavedProofCounts', {'true': 1}),
    );
    expect(
      handoffMetadata,
      containsPair('ocrUsesSavedProofFallbackCounts', {'false': 1}),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptBrainBasePayloadGuardrailOutcome',
        'base_payload_optional_packs_ok',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptPhotoReviewHandoffPath',
        'accepted_single_prepared_source',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptPhotoReviewHandoffPathLabel',
        'Accepted single receipt with prepared OCR source.',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptReaderHandoffRoute',
        'photo_review_accepted_to_receipt_details',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptDetailsHandoffRoute',
        'photo_review_accepted_to_receipt_details',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptReaderHandoffNextScreen',
        'receipt_details_store_date_total_tax_items',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptDetailsHandoffNextScreen',
        'receipt_details_store_date_total_tax_items',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptReaderHandoffNextStepLabel',
        'Receipt details open with store, date, total, tax, item prices, and Business/Personal/Mixed choices.',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptDetailsHandoffNextStepLabel',
        'Receipt details open with store, date, total, tax, item prices, and Business/Personal/Mixed choices.',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptReaderHandoffRouteResultLabel',
        'Accepted photo review must open receipt details next, not the previous expense screen.',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptDetailsHandoffRouteResultLabel',
        'Accepted photo review must open receipt details next, not the previous expense screen.',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('receiptReaderHandoffMustOpenReceiptDetails', true),
    );
    expect(
      handoffMetadata,
      containsPair('receiptDetailsHandoffMustOpenReceiptDetails', true),
    );
    expect(
      handoffMetadata,
      containsPair('receiptReaderHandoffMustOpenFilledReview', true),
    );
    expect(
      handoffMetadata,
      containsPair('receiptDetailsHandoffMustOpenFilledReview', true),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptReaderHandoffUserAction',
        'tap_next_after_photo_review',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptDetailsHandoffUserAction',
        'tap_next_after_photo_review',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptReaderHandoffEvidence',
        'quality=ready_for_receipt_review;stitch=notNeeded;reason=notNeeded;sources=1;ocr_source_first=true;scanner=enhanced_ocr_source;saved=saved_warning_none;coverage=coverage_ok;ui=native_ui_signal_missing',
      ),
    );
    expect(
      handoffMetadata,
      containsPair(
        'receiptDetailsHandoffEvidence',
        'quality=ready_for_receipt_review;stitch=notNeeded;reason=notNeeded;sources=1;ocr_source_first=true;scanner=enhanced_ocr_source;saved=saved_warning_none;coverage=coverage_ok;ui=native_ui_signal_missing',
      ),
    );
    expect(
      handoffMetadata,
      containsPair('acceptedPhotoWarningProfile', 'saved_photo_ok'),
    );
  });
}
