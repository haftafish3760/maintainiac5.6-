part of 'receipt_photo_review_screen.dart';

class _ReceiptManualStitchControls extends StatelessWidget {
  const _ReceiptManualStitchControls({
    required this.pairIndex,
    required this.totalPairs,
    required this.manualOverlapFraction,
    required this.stitchPreview,
    required this.stitchPreviewInFlight,
    required this.disabled,
    required this.onPairSelected,
    required this.onOverlapChanged,
    required this.onClear,
    required this.onOpenOrder,
  });

  final int pairIndex;
  final int totalPairs;
  final double? manualOverlapFraction;
  final ReceiptStitchResult? stitchPreview;
  final bool stitchPreviewInFlight;
  final bool disabled;
  final ValueChanged<int> onPairSelected;
  final ValueChanged<double> onOverlapChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final overlap = manualOverlapFraction ?? .22;
    final percent = (overlap * 100).round();
    final pairCountLabel =
        'Sections ${pairIndex + 1}-${pairIndex + 2} of ${totalPairs + 1}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: disabled || pairIndex == 0
                        ? null
                        : () => onPairSelected(pairIndex - 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('Previous Pair'),
                    style: _smallStitchButtonStyle(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pairCountLabel,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: disabled || pairIndex >= totalPairs - 1
                        ? null
                        : () => onPairSelected(pairIndex + 1),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('Next Pair'),
                    style: _smallStitchButtonStyle(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.join_full_rounded,
                  color: Color(0xFFFFD166),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    manualOverlapFraction == null
                        ? 'Automatic match. If repeated receipt text does not line up, adjust this pair.'
                        : 'Manual match: $percent%. Line up the repeated receipt text.',
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: disabled || manualOverlapFraction == null
                      ? null
                      : onClear,
                  child: const Text('Use Auto'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Slide until the bottom of the first section matches the top of the next section.',
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _ReceiptStitchGuideChip(
                    label: 'Bottom of section ${pairIndex + 1}',
                    icon: Icons.vertical_align_bottom_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ReceiptStitchGuideChip(
                    label: 'Top of section ${pairIndex + 2}',
                    icon: Icons.vertical_align_top_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                _ReceiptStitchGuideChip(
                  label: '$percent%',
                  icon: Icons.compare_arrows_rounded,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Slider(
              value: overlap,
              min: .08,
              max: .48,
              divisions: 20,
              activeColor: const Color(0xFFFFD166),
              inactiveColor: const Color(0xFF526168),
              label: '$percent%',
              onChanged: disabled ? null : onOverlapChanged,
            ),
            _ReceiptStitchReadinessCard(
              stitchPreview: stitchPreview,
              rebuilding: stitchPreviewInFlight,
              onOpenOrder: disabled ? null : onOpenOrder,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _smallStitchButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE8ECEE),
      disabledForegroundColor: const Color(0xFF76848A),
      side: const BorderSide(color: Color(0xFF526168), width: .9),
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
    );
  }
}
