/// Explicit audit-correction confirmation for lower odometer readings.
///
/// Owns the user-confirmed transition from a selected correction reason to
/// the existing durable odometer audit API. Does not reinterpret mileage,
/// alter GPS evidence, or remove original history. Consumed by
/// OdometerEntrySheet when its correction-review panel requires this flow.
part of 'odometer_entry_sheet.dart';

extension _OdometerEntryAuditCorrectionActions on _OdometerEntrySheetState {
  Future<void> _confirmAndApplyAuditCorrection({
    required int reading,
    required OdometerCorrectionReview review,
  }) async {
    final currentReading = GlobalOdometerScope.of(context).confirmedReading;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review odometer correction'),
        content: Text(
          'This will record an audited correction from $currentReading to '
          '$reading miles. The original entry stays in the vehicle history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apply correction'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await GlobalOdometerScope.of(
        context,
      ).applyAuditCorrection(rawValue: '$reading', correctionReview: review);
    } on ArgumentError catch (error) {
      _showAuditCorrectionError(error.message?.toString());
      return;
    }
    if (!mounted) return;
    widget.onSaved?.call();
    Navigator.of(context).pop(reading);
  }
}
