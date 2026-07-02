part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryPhotoPreparationTelemetry
    on _ExpenseReceiptEntryScreenState {
  void _recordReceiptPhotoPreparationTelemetry(
    ReceiptPhotoReviewResult result,
  ) {
    final diagnostics = result.preparationDiagnosticsByOcrPath.values.toList(
      growable: false,
    );
    final captureDiagnostics = result.captureDiagnosticsByPhotoPath.values
        .toList(growable: false);
    final enhancedCount = diagnostics
        .where((item) => item['usedEnhancedOcrSource'] == true)
        .length;
    final cleanupActions = <String>{};
    for (final diagnostic in diagnostics) {
      final actions = diagnostic['cleanupActions'];
      if (actions is Iterable) {
        cleanupActions.addAll(
          actions
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty),
        );
      }
    }
    final metadata = _receiptPhotoPreparationTelemetryMetadata(
      result: result,
      diagnostics: diagnostics,
      captureDiagnostics: captureDiagnostics,
      enhancedCount: enhancedCount,
      cleanupActions: cleanupActions,
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.ocrStarted,
      metadata: metadata,
    );
  }
}
