part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNativeSignals on ReceiptPhotoReviewResult {
  String get nativeReceiptReviewDepth {
    var sawPricesOnly = false;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final value = diagnostics['reviewDepth']?.toString().trim();
      if (value == 'detailedLines') return value!;
      if (value == 'pricesOnly') sawPricesOnly = true;
    }
    if (sawPricesOnly) return 'pricesOnly';
    return 'pricesOnly';
  }

  Map<String, int> get nativeReceiptReviewDepthCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final raw = diagnostics['reviewDepth']?.toString().trim();
      if (raw == null || raw.isEmpty) continue;
      if (raw == 'detailedLines' || raw == 'pricesOnly') {
        counts[raw] = (counts[raw] ?? 0) + 1;
        continue;
      }
      final token = _diagnosticToken(raw);
      counts['invalid_$token'] = (counts['invalid_$token'] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get editedPhotoActionCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (diagnostics['userEditedPhoto'] != true) continue;
      final token = _diagnosticToken(
        diagnostics['photoEditAction']?.toString() ?? 'manual_edit',
      );
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get editedPhotoSourceSelectionCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (diagnostics['userEditedPhoto'] != true) continue;
      final token = diagnostics['photoEditReplacedOriginal'] == true
          ? 'edited_copy_selected'
          : 'original_source_retained';
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get editedPhotoReplacedOriginalCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (diagnostics['userEditedPhoto'] != true ||
          diagnostics['photoEditReplacedOriginal'] != true) {
        continue;
      }
      final token = _diagnosticToken(
        diagnostics['photoEditAction']?.toString() ?? 'manual_edit',
      );
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get captureReadinessCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final token = _diagnosticToken(
        diagnostics[ReceiptCaptureDiagnosticKeys.captureReadinessCode]
                ?.toString() ??
            '',
      );
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  int get manualCaptureAllowedCount {
    var count = 0;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (_diagnosticBool(
            diagnostics[ReceiptCaptureDiagnosticKeys.manualCaptureAllowed],
          ) ==
          true) {
        count += 1;
      }
    }
    return count;
  }

  int get autoCaptureAllowedCount {
    var count = 0;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (_diagnosticBool(
            diagnostics[ReceiptCaptureDiagnosticKeys.autoCaptureAllowed],
          ) ==
          true) {
        count += 1;
      }
    }
    return count;
  }

  Map<String, int> get nativeCameraUiHealthCounts {
    final counts = <String, int>{};
    final resultProvesReceiptDetailsHandoff =
        acceptedPhotoHandoffMustOpenReceiptDetails &&
        acceptedPhotoHandoffRoute == 'photo_review_accepted_to_receipt_details';
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final controlSet = diagnostics['visibleControlSet']?.toString().trim();
      final previewTarget = diagnostics['previewDominanceTarget']
          ?.toString()
          .trim();
      final hasNativeTransitionContract =
          diagnostics.containsKey('nativeCaptureReviewTransitionPolicy') ||
          diagnostics.containsKey('nativeCaptureReviewTransitionTarget') ||
          diagnostics.containsKey('nativeCaptureReviewDiscardPolicy');
      for (final parityCode in _nativeCapturePreviewParityHealthCodes(
        diagnostics,
      )) {
        counts[parityCode] = (counts[parityCode] ?? 0) + 1;
      }
      for (final closeCode in _nativeCloseHealthCodes(diagnostics)) {
        counts[closeCode] = (counts[closeCode] ?? 0) + 1;
      }
      for (final readinessCode in _nativeControlReadinessHealthCodes(
        diagnostics,
      )) {
        counts[readinessCode] = (counts[readinessCode] ?? 0) + 1;
      }
      for (final latencyCode in _nativeCaptureLatencyHealthCodes(diagnostics)) {
        counts[latencyCode] = (counts[latencyCode] ?? 0) + 1;
      }
      if (hasNativeTransitionContract || !resultProvesReceiptDetailsHandoff) {
        for (final transitionCode in _nativeCaptureReviewTransitionHealthCodes(
          diagnostics,
        )) {
          counts[transitionCode] = (counts[transitionCode] ?? 0) + 1;
        }
      }
      for (final openingCode in _receiptReviewOpeningHealthCodes(diagnostics)) {
        counts[openingCode] = (counts[openingCode] ?? 0) + 1;
      }
      for (final exposureCode in _nativeExposureControlHealthCodes(
        diagnostics,
      )) {
        counts[exposureCode] = (counts[exposureCode] ?? 0) + 1;
      }
      if ((controlSet == null || controlSet.isEmpty) &&
          (previewTarget == null || previewTarget.isEmpty)) {
        continue;
      }
      final controlCode = _nativeControlSetHealthCode(controlSet);
      final previewCode = previewTarget == 'receipt_preview_75_80_percent'
          ? 'preview_dominance_expected'
          : 'preview_dominance_missing';
      counts[controlCode] = (counts[controlCode] ?? 0) + 1;
      counts[previewCode] = (counts[previewCode] ?? 0) + 1;
      for (final settingsCode in _nativeSettingsControlHealthCodes(
        diagnostics,
        controlSet,
      )) {
        counts[settingsCode] = (counts[settingsCode] ?? 0) + 1;
      }
    }
    if (resultProvesReceiptDetailsHandoff) {
      counts['native_capture_review_transition_ready'] =
          (counts['native_capture_review_transition_ready'] ?? 0) + 1;
      counts['native_capture_review_target_receipt_details'] =
          (counts['native_capture_review_target_receipt_details'] ?? 0) + 1;
      counts['native_capture_review_discard_protected'] =
          (counts['native_capture_review_discard_protected'] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get nativeCloseCapturedPhotoOutcomeCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final outcome = diagnostics['closeCapturedPhotoOutcome']
          ?.toString()
          .trim();
      if (outcome == null || outcome.isEmpty) continue;
      final token = _diagnosticToken(outcome);
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get receiptSectionOrderCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final sectionCount = _diagnosticPositiveInt(
        diagnostics['receiptSectionCount'],
      );
      final nextSection = _diagnosticPositiveInt(
        diagnostics['nextReceiptSectionNumber'],
      );
      final orderPolicy = _diagnosticToken(
        diagnostics['receiptSectionOrderPolicy']?.toString() ?? '',
      );
      final ghostPolicy = _diagnosticToken(
        diagnostics['previousSectionGhostGuidePolicy']?.toString() ?? '',
      );
      final ghostVisible = _diagnosticBool(
        diagnostics['previousSectionGhostGuideVisible'],
      );
      final retakeOriginalSection = _diagnosticPositiveInt(
        diagnostics['receiptRetakeOriginalSectionNumber'],
      );
      final retakeFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptRetakeFinalSectionNumber'],
      );
      final retakeGuidance = _diagnosticToken(
        diagnostics['receiptRetakeGuidanceCode']?.toString() ?? '',
      );
      final retakePolicy = _diagnosticToken(
        diagnostics['receiptRetakeOrderPolicy']?.toString() ?? '',
      );
      final insertAnchorSection = _diagnosticPositiveInt(
        diagnostics['receiptInsertAfterAnchorSectionNumber'],
      );
      final insertFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptInsertFinalSectionNumber'],
      );
      final insertPolicy = _diagnosticToken(
        diagnostics['receiptInsertOrderPolicy']?.toString() ?? '',
      );
      final manualReorderOriginalSection = _diagnosticPositiveInt(
        diagnostics['receiptManualReorderOriginalSectionNumber'],
      );
      final manualReorderFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptManualReorderFinalSectionNumber'],
      );
      final manualReorderDirection = _diagnosticToken(
        diagnostics['receiptManualReorderDirection']?.toString() ?? '',
      );
      final manualReorderPolicy = _diagnosticToken(
        diagnostics['receiptManualReorderPolicy']?.toString() ?? '',
      );
      if (sectionCount != null) {
        final bucket = sectionCount <= 1
            ? 'single_section'
            : 'multi_section_${sectionCount}_sections';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (nextSection != null && nextSection > 1) {
        final bucket = nextSection > 9
            ? 'next_section_10_plus'
            : 'next_section_$nextSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (retakeOriginalSection != null) {
        final bucket = retakeOriginalSection > 9
            ? 'retake_original_section_10_plus'
            : 'retake_original_section_$retakeOriginalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (retakeFinalSection != null) {
        final bucket = retakeFinalSection > 9
            ? 'retake_final_section_10_plus'
            : 'retake_final_section_$retakeFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (insertAnchorSection != null) {
        final bucket = insertAnchorSection > 9
            ? 'insert_anchor_section_10_plus'
            : 'insert_anchor_section_$insertAnchorSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (insertFinalSection != null) {
        final bucket = insertFinalSection > 9
            ? 'insert_final_section_10_plus'
            : 'insert_final_section_$insertFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (manualReorderOriginalSection != null) {
        final bucket = manualReorderOriginalSection > 9
            ? 'manual_reorder_original_section_10_plus'
            : 'manual_reorder_original_section_$manualReorderOriginalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (manualReorderFinalSection != null) {
        final bucket = manualReorderFinalSection > 9
            ? 'manual_reorder_final_section_10_plus'
            : 'manual_reorder_final_section_$manualReorderFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      for (final invalidCode in _receiptRetakeInvalidOrderCodes(
        diagnostics: diagnostics,
        originalSection: retakeOriginalSection,
        finalSection: retakeFinalSection,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      for (final invalidCode in _receiptInsertInvalidOrderCodes(
        diagnostics: diagnostics,
        anchorSection: insertAnchorSection,
        finalSection: insertFinalSection,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      if (orderPolicy != 'unknown') {
        counts['policy_$orderPolicy'] =
            (counts['policy_$orderPolicy'] ?? 0) + 1;
      }
      if (retakePolicy != 'unknown') {
        counts['retake_policy_$retakePolicy'] =
            (counts['retake_policy_$retakePolicy'] ?? 0) + 1;
      }
      if (insertPolicy != 'unknown') {
        counts['insert_policy_$insertPolicy'] =
            (counts['insert_policy_$insertPolicy'] ?? 0) + 1;
      }
      if (manualReorderPolicy != 'unknown') {
        counts['manual_reorder_policy_$manualReorderPolicy'] =
            (counts['manual_reorder_policy_$manualReorderPolicy'] ?? 0) + 1;
      }
      if (manualReorderDirection != 'unknown') {
        counts['manual_reorder_direction_$manualReorderDirection'] =
            (counts['manual_reorder_direction_$manualReorderDirection'] ?? 0) +
            1;
      }
      if (retakeGuidance != 'unknown') {
        counts['retake_guidance_$retakeGuidance'] =
            (counts['retake_guidance_$retakeGuidance'] ?? 0) + 1;
      }
      if (ghostPolicy != 'unknown') {
        counts['ghost_policy_$ghostPolicy'] =
            (counts['ghost_policy_$ghostPolicy'] ?? 0) + 1;
      }
      if (ghostVisible != null) {
        final bucket = ghostVisible
            ? 'ghost_guide_visible'
            : 'ghost_guide_hidden';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      for (final code in _receiptRetakeContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
      for (final code in _receiptInsertContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
      for (final code in _receiptManualReorderContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  String get receiptSectionOrderOutcome {
    final counts = receiptSectionOrderCounts;
    if (counts.isEmpty) return 'unknown';
    if (counts.keys.any((key) => key.startsWith('retake_invalid_'))) {
      return 'retake_order_invalid';
    }
    if (counts.keys.any((key) => key.startsWith('insert_invalid_'))) {
      return 'insert_order_invalid';
    }
    if ((counts['policy_top_to_bottom_numbered_sections'] ?? 0) > 0 &&
        (counts['ghost_guide_visible'] ?? 0) > 0) {
      return 'numbered_sections_with_ghost_guide';
    }
    if ((counts['policy_top_to_bottom_numbered_sections'] ?? 0) > 0) {
      return 'numbered_sections_top_to_bottom';
    }
    if ((counts['retake_preserved_original_slot'] ?? 0) > 0) {
      return 'retake_order_preserved';
    }
    if ((counts['insert_preserved_anchor_slot'] ?? 0) > 0) {
      return 'insert_order_preserved';
    }
    if ((counts['manual_reorder_preserved_photo_path'] ?? 0) > 0) {
      return 'manual_reorder_preserved';
    }
    if (counts.keys.any((key) => key.startsWith('multi_section_'))) {
      return 'multi_section_order_tracked';
    }
    return 'single_section_or_unordered';
  }

  String get receiptSectionOrderEvidenceLabel {
    final counts = receiptSectionOrderCounts;
    if (counts.isEmpty) return 'section_order=unknown';
    final outcome = receiptSectionOrderOutcome;
    final sectionCount = counts.entries
        .where((entry) => entry.key.startsWith('multi_section_'))
        .fold<int>(0, (total, entry) => total + entry.value);
    final ghost = (counts['ghost_guide_visible'] ?? 0) > 0
        ? 'ghost_visible'
        : (counts['ghost_guide_hidden'] ?? 0) > 0
        ? 'ghost_hidden'
        : 'ghost_unknown';
    final label =
        'section_order=$outcome;multi_section_photos=$sectionCount;$ghost';
    if (outcome == 'retake_order_invalid') {
      return '$label;retake_invalid';
    }
    if (outcome == 'insert_order_invalid') {
      return '$label;insert_invalid';
    }
    if ((counts['retake_preserved_original_slot'] ?? 0) > 0) {
      return '$label;retake_preserved';
    }
    if ((counts['insert_preserved_anchor_slot'] ?? 0) > 0) {
      return '$label;insert_preserved';
    }
    if ((counts['manual_reorder_preserved_photo_path'] ?? 0) > 0) {
      return '$label;manual_reorder_preserved';
    }
    return label;
  }
}
