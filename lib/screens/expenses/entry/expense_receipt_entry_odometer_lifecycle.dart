part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptOdometerLifecycle on _ExpenseReceiptEntryScreenState {
  Future<_ReceiptOdometerCommit?> _prepareReceiptOdometerCommit(
    ExpenseReceiptRecord receipt,
  ) async {
    final reading = receipt.odometerReading;
    if (reading == null || _isEditingReceipt || receipt.vehicleId == null) {
      return const _ReceiptOdometerCommit.none();
    }
    final odometer = GlobalOdometerScope.of(context);
    if (receipt.vehicleId != odometer.vehicleId) {
      return const _ReceiptOdometerCommit.none();
    }

    OdometerMileageReview? mileageReview;
    OdometerCorrectionReview? correctionReview;
    var confirmSuspicious = false;
    final enteredAt = receipt.sortDate;
    while (true) {
      final preview = odometer.updateFromText(
        reading.toString(),
        enteredAt: enteredAt,
        confirmSuspicious: confirmSuspicious,
        mileageReview: mileageReview,
        correctionReview: correctionReview,
        workProfileId: receipt.workProfileId,
        sourceType: 'expense_receipt',
        sourceId: receipt.id,
        commit: false,
      );
      if (preview.requiresCorrectionReview) {
        correctionReview = await collectOdometerCorrectionReview(
          context,
          currentReading: preview.currentReading ?? odometer.confirmedReading,
          candidateReading: preview.candidateReading ?? reading,
        );
        if (!mounted || correctionReview == null) return null;
        continue;
      }
      if (preview.requiresMileageReview) {
        mileageReview = await collectOdometerMileageReview(
          context,
          preview.deltaMiles ?? 0,
        );
        if (!mounted || mileageReview == null) return null;
        continue;
      }
      if (preview.requiresConfirmation) {
        confirmSuspicious = await confirmSuspiciousOdometerReading(
          context,
          preview.message,
        );
        if (!mounted || !confirmSuspicious) return null;
        continue;
      }
      if (!preview.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preview.message ?? 'Check the odometer reading.'),
          ),
        );
        return null;
      }
      return _ReceiptOdometerCommit(
        controller: odometer,
        rawReading: reading.toString(),
        enteredAt: enteredAt,
        confirmSuspicious: confirmSuspicious,
        mileageReview: mileageReview,
        correctionReview: correctionReview,
        workProfileId: receipt.workProfileId,
        receiptId: receipt.id,
      );
    }
  }
}

class _ReceiptOdometerCommit {
  const _ReceiptOdometerCommit.none()
    : controller = null,
      rawReading = '',
      enteredAt = null,
      confirmSuspicious = false,
      mileageReview = null,
      correctionReview = null,
      workProfileId = null,
      receiptId = '';

  const _ReceiptOdometerCommit({
    required this.controller,
    required this.rawReading,
    required this.enteredAt,
    required this.confirmSuspicious,
    required this.mileageReview,
    required this.correctionReview,
    required this.workProfileId,
    required this.receiptId,
  });

  final GlobalOdometerController? controller;
  final String rawReading;
  final DateTime? enteredAt;
  final bool confirmSuspicious;
  final OdometerMileageReview? mileageReview;
  final OdometerCorrectionReview? correctionReview;
  final String? workProfileId;
  final String receiptId;

  OdometerUpdateResult commit() {
    final odometer = controller;
    if (odometer == null) {
      return const OdometerUpdateResult.success(
        message: 'Receipt odometer was not changed.',
      );
    }
    return odometer.updateFromText(
      rawReading,
      enteredAt: enteredAt,
      confirmSuspicious: confirmSuspicious,
      mileageReview: mileageReview,
      correctionReview: correctionReview,
      workProfileId: workProfileId,
      sourceType: 'expense_receipt',
      sourceId: receiptId,
    );
  }
}
