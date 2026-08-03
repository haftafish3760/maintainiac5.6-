part of 'receipt_photo_review_screen.dart';

extension _ReceiptPreviewActionTrayStatus on _ReceiptPreviewActionTray {
  int get effectiveSelectedIndex {
    if (photoPaths.isEmpty) return 0;
    return selectedIndex.clamp(0, photoPaths.length - 1);
  }

  IconData get statusIcon {
    final nativeWarning = nativeCaptureReviewWarning;
    if (nativeWarning != null) return nativeWarning.icon;
    final coverageDecision = coverageDecisionForSelectedPhoto;
    if (coverageDecision.status == ReceiptPhotoCoverageStatus.likelyCutOff) {
      return Icons.add_photo_alternate_rounded;
    }
    if (coverageDecision.status == ReceiptPhotoCoverageStatus.maybeContinues) {
      return Icons.receipt_long_rounded;
    }
    final quality = selectedQualityCheck;
    if (quality?.hasCriticalIssue == true) {
      if (quality!.isTooDark) return Icons.light_mode_rounded;
      if (quality.isTooBright) return Icons.flare_rounded;
      return Icons.warning_amber_rounded;
    }
    if (quality?.needsReview == true) return Icons.info_outline_rounded;
    if (photoPaths.length > 1) return Icons.layers_rounded;
    return Icons.receipt_long_rounded;
  }

  Color get statusColor {
    final nativeWarning = nativeCaptureReviewWarning;
    if (nativeWarning != null) return nativeWarning.color;
    final coverageDecision = coverageDecisionForSelectedPhoto;
    if (coverageDecision.status == ReceiptPhotoCoverageStatus.likelyCutOff) {
      return const Color(0xFFFFD166);
    }
    if (coverageDecision.status == ReceiptPhotoCoverageStatus.maybeContinues) {
      return const Color(0xFFFFD166);
    }
    final quality = selectedQualityCheck;
    if (quality?.hasCriticalIssue == true) return const Color(0xFFFFB020);
    if (quality != null && quality.reviewScore >= 70) {
      return const Color(0xFF8EF6A4);
    }
    if (quality?.needsReview == true) return const Color(0xFFFFD166);
    return const Color(0xFF8EF6A4);
  }

  String get statusText {
    final photoCount = photoPaths.length;
    final recoveryPrefix = captureSourcePrefix;
    final memoryPolicyCopy = captureMemoryPolicyCopy;
    final editedPhotoCopy = editedPhotoCopyForSelectedPhoto;
    final coverageDecision = coverageDecisionForSelectedPhoto;
    if (photoCount > 1) {
      final sectionGuidance = _ReceiptPhotoSectionLabels.selectedReviewGuidance(
        selectedIndex: effectiveSelectedIndex,
        total: photoCount,
      );
      final sectionAction = _ReceiptPhotoSectionLabels.selectedReviewAction(
        selectedIndex: effectiveSelectedIndex,
        total: photoCount,
      );
      final matchStatus = multiPhotoMatchStatusCopy;
      if (coverageDecision.shouldPromptForMorePhotos) {
        final addPhotoAction = coverageDecision.isMissingBottomEdgeAndTotals
            ? 'add the bottom receipt section and repeat 3-5 readable lines in the top reference strip'
            : 'add the next receipt section now';
        return '$recoveryPrefix$photoCount receipt sections are saved locally. '
            '$sectionGuidance $sectionAction $matchStatus '
            '${coverageDecision.title}: $addPhotoAction, or use this receipt only if '
            'these photos already show the full receipt.$editedPhotoCopy$memoryPolicyCopy';
      }
      return '$recoveryPrefix$photoCount receipt sections are saved locally. '
          '$sectionGuidance $sectionAction $matchStatus Use this receipt when '
          'the full receipt is visible.'
          '$editedPhotoCopy$memoryPolicyCopy';
    }
    final nativeWarning = nativeCaptureReviewWarning;
    if (nativeWarning != null) {
      return '${nativeWarning.message} ${nativeWarning.primaryActionLabel} '
          'is recommended before continuing.$editedPhotoCopy';
    }
    if (coverageDecision.shouldPromptForMorePhotos) {
      return '${coverageDecision.title} Add another photo if any part of the '
          'receipt is missing.$editedPhotoCopy';
    }
    final readinessCopy = _ReceiptCaptureReadinessReviewCopy.fromDiagnostics(
      selectedCaptureDiagnostics,
    );
    if (readinessCopy != null) {
      return '${readinessCopy.previewStatus}$editedPhotoCopy';
    }
    final quality = selectedQualityCheck;
    if (quality != null) {
      return '${quality.userFacingStatusLabel} Check the store, date, total, '
          'and line details before continuing.$editedPhotoCopy';
    }
    return 'Check the store, date, total, and line details before '
        'continuing.$editedPhotoCopy';
  }

