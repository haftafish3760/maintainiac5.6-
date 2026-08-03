part of 'receipt_photo_review_screen.dart';

/// Shows one original section at readable size while the app combines the
/// ordered receipt in the background. The compact section strip below the
/// surface keeps every original available without crushing two full photos
/// into the same viewport.
class _ReceiptStitchWorkingSurface extends StatelessWidget {
  const _ReceiptStitchWorkingSurface({
    required this.photoPaths,
    required this.pairIndex,
    required this.matching,
    required this.manualOverlapFraction,
    required this.manualZeroOverlap,
    required this.manualScaleCorrection,
    required this.manualRotationCorrectionDegrees,
    required this.manualHorizontalOffsetFraction,
    required this.onPhotoSelected,
    required this.onPairSelected,
    required this.onManualOverlapChanged,
    required this.onManualZeroOverlapChanged,
    required this.onManualScaleChanged,
    required this.onManualRotationChanged,
    required this.onManualHorizontalOffsetChanged,
  });

  final List<String> photoPaths;
  final int pairIndex;
  final bool matching;
  final double? manualOverlapFraction;
  final bool manualZeroOverlap;
  final double manualScaleCorrection;
  final double manualRotationCorrectionDegrees;
  final double manualHorizontalOffsetFraction;
  final ValueChanged<int> onPhotoSelected;
  final ValueChanged<int> onPairSelected;
  final ValueChanged<double> onManualOverlapChanged;
  final ValueChanged<bool> onManualZeroOverlapChanged;
  final ValueChanged<double> onManualScaleChanged;
  final ValueChanged<double> onManualRotationChanged;
  final ValueChanged<double> onManualHorizontalOffsetChanged;

