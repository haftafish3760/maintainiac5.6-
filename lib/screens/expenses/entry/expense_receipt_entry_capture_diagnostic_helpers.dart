part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryCaptureDiagnosticHelpers
    on _ExpenseReceiptEntryScreenState {
  void _recordReceiptCaptureDiagnostic(Map<String, Object?> diagnostic) {
    final stage = _safeTelemetryToken(
      diagnostic['nativeCaptureFailureStage'],
      fallback: 'native_camera_unknown',
    );
    final reason = _safeTelemetryToken(
      diagnostic['nativeCaptureFailureReason'],
      fallback: 'native_camera_unexpected_failure',
    );
    final action = _safeTelemetryToken(
      diagnostic['nativeCaptureRecoveryAction'],
      fallback: 'retry_or_import_existing_photo',
    );
    if (_isNonFailureReceiptCaptureDiagnostic(reason)) {
      _recordNonFailureReceiptCaptureDiagnostic(
        diagnostic,
        stage: stage,
        reason: reason,
        action: action,
      );
      return;
    }
    final userDiscardedRecovery = reason == 'user_discarded_recovery';
    ExpenseScreenTelemetryRecorder.record(
      context,
      userDiscardedRecovery
          ? ExpenseTelemetryEventType.addExpenseAbandoned
          : ExpenseTelemetryEventType.imageAttachFailure,
      failureKind: reason,
      diagnostic: ExpenseFailureDiagnostic(
        workflowStep: ExpenseWorkflowStep.receiptAttachment,
        failedAt: stage,
        confirmedCause: reason,
        causeStatus: ExpenseFailureCauseStatus.confirmed,
        evidence: action,
        abandoned: userDiscardedRecovery,
      ),
      metadata: {
        'captureFlow': 'maintainiac_native_receipt_camera',
        'nativeCaptureFailureStage': stage,
        'nativeCaptureFailureReason': reason,
        'nativeCaptureRecoveryAction': action,
        if (diagnostic['nativeCameraEngine'] != null)
          'nativeCameraEngine': _safeTelemetryToken(
            diagnostic['nativeCameraEngine'],
            fallback: 'unknown',
          ),
        if (diagnostic['nativeCameraAvailable'] is bool)
          'nativeCameraAvailable': diagnostic['nativeCameraAvailable'],
        if (diagnostic['nativeCameraPermissionGranted'] is bool)
          'nativeCameraPermissionGranted':
              diagnostic['nativeCameraPermissionGranted'],
        if (diagnostic['nativeCameraHasRearCamera'] is bool)
          'nativeCameraHasRearCamera': diagnostic['nativeCameraHasRearCamera'],
        if (diagnostic['nativeRecoveryDiscardedPhotoCount'] is int)
          'nativeRecoveryDiscardedPhotoCount':
              diagnostic['nativeRecoveryDiscardedPhotoCount'],
        if (diagnostic['nativeRecoveryDiscardedMultipleSections'] is bool)
          'nativeRecoveryDiscardedMultipleSections':
              diagnostic['nativeRecoveryDiscardedMultipleSections'],
      },
    );
  }

  void _recordNonFailureReceiptCaptureDiagnostic(
    Map<String, Object?> diagnostic, {
    required String stage,
    required String reason,
    required String action,
  }) {
    final recoveryStage = _safeTelemetryToken(
      diagnostic['nativeRecoveryLastStage'],
      fallback: '',
    );
    final recoveryReason = _safeTelemetryToken(
      diagnostic['nativeRecoveryLastReason'],
      fallback: '',
    );
    if (recoveryStage.isEmpty && recoveryReason.isEmpty) return;
    final reviewedPhotoCount = _intTelemetryValue(
      diagnostic['nativeRecoveryReviewedPhotoCount'],
    );
    final ocrSourcePhotoCount = _intTelemetryValue(
      diagnostic['nativeRecoveryOcrSourcePhotoCount'],
    );
    final recoveryFreshness = _safeTelemetryToken(
      diagnostic['nativeRecoveryFreshness'],
      fallback: '',
    );
    final recoveryStorageStatus = _safeTelemetryToken(
      diagnostic['nativeRecoveryStorageStatus'],
      fallback: '',
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.imageAttachSuccess,
      metadata: {
        'captureFlow': 'maintainiac_native_receipt_camera',
        'nativeCaptureFailureStage': stage,
        'nativeCaptureFailureReason': reason,
        'nativeCaptureRecoveryAction': action,
        if (recoveryStage.isNotEmpty)
          'nativeRecoveryResumeStatusBuckets': {recoveryStage: 1},
        if (recoveryFreshness.isNotEmpty)
          'nativeRecoveryFreshnessBuckets': {recoveryFreshness: 1},
        if (recoveryStorageStatus.isNotEmpty)
          'nativeRecoveryStorageStatusBuckets': {recoveryStorageStatus: 1},
        if (reviewedPhotoCount > 0)
          'nativeRecoveryRecoveredPhotoTotal': reviewedPhotoCount,
        if (reviewedPhotoCount > 1) 'nativeRecoveryMultipleSectionCount': 1,
        if (ocrSourcePhotoCount > 0) 'ocrSourceCount': ocrSourcePhotoCount,
        if (diagnostic['nativeRecoveryReviewAccepted'] is bool)
          'nativeRecoveryReviewAccepted':
              diagnostic['nativeRecoveryReviewAccepted'],
        if (diagnostic['nativeRecoveryReviewClosed'] is bool)
          'nativeRecoveryReviewClosed':
              diagnostic['nativeRecoveryReviewClosed'],
        if (diagnostic['nativeRecoveryOcrPending'] is bool)
          'nativeRecoveryOcrPending': diagnostic['nativeRecoveryOcrPending'],
      },
    );
  }

  bool _isNonFailureReceiptCaptureDiagnostic(String reason) {
    return switch (reason) {
      'review_accepted' ||
      'recovery_review_accepted' ||
      'recovery_review_closed' ||
      'user_closed_review' ||
      'user_canceled_before_photo' ||
      'recovery_context_closed_before_review' ||
      'recovery_context_closed_after_review' => true,
      _ => false,
    };
  }

  String _safeTelemetryToken(Object? value, {required String fallback}) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return fallback;
    final safe = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
    return safe.isEmpty ? fallback : safe;
  }

  int _intTelemetryValue(Object? value) {
    if (value is int) return value;
    final parsed = switch (value) {
      num() when value.isFinite => value,
      String() => double.tryParse(value.trim()),
      _ => null,
    };
    if (parsed == null || !parsed.isFinite) return 0;
    return parsed.toInt();
  }
}
