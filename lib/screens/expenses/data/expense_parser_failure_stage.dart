class ExpenseParserFailureStage {
  const ExpenseParserFailureStage._();

  static String failedAtFor(String cause) {
    return switch (cause) {
      'receipt_parser_no_usable_fields' =>
        'after_ocr_text_before_receipt_fields',
      'receipt_ocr_missing_vendor' => 'ocr_to_parser_vendor_handoff',
      'receipt_ocr_missing_date' => 'ocr_to_parser_date_handoff',
      'receipt_ocr_no_readable_text' => 'ocr_to_parser_no_text_handoff',
      'receipt_ocr_photo_read_failed' => 'ocr_to_parser_photo_read_handoff',
      'receipt_ocr_photo_tiny_text' => 'ocr_to_parser_tiny_text_handoff',
      'receipt_ocr_small_proof_copy' => 'ocr_to_parser_small_proof_handoff',
      'receipt_ocr_photo_retake_recommended' =>
        'ocr_to_parser_photo_retake_handoff',
      'receipt_ocr_photo_crop_or_retake' => 'ocr_to_parser_photo_crop_handoff',
      'receipt_ocr_photo_readability_or_closer' =>
        'ocr_to_parser_photo_readability_handoff',
      'receipt_ocr_photo_saved_dark_or_exposure' =>
        'ocr_to_parser_photo_exposure_handoff',
      'receipt_ocr_photo_saved_soft_blur' =>
        'ocr_to_parser_photo_focus_handoff',
      'receipt_ocr_photo_saved_glare' => 'ocr_to_parser_photo_glare_handoff',
      'receipt_ocr_photo_saved_bottom_quality' =>
        'ocr_to_parser_photo_bottom_quality_handoff',
      'receipt_ocr_photo_quality_review' =>
        'ocr_to_parser_photo_quality_handoff',
      'receipt_ocr_long_receipt_section_gap' =>
        'ocr_to_parser_long_receipt_section_handoff',
      'receipt_ocr_long_receipt_probable_overlap' =>
        'ocr_to_parser_long_receipt_overlap_handoff',
      'receipt_ocr_long_receipt_duplicate_text' =>
        'ocr_to_parser_long_receipt_duplicate_handoff',
      'receipt_ocr_missing_total' => 'ocr_to_parser_total_handoff',
      'receipt_ocr_missing_summary' => 'ocr_to_parser_summary_handoff',
      'receipt_ocr_missing_tax' => 'ocr_to_parser_tax_handoff',
      'receipt_ocr_no_priced_lines' => 'ocr_to_parser_price_handoff',
      'receipt_ocr_no_item_lines' => 'ocr_to_parser_item_handoff',
      'receipt_ocr_no_parser_ready_items' =>
        'ocr_to_parser_item_confidence_handoff',
      'receipt_ocr_line_sequence_review' =>
        'ocr_to_parser_line_sequence_handoff',
      'receipt_ocr_source_sections_out_of_order' =>
        'ocr_to_parser_long_receipt_section_order_handoff',
      'receipt_ocr_source_sections_missing' =>
        'ocr_to_parser_long_receipt_section_gap_handoff',
      'receipt_ocr_source_sections_partial' =>
        'ocr_to_parser_long_receipt_section_location_handoff',
      'receipt_ocr_summary_math_review' => 'ocr_to_parser_summary_math_handoff',
      'receipt_ocr_parser_readiness_review' =>
        'ocr_to_parser_readiness_handoff',
      'receipt_parser_base_install_blocks_low_storage' =>
        'receipt_brain_required_base_storage_guardrail',
      'receipt_parser_full_offline_too_large_optional_only' =>
        'receipt_brain_full_offline_pack_guardrail',
      'receipt_parser_optional_pack_deferred_for_storage' =>
        'receipt_optional_detail_pack_storage_guardrail',
      'receipt_parser_optional_detail_pack_available' =>
        'receipt_optional_detail_pack_routing',
      'receipt_line_total_mismatch' => 'receipt_line_reconciliation',
      'receipt_subtotal_tax_total_mismatch' => 'receipt_total_math_check',
      'receipt_parser_totals_found_no_safe_lines' =>
        'receipt_line_detection_after_total_detection',
      'receipt_totals_only_no_line_items' => 'receipt_line_detection',
      'receipt_total_missing' => 'receipt_total_detection',
      'receipt_subtotal_inferred' => 'receipt_total_math_inference',
      'receipt_tax_inferred' => 'receipt_total_math_inference',
      'receipt_total_inferred' => 'receipt_total_math_inference',
      'receipt_date_missing' => 'receipt_date_detection',
      'receipt_date_used_fallback' => 'receipt_date_fallback',
      'receipt_merchant_missing' => 'receipt_merchant_detection',
      'inventory_catalog_match_weak' => 'inventory_catalog_matching',
      'receipt_lines_need_review' => 'receipt_line_classification',
      _ => 'receipt_parser_quality_check',
    };
  }
}
