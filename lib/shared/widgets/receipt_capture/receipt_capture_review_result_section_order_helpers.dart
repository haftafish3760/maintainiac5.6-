part of 'receipt_capture_models.dart';

List<String> _receiptRetakeInvalidOrderCodes({
  required Map<String, Object?> diagnostics,
  required int? originalSection,
  required int? finalSection,
}) {
  if (originalSection == null || finalSection == null) return const [];
  final codes = <String>[];
  if (finalSection < originalSection) {
    codes.add('retake_invalid_final_before_original');
  }
  if (_diagnosticBool(diagnostics['receiptRetakePreservedOriginalSlot']) ==
          true &&
      finalSection != originalSection) {
    codes.add('retake_invalid_preserved_slot_moved');
  }
  return codes;
}

List<String> _receiptInsertInvalidOrderCodes({
  required Map<String, Object?> diagnostics,
  required int? anchorSection,
  required int? finalSection,
}) {
  if (anchorSection == null || finalSection == null) return const [];
  final codes = <String>[];
  if (finalSection <= anchorSection) {
    codes.add('insert_invalid_final_not_after_anchor');
  }
  if (_diagnosticBool(diagnostics['receiptInsertPreservedAnchorSlot']) ==
          true &&
      finalSection <= anchorSection) {
    codes.add('insert_invalid_preserved_anchor_overlap');
  }
  return codes;
}

List<String> _receiptRetakeContextCodes(Map<String, Object?> diagnostics) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptRetakePreservedOriginalSlot']) ==
      true) {
    codes.add('retake_preserved_original_slot');
  }
  if (_diagnosticBool(diagnostics['receiptRetakeInsertedExtraSection']) ==
      true) {
    codes.add('retake_inserted_extra_section');
  }
  if (_diagnosticBool(
        diagnostics['receiptRetakeHasPreviousAlignmentContext'],
      ) ==
      true) {
    codes.add('retake_previous_alignment_context');
  }
  if (_diagnosticBool(diagnostics['receiptRetakeHasNextAlignmentContext']) ==
      true) {
    codes.add('retake_next_alignment_context');
  }
  if (_diagnosticBool(
        diagnostics['receiptRetakeHasTwoSidedAlignmentContext'],
      ) ==
      true) {
    codes.add('retake_two_sided_alignment_context');
  }
  final previousSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakePreviousContextSectionNumber'],
  );
  if (previousSection != null) {
    codes.add(
      previousSection > 9
          ? 'retake_previous_context_section_10_plus'
          : 'retake_previous_context_section_$previousSection',
    );
  }
  final nextSection = _diagnosticPositiveInt(
    diagnostics['receiptRetakeNextContextSectionNumber'],
  );
  if (nextSection != null) {
    codes.add(
      nextSection > 9
          ? 'retake_next_context_section_10_plus'
          : 'retake_next_context_section_$nextSection',
    );
  }
  return codes;
}

List<String> _receiptInsertContextCodes(Map<String, Object?> diagnostics) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptInsertPreservedAnchorSlot']) ==
      true) {
    codes.add('insert_preserved_anchor_slot');
  }
  final offset = _diagnosticZeroOrPositiveInt(
    diagnostics['receiptInsertAfterOffset'],
  );
  if (offset != null) {
    codes.add(offset > 9 ? 'insert_offset_10_plus' : 'insert_offset_$offset');
  }
  return codes;
}

List<String> _receiptManualReorderContextCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  if (_diagnosticBool(diagnostics['receiptManualReorderPreservedPhotoPath']) ==
      true) {
    codes.add('manual_reorder_preserved_photo_path');
  }
  return codes;
}