  @override
  Widget build(BuildContext context) {
    final selected = pairIndex.clamp(0, photoPaths.length - 2).toInt();
    final sectionNumberLabel = 'Sections ${selected + 1} and ${selected + 2}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReceiptStitchWorkingHeader(
            matching: matching,
            total: photoPaths.length,
          ),
          const SizedBox(height: 6),
          if (matching)
            Expanded(
              child: _StitchPreviewPhoto(
                path: photoPaths[selected],
                label: 'Receipt section ${selected + 1}',
                alignment: Alignment.topCenter,
                selected: true,
                onSelected: () => onPhotoSelected(selected),
              ),
            )
          else if (photoPaths.length > 1)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoPaths.length > 2) ...[
                      _ReceiptStitchPairNavigator(
                        pairIndex: selected,
                        pairCount: photoPaths.length - 1,
                        onSelected: onPairSelected,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _ReceiptManualOverlapPanel(
                      previousPath:
                          photoPaths[selected
                              .clamp(0, photoPaths.length - 2)
                              .toInt()],
                      nextPath:
                          photoPaths[(selected + 1)
                              .clamp(1, photoPaths.length - 1)
                              .toInt()],
                      sectionNumberLabel: sectionNumberLabel,
                      value: manualOverlapFraction ?? .20,
                      noOverlap: manualZeroOverlap,
                      onChanged: onManualOverlapChanged,
                      onNoOverlapChanged: onManualZeroOverlapChanged,
                      scale: manualScaleCorrection,
                      rotationDegrees: manualRotationCorrectionDegrees,
                      horizontalOffsetFraction: manualHorizontalOffsetFraction,
                      onScaleChanged: onManualScaleChanged,
                      onRotationChanged: onManualRotationChanged,
                      onHorizontalOffsetChanged:
                          onManualHorizontalOffsetChanged,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReceiptManualOverlapPanel extends StatelessWidget {
  const _ReceiptManualOverlapPanel({
    required this.previousPath,
    required this.nextPath,
    required this.sectionNumberLabel,
    required this.value,
    required this.noOverlap,
    required this.onChanged,
    required this.onNoOverlapChanged,
    required this.scale,
    required this.rotationDegrees,
    required this.horizontalOffsetFraction,
    required this.onScaleChanged,
    required this.onRotationChanged,
    required this.onHorizontalOffsetChanged,
  });

  final String previousPath;
  final String nextPath;
  final String sectionNumberLabel;
  final double value;
  final bool noOverlap;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onNoOverlapChanged;
  final double scale;
  final double rotationDegrees;
  final double horizontalOffsetFraction;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onHorizontalOffsetChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF211181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Align $sectionNumberLabel',
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Keep these photos separate for now, or compare the bottom of the first photo with the top of the next photo and adjust the overlap. Maintainiac will try the combined image again. You can also retake only the section that is unclear.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            _ReceiptGhostAlignmentPreview(
              previousPath: previousPath,
              nextPath: nextPath,
              overlapFraction: value,
              noOverlap: noOverlap,
              scale: scale,
              rotationDegrees: rotationDegrees,
              horizontalOffsetFraction: horizontalOffsetFraction,
            ),
            OutlinedButton.icon(
              onPressed: () => onNoOverlapChanged(!noOverlap),
              icon: Icon(
                noOverlap
                    ? Icons.check_circle_rounded
                    : Icons.vertical_align_center_rounded,
              ),
              label: Text(
                noOverlap
                    ? 'No shared lines selected'
                    : 'These sections do not overlap',
              ),
            ),
            if (!noOverlap)
              Slider(
                value: value.clamp(.08, .48),
                min: .08,
                max: .48,
                divisions: 20,
                label: '${(value * 100).round()}% overlap',
                activeColor: const Color(0xFFFFD166),
                onChanged: onChanged,
              ),
            Text(
              noOverlap
                  ? 'No shared lines  •  Size ${(scale * 100).round()}%  •  Straighten ${rotationDegrees.toStringAsFixed(1)}°'
                  : 'Overlap ${(value * 100).round()}%  •  Size ${(scale * 100).round()}%  •  Straighten ${rotationDegrees.toStringAsFixed(1)}°',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: _ReceiptAlignmentButton(
                    label: 'Move left',
                    onPressed: () => onHorizontalOffsetChanged(
                      horizontalOffsetFraction - .02,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ReceiptAlignmentButton(
                    label: 'Move right',
                    onPressed: () => onHorizontalOffsetChanged(
                      horizontalOffsetFraction + .02,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ReceiptAlignmentButton(
                    label: 'Smaller',
                    onPressed: () => onScaleChanged(scale - .02),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ReceiptAlignmentButton(
                    label: 'Larger',
                    onPressed: () => onScaleChanged(scale + .02),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _ReceiptAlignmentButton(
                    label: 'Straighten left',
                    onPressed: () => onRotationChanged(rotationDegrees - .5),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ReceiptAlignmentButton(
                    label: 'Straighten right',
                    onPressed: () => onRotationChanged(rotationDegrees + .5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptAlignmentButton extends StatelessWidget {
  const _ReceiptAlignmentButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE8ECEE),
      side: const BorderSide(color: Color(0xFF6D7B81)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      minimumSize: const Size(0, 38),
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

class _ReceiptStitchWorkingHeader extends StatelessWidget {
  const _ReceiptStitchWorkingHeader({
    required this.matching,
    required this.total,
  });

  final bool matching;
  final int total;

  @override
  Widget build(BuildContext context) {
    final resolvedMessage = matching
        ? 'Combining $total receipt sections automatically'
        : 'Could not safely combine every section';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF211181B),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Row(
          children: [
            Icon(
              matching
                  ? Icons.auto_awesome_rounded
                  : Icons.warning_amber_rounded,
              color: matching
                  ? const Color(0xFF5CE17A)
                  : const Color(0xFFFFD166),
              size: 17,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedMessage,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    matching
                        ? 'Maintainiac is preparing one complete receipt.'
                        : 'Adjust the overlap below, or return and retake a section.',
                    style: const TextStyle(
                      color: Color(0xFF9FB0B8),
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (matching)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF5CE17A),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
