part of 'expense_receipt_entry_screen.dart';

extension _ReceiptLineEditorOdometerDialogs on _ReceiptLineEditorSheetState {
  Future<bool> _confirmSuspiciousOdometer(String? message) {
    return confirmSuspiciousOdometerReading(context, message);
  }

  Future<OdometerMileageReview?> _collectMileageReview(int deltaMiles) {
    return collectOdometerMileageReview(context, deltaMiles);
  }

  Future<OdometerCorrectionReview?> _collectCorrectionReview({
    required int currentReading,
    required int candidateReading,
  }) {
    return collectOdometerCorrectionReview(
      context,
      currentReading: currentReading,
      candidateReading: candidateReading,
    );
  }
}