  String get captureSourcePrefix {
    if (isPhoneCameraBackupCapture) {
      return 'Phone camera backup capture; still reviewed in Maintainiac. ';
    }
    if (isLocalRecoveryCapture) {
      return 'Saved locally for recovery. ';
    }
    return '';
  }

  bool get isPhoneCameraBackupCapture {
    final diagnostics = selectedCaptureDiagnostics;
    if (diagnostics == null) return false;
    return diagnostics['captureFlow'] == 'phone_camera_backup_receipt_photo' ||
        diagnostics['phoneCameraBackupUsed'] == true;
  }

  bool get isLocalRecoveryCapture {
    final diagnostics = selectedCaptureDiagnostics;
    if (diagnostics == null) return false;
    final captureSurface = diagnostics['captureSurface']?.toString() ?? '';
    final captureFlow = diagnostics['captureFlow']?.toString() ?? '';
    return captureSurface.startsWith('maintainiac_native_') ||
        captureFlow == 'maintainiac_native_receipt_camera' ||
        diagnostics.containsKey('nativeRecoveryFreshnessBucket');
  }

  String get captureMemoryPolicyCopy {
    final diagnostics = selectedCaptureDiagnostics;
    if (diagnostics == null) return '';
    final policy = diagnostics['nativeCaptureMemoryPolicy']?.toString() ?? '';
    final storageConstrained = diagnostics['storageConstrained'] == true;
    final olderPhonePolicy = policy.contains('older_phone');
    final storageSaverPolicy =
        storageConstrained ||
        policy.contains('small_local_proof') ||
        policy.contains('tiny_local_proof');
    if (!olderPhonePolicy && !storageSaverPolicy) return '';
    return ' Maintainiac reads the full captured photo first; smaller saved copies are only for storage and recovery.';
  }

  String get editedPhotoCopyForSelectedPhoto {
    final diagnostics = selectedCaptureDiagnostics;
    if (diagnostics == null || diagnostics['userEditedPhoto'] != true) {
      return '';
    }
    final action = diagnostics['photoEditAction']?.toString().trim();
    final editLabel = switch (action) {
      'manual_crop' => 'Crop edit',
      'manual_rotate' => 'Rotation edit',
      _ => 'Photo edit',
    };
    final sourceCopy = diagnostics['photoEditReplacedOriginal'] == true
        ? ' This edited copy is the one Maintainiac will read.'
        : '';
    return ' $editLabel applied.$sourceCopy';
  }

  String get multiPhotoMatchStatusCopy {
    if (stitchPreviewInFlight) {
      return 'Putting your receipt photos together.';
    }
    final preview = stitchPreview;
    if (preview == null) {
      return 'Continue when these receipt sections are in top-to-bottom order.';
    }
    if (preview.didStitch) {
      return 'Your receipt is ready as one combined image.';
    }
    if (preview.usedFallback) {
      return 'Keep the photos in order. You can adjust them or retake one before continuing.';
    }
    return 'Review the receipt sections before continuing.';
  }

  ReceiptPhotoCoverageDecision get coverageDecisionForSelectedPhoto {
    return ReceiptPhotoCoverageDecision.fromSignals(
      quality: selectedQualityCheck,
      diagnostics: selectedCaptureDiagnostics,
    );
  }

  _NativeCaptureReviewWarning? get nativeCaptureReviewWarning {
    final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
      selectedCaptureDiagnostics,
    );
    if (warning == null) return null;
    return _NativeCaptureReviewWarning.fromModel(warning);
  }
}
