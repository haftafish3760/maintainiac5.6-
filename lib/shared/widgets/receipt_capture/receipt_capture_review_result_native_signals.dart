part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNativeSignals on ReceiptPhotoReviewResult {
  String get nativeReceiptReviewDepth {
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final value = diagnostics['reviewDepth']?.toString().trim();
      if (value == 'detailedLines' || value == 'pricesOnly') return value!;
    }
    return 'pricesOnly';
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
      final token = _diagnosticToken(
        diagnostics['photoEditAction']?.toString() ?? 'manual_edit',
      );
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
      if (orderPolicy != 'unknown') {
        counts['policy_$orderPolicy'] =
            (counts['policy_$orderPolicy'] ?? 0) + 1;
      }
      if (retakePolicy != 'unknown') {
        counts['retake_policy_$retakePolicy'] =
            (counts['retake_policy_$retakePolicy'] ?? 0) + 1;
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
    }
    return Map.unmodifiable(counts);
  }

  String get receiptSectionOrderOutcome {
    final counts = receiptSectionOrderCounts;
    if (counts.isEmpty) return 'unknown';
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
    if ((counts['retake_preserved_original_slot'] ?? 0) > 0) {
      return '$label;retake_preserved';
    }
    return label;
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
    return codes;
  }
}
