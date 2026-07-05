class ReceiptCaptureDiagnosticPublishPolicy {
  const ReceiptCaptureDiagnosticPublishPolicy();

  bool shouldPublish({
    required bool improvementOptIn,
    required Map<String, Object?> diagnostic,
  }) {
    return improvementOptIn && diagnostic.isNotEmpty;
  }

  Map<String, Object?> envelope({
    required bool improvementOptIn,
    required Map<String, Object?> diagnostic,
  }) {
    if (!shouldPublish(
      improvementOptIn: improvementOptIn,
      diagnostic: diagnostic,
    )) {
      return const {};
    }
    return Map<String, Object?>.unmodifiable({
      'cameraDiagnosticsImprovementOptIn': true,
      'adminDiagnosticOwnerImagePreviewAllowed': false,
      ...diagnostic,
    });
  }
}
