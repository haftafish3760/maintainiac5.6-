part of 'odometer_entry_sheet.dart';

class _CorrectionReviewPanel extends StatelessWidget {
  const _CorrectionReviewPanel({
    required this.currentReading,
    required this.candidateReading,
    required this.selectedReason,
    required this.onReasonChanged,
  });

  final int currentReading;
  final int candidateReading;
  final OdometerCorrectionReason? selectedReason;
  final ValueChanged<OdometerCorrectionReason> onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final difference = currentReading - candidateReading;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please review this odometer reading',
              style: TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This reading is ${_comma(difference)} miles below your '
              'previous entry of ${_comma(currentReading)} miles.',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the option that best explains the difference.',
              style: TextStyle(
                color: Color(0xFFE3E8EA),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...OdometerCorrectionReason.values.map((reason) {
              final selected = selectedReason == reason;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ChoiceChip(
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(reason.label),
                    ),
                    selected: selected,
                    onSelected: (_) => onReasonChanged(reason),
                    selectedColor: const Color(0xFFFFC857),
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : const Color(0xFFE3E8EA),
                      fontWeight: FontWeight.w800,
                    ),
                    backgroundColor: const Color(0xFF1B2427),
                    side: const BorderSide(color: Color(0xFF526168)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              );
            }),
            if (selectedReason?.requiresDedicatedCorrectionFlow == true)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'A guided correction review will preserve the original entry and its audit history.',
                  style: TextStyle(
                    color: Color(0xFFFFD27A),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
