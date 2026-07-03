part of 'receipt_native_capture_staging.dart';

extension _ReceiptNativeCaptureStagingDiagnostics
    on ReceiptNativeCaptureStaging {
  Map<String, Object?> _stagedPhotoDiagnostics({
    required Map<String, Object?> baseDiagnostics,
    required ReceiptAttachmentRecord staged,
    required int index,
    required int stagedPhotoCount,
    required String recoveryManifestPath,
  }) {
    final bottomEdgeEvidence = _bottomEdgeEvidence(baseDiagnostics);
    return Map.unmodifiable({
      ...baseDiagnostics,
      ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected:
          bottomEdgeEvidence.detected,
      ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus:
          bottomEdgeEvidence.status,
      'receiptBottomEdgeEvidenceSource': bottomEdgeEvidence.source,
      'receiptBottomEdgeEvidenceReason': bottomEdgeEvidence.reason,
      'nativeCapturePersistedLocally': true,
      'nativeCaptureStage': 'staged_for_receipt_review',
      'nativeCaptureRecoveryPrivacyScope': 'summary_only_no_receipt_content',
      'nativeCaptureRecoveryContentPolicy':
          'no_receipt_text_no_customer_content',
      'nativeCaptureRecoveryAttachmentState': 'staged_not_attached',
      'nativeCaptureRecoveryResumeAction':
          'resume_review_before_receipt_details',
      'nativeCaptureRecoveryResumeCheckpoint':
          'after_native_capture_before_ocr',
      'nativeCaptureRecoveryOcrSourcePolicy':
          'original_staged_photo_used_before_data_saver_copy',
      'nativeCaptureRecoveryCleanupPolicy':
          'discard_only_after_accept_or_user_discard_or_old_cleanup',
      'nativeCaptureRecoveryWriteOrder':
          'copy_photo_then_manifest_then_hive_index',
      'nativeCaptureRecoveryUserSafeExit':
          'leave_without_attaching_keeps_local_recovery',
      'nativeCaptureRecoveryCoveredInterruptions': _coveredInterruptionCases,
      'nativeCaptureStagedPhotoIndex': index,
      'nativeCaptureStagedPhotoNumber': index + 1,
      'nativeCaptureStagedPhotoCount': stagedPhotoCount,
      'nativeCaptureRecoveryManifestCreated': recoveryManifestPath
          .trim()
          .isNotEmpty,
      'nativeCaptureAttachmentStorageState': staged.storageState.name,
      'nativeCaptureAttachmentKind': staged.kind.name,
      'nativeCaptureDataSaverLevel': staged.dataSaverLevel.name,
      'nativeCaptureByteSizeBucket': _byteSizeBucket(staged.byteSize ?? 0),
      'nativeCaptureHashPresent': staged.fileHash.trim().isNotEmpty,
    });
  }

  _ReceiptBottomEdgeEvidence _bottomEdgeEvidence(
    Map<String, Object?> diagnostics,
  ) {
    final explicit = _boolValue(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected],
    );
    if (explicit != null) {
      return _ReceiptBottomEdgeEvidence(
        detected: explicit,
        status: explicit ? 'present' : 'missing',
        source: 'native_explicit',
        reason: explicit
            ? 'native_reported_bottom_edge_present'
            : 'native_reported_bottom_edge_missing',
      );
    }
    final explicitStatus =
        diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus]
            ?.toString()
            .trim()
            .toLowerCase();
    if (explicitStatus != null && explicitStatus.isNotEmpty) {
      if (_missingBottomEdgeStatuses.contains(explicitStatus)) {
        return _ReceiptBottomEdgeEvidence(
          detected: false,
          status: explicitStatus,
          source: 'native_status',
          reason: 'native_status_bottom_edge_missing',
        );
      }
      if (_presentBottomEdgeStatuses.contains(explicitStatus)) {
        return _ReceiptBottomEdgeEvidence(
          detected: true,
          status: explicitStatus,
          source: 'native_status',
          reason: 'native_status_bottom_edge_present',
        );
      }
    }
    final bottomEdgeScore = _doubleValue(
      diagnostics[ReceiptCaptureDiagnosticKeys.latestCapturedBottomEdgeScore],
    );
    if (bottomEdgeScore != null && bottomEdgeScore >= 0) {
      if (bottomEdgeScore < .20) {
        return const _ReceiptBottomEdgeEvidence(
          detected: false,
          status: 'missing',
          source: 'native_bottom_edge_score',
          reason: 'bottom_edge_score_below_missing_threshold',
        );
      }
      if (bottomEdgeScore >= .42) {
        return const _ReceiptBottomEdgeEvidence(
          detected: true,
          status: 'present',
          source: 'native_bottom_edge_score',
          reason: 'bottom_edge_score_above_present_threshold',
        );
      }
    }
    final framingSignal =
        diagnostics[ReceiptCaptureDiagnosticKeys.latestFramingSignal]
            ?.toString()
            .trim();
    final perspectiveReadiness =
        diagnostics[ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness]
            ?.toString()
            .trim();
    final edgeCoverage = _doubleValue(
      diagnostics[ReceiptCaptureDiagnosticKeys.latestEdgeCoverage],
    );
    final cutOffRisk =
        framingSignal == ReceiptNativeCoverageSignalValues.possiblyCutOff ||
        perspectiveReadiness ==
            ReceiptNativeCoverageSignalValues.perspectiveSkippedCutOffRisk;
    if (cutOffRisk && edgeCoverage != null && edgeCoverage < .45) {
      return const _ReceiptBottomEdgeEvidence(
        detected: false,
        status: 'possibly_cut_off',
        source: 'native_framing_edge_coverage',
        reason: 'cut_off_signal_with_low_edge_coverage',
      );
    }
    if (cutOffRisk && bottomEdgeScore == null && edgeCoverage == null) {
      return const _ReceiptBottomEdgeEvidence(
        detected: false,
        status: 'possibly_cut_off',
        source: 'native_framing_unusable_numbers',
        reason: 'cut_off_signal_with_unusable_edge_evidence',
      );
    }
    if (framingSignal == ReceiptNativeCoverageSignalValues.framingOk &&
        edgeCoverage != null &&
        edgeCoverage >= .55) {
      return const _ReceiptBottomEdgeEvidence(
        detected: true,
        status: 'present',
        source: 'native_framing_edge_coverage',
        reason: 'framing_ok_with_edge_coverage',
      );
    }
    return const _ReceiptBottomEdgeEvidence(
      detected: true,
      status: 'unknown_assume_present_until_ocr_evidence',
      source: 'native_default',
      reason: 'no_bottom_edge_risk_signal',
    );
  }
}
