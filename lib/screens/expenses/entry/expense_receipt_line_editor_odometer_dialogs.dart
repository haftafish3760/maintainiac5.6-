part of 'expense_receipt_entry_screen.dart';

extension _ReceiptLineEditorOdometerDialogs on _ReceiptLineEditorSheetState {
  Future<bool> _confirmSuspiciousOdometer(String? message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'Confirm Odometer Reading',
          style: TextStyle(color: Color(0xFFF0F4F2)),
        ),
        content: Text(
          message ??
              'This odometer reading is outside the expected range. Confirm the vehicle reading before saving.',
          style: const TextStyle(color: Color(0xFFC8D0D3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<OdometerMileageReview?> _collectMileageReview(int deltaMiles) async {
    OdometerMileageUse? selectedUse;
    final businessMilesController = TextEditingController();
    final review = await showDialog<OdometerMileageReview>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF101719),
          title: const Text(
            'Count These Miles',
            style: TextStyle(color: Color(0xFFF0F4F2)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  odometerMileageReviewPrompt(deltaMiles),
                  style: const TextStyle(color: Color(0xFFC8D0D3)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OdometerMileageUse.values.map((use) {
                    final selected = selectedUse == use;
                    return ChoiceChip(
                      label: Text(use.label),
                      selected: selected,
                      selectedColor: const Color(0xFF2C7A55),
                      backgroundColor: const Color(0xFF1B2427),
                      side: const BorderSide(color: Color(0xFF344247)),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFE3E8EA),
                        fontWeight: FontWeight.w800,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          selectedUse = use;
                          if (use != OdometerMileageUse.split) {
                            businessMilesController.clear();
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (selectedUse == OdometerMileageUse.split) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: businessMilesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Business miles',
                      helperText:
                          'The remaining miles will be counted as personal.',
                      filled: true,
                      fillColor: Color(0xFFAAB4B9),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedUse == null
                  ? null
                  : () {
                      Navigator.of(context).pop(
                        OdometerMileageReview(
                          use: selectedUse!,
                          businessMiles: selectedUse == OdometerMileageUse.split
                              ? int.tryParse(
                                  businessMilesController.text.trim(),
                                )
                              : null,
                        ),
                      );
                    },
              child: const Text('Save Miles'),
            ),
          ],
        ),
      ),
    );
    businessMilesController.dispose();
    return review;
  }

  Future<OdometerCorrectionReview?> _collectCorrectionReview({
    required int currentReading,
    required int candidateReading,
  }) async {
    OdometerCorrectionReason? selectedReason;
    final review = await showDialog<OdometerCorrectionReview>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF101719),
          title: const Text(
            'Review Odometer Reading',
            style: TextStyle(color: Color(0xFFF0F4F2)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  odometerCorrectionReviewPrompt(
                    currentReading: currentReading,
                    candidateReading: candidateReading,
                  ),
                  style: const TextStyle(color: Color(0xFFC8D0D3)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OdometerCorrectionReason.values.map((reason) {
                    final selected = selectedReason == reason;
                    return ChoiceChip(
                      label: Text(reason.label),
                      selected: selected,
                      selectedColor: const Color(0xFFFFC857),
                      backgroundColor: const Color(0xFF1B2427),
                      side: const BorderSide(color: Color(0xFF344247)),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.black
                            : const Color(0xFFE3E8EA),
                        fontWeight: FontWeight.w800,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          selectedReason = reason;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (selectedReason ==
                        OdometerCorrectionReason.previousEntryWrong ||
                    selectedReason == OdometerCorrectionReason.odometerReplaced)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'This needs the full odometer correction flow before it can change mileage records.',
                      style: TextStyle(color: Color(0xFFFFD27A)),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.of(
                        context,
                      ).pop(OdometerCorrectionReview(reason: selectedReason!));
                    },
              child: const Text('Save Review'),
            ),
          ],
        ),
      ),
    );
    return review;
  }
}
