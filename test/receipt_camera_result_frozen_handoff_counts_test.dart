import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_result_frozen_fixture.dart';

void main() {
  test('accepted review freezes core handoff counts and scanner proof policy', () {
    final fixture = frozenReceiptCameraDiagnosticsFixture();
    final result = fixture.result;
    final quality = fixture.quality;

    expect(result.photoPaths, ['/tmp/proof.jpg']);
    expect(result.ocrSourcePhotoPaths, ['/tmp/ocr.jpg']);
    expect(result.savedBackupPhotoCount, 1);
    expect(result.ocrSourcePhotoCount, 1);
    expect(result.hasReceiptReaderHandoff, isTrue);
    expect(result.usesSeparateOcrSourceCopies, isTrue);
    expect(result.receiptReaderHandoffCounts, {
      'saved_backup_present': 1,
      'ocr_source_present': 1,
      'ocr_source_separate_from_backup': 1,
      'ocr_source_review_risk_ocr_source_ready': 1,
      'ocr_source_review_requirement_standard_user_confirmation_required': 1,
      'stitch_ocr_source_contract_ordered_sources_ready': 1,
      'match_readiness_single_receipt_source_ready': 1,
      'native_camera_ui_native_capture_review_transition_ready': 1,
      'native_camera_ui_native_capture_review_target_receipt_details': 1,
      'native_camera_ui_native_capture_review_discard_protected': 1,
      'receipt_section_order_action_review_single_section': 1,
      'receipt_brain_release_ship_lean_base_offer_explicit_receipt_pack_download':
          1,
      'receipt_brain_install_base_app_explicit_optional_receipt_packs': 1,
      'receipt_brain_storage_comfortable': 1,
      'receipt_brain_local_ocr_full_local_ocr': 1,
      'receipt_brain_base_size_decision_base_size_ready': 1,
      'receipt_brain_first_install_boundary_ready_base_first_optional_local_pack_later':
          1,
      'receipt_brain_first_install_action_ship_base_then_offer_optional_local_pack':
          1,
      'receipt_brain_first_install_low_storage_true': 1,
      'receipt_brain_base_size_review_false': 1,
      'receipt_brain_base_blocks_low_storage_false': 1,
      'receipt_brain_full_offline_exceeds_base_guardrail_true': 1,
      'receipt_brain_full_offline_must_stay_optional_true': 1,
      'receipt_brain_low_storage_download_risk_full_offline_large_optional_only':
          1,
      'receipt_install_required_segment_required_base_lean_under_40mb': 1,
      'receipt_install_full_offline_segment_full_offline_100_to_250mb_optional':
          1,
      'receipt_install_low_storage_impact_low_storage_base_only_optional_pack_hidden':
          1,
      'receipt_install_distribution_ship_base_hide_large_packs_until_storage_allows':
          1,
      'receipt_install_shell_parser_free_true': 1,
      'receipt_install_tiny_phone_useful_true': 1,
      'receipt_install_optional_consent_true': 1,
      'receipt_brain_required_payload_native_receipt_camera': 1,
      'receipt_brain_required_payload_receipt_proof_storage': 1,
      'receipt_brain_required_payload_basic_local_receipt_reader': 1,
      'receipt_brain_required_payload_manual_receipt_entry': 1,
      'receipt_brain_required_payload_data_saver_proof_copies': 1,
      'receipt_brain_optional_payload_general_expense_lines_v1': 1,
      'receipt_brain_optional_payload_materials_inventory_regional_v1': 1,
      'receipt_brain_base_ship_without_full_offline_true': 1,
      'receipt_brain_base_vs_full_offline_summary_present': 1,
      'receipt_brain_optional_pack_choice_true': 1,
      'receipt_brain_base_local_reading_available_true': 1,
      'receipt_brain_base_works_without_cloud_assist_true': 1,
      'receipt_brain_local_first_readiness_lean_local_ready_optional_packs_deferred':
          1,
      'receipt_brain_local_first_action_keep_capture_and_basic_reader_available':
          1,
      'receipt_brain_local_first_summary_present': 1,
      'receipt_local_only_status_ready_local_first_optional_packs_deferred': 1,
      'receipt_local_only_action_ship_base_capture_save_review_before_optional_packs':
          1,
      'receipt_local_only_base_flow_can_run_true': 1,
      'receipt_local_only_blocks_low_storage_false': 1,
      'receipt_local_only_evidence_capture_available_in_base': 1,
      'receipt_local_only_evidence_proof_save_available_in_base': 1,
      'receipt_local_only_evidence_basic_local_review_available_in_base': 1,
      'native_local_only_capture_policy_capture_save_basic_review_now_optional_packs_later':
          1,
      'native_local_only_base_flow_can_run_true': 1,
      'native_local_only_heavy_packs_block_capture_false': 1,
      'native_local_only_cloud_blocks_capture_false': 1,
      'receipt_required_base_footprint_status_review': 1,
      'receipt_required_base_footprint_can_ship_true': 1,
      'receipt_required_base_footprint_review_true': 1,
      'receipt_required_base_footprint_review_reason_full_offline_brain_over_100mb_optional_only':
          1,
      'ocr_storage_policy_ocr_clear_source_before_saved_proof_copy': 1,
      'receipt_proof_storage_policy_saved_proof_kept_for_receipt_record': 1,
      'receipt_proof_storage_policy_ocr_source_used_for_reading_before_saved_proof':
          1,
      'receipt_proof_storage_policy_temporary_ocr_source_separate_from_saved_proof':
          1,
      'receipt_proof_storage_policy_clear_ocr_source_read_before_saved_proof_copy':
          1,
      'receipt_proof_storage_policy_normal_record_uses_data_saver_proof': 1,
      'receipt_proof_storage_policy_accepted_review_allows_temporary_ocr_cleanup':
          1,
      'receipt_proof_target_normal_proof_200_300kb': 1,
      'receipt_proof_target_level_balanced': 1,
      'receipt_proof_target_cloud_backup_true': 1,
      'receipt_proof_target_review_required_false': 1,
      'ocr_prepared_source_before_saved_proof_true': 1,
      'ocr_saved_proof_fallback_false': 1,
      'scanner_enhanced_ocr_source_used': 1,
    });
    expect(
      result.receiptReaderHandoffIntegrityLabel,
      'saved=1;ocr=1;storage=ocr_source_separate_from_backup;stitch=notNeeded;coverage=coverage_ok;warnings=saved_photo_ok',
    );
    expect(result.photoQualityChecksByPath['/tmp/proof.jpg'], quality);
    expect(
      result
          .preparationDiagnosticsByOcrPath['/tmp/ocr.jpg']!['usedEnhancedOcrSource'],
      isTrue,
    );
    expect(result.scannerDecisionCodes, [
      'cleanup_applied_dark_receipt',
      'ocr_source_enhanced_selected',
    ]);
    expect(result.scannerDecisionCounts['cleanup_applied_dark_receipt'], 1);
    expect(result.scannerUsedEnhancedOcrSource, isTrue);
    expect(result.scannerKeptTemporaryFullQualitySourceForQuality, isFalse);
    expect(result.scannerNeedsOperatorReview, isFalse);
    expect(result.ocrStoragePolicyCounts, {
      'ocr_clear_source_before_saved_proof_copy': 1,
    });
    expect(
      result.ocrStoragePolicyOutcome,
      'ocr_clear_source_before_saved_proof_copy',
    );
    expect(result.receiptProofStoragePolicyCounts, {
      'saved_proof_kept_for_receipt_record': 1,
      'ocr_source_used_for_reading_before_saved_proof': 1,
      'temporary_ocr_source_separate_from_saved_proof': 1,
      'clear_ocr_source_read_before_saved_proof_copy': 1,
      'normal_record_uses_data_saver_proof': 1,
      'accepted_review_allows_temporary_ocr_cleanup': 1,
    });
    expect(
      result.receiptProofStoragePolicyOutcome,
      'temporary_ocr_source_saved_data_saver_proof',
    );
    expect(
      result.receiptProofTargetSizePolicy.policyCode,
      'normal_proof_200_300kb',
    );
    expect(result.receiptProofTargetSizePolicy.targetBytes, 250 * 1024);
    expect(
      result.receiptProofTargetSizePolicy.cloudBackupDefaultAllowed,
      isTrue,
    );
    expect(
      result.receiptProofTargetSizePolicy.requiresReadabilityReview,
      isFalse,
    );
    expect(result.ocrUsesPreparedSourceBeforeSavedProofCounts, {'true': 1});
    expect(result.ocrUsesSavedProofFallbackCounts, {'false': 1});
    expect(result.ocrSourceFirstOutcome, 'prepared_source_ready');
    expect(
      result.ocrSourceFirstActionLabel,
      'OCR reads prepared receipt source before saved proof',
    );
  });
}
