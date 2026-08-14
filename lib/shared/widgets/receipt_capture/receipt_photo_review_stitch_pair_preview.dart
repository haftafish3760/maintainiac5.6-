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
    required this.onManualGestureChanged,
    required this.onResetManualAlignment,
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
  final ValueChanged<_ReceiptManualAlignmentUpdate> onManualGestureChanged;
  final VoidCallback onResetManualAlignment;

  @override
  Widget build(BuildContext context) {
    final selected = pairIndex.clamp(0, photoPaths.length - 2).toInt();
    final sectionNumberLabel = 'Sections ${selected + 1} and ${selected + 2}';
    if (!matching && photoPaths.length > 1) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _ReceiptManualOverlapPanel(
            previousPath: photoPaths[selected],
            nextPath: photoPaths[selected + 1],
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
            onHorizontalOffsetChanged: onManualHorizontalOffsetChanged,
            onGestureChanged: onManualGestureChanged,
            onReset: onResetManualAlignment,
          ),
          if (photoPaths.length > 2)
            Positioned(
              top: 8,
              left: 64,
              right: 8,
              child: _ReceiptStitchPairNavigator(
                pairIndex: selected,
                pairCount: photoPaths.length - 1,
                onSelected: onPairSelected,
              ),
            ),
        ],
      );
    }
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
            ),
        ],
      ),
    );
  }
}

class _ReceiptManualOverlapPanel extends StatefulWidget {
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
    required this.onGestureChanged,
    required this.onReset,
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
  final ValueChanged<_ReceiptManualAlignmentUpdate> onGestureChanged;
  final VoidCallback onReset;

  @override
  State<_ReceiptManualOverlapPanel> createState() =>
      _ReceiptManualOverlapPanelState();
}

class _ReceiptManualOverlapPanelState
    extends State<_ReceiptManualOverlapPanel> {
  bool _controlsVisible = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ReceiptGhostAlignmentPreview(
          previousPath: widget.previousPath,
          nextPath: widget.nextPath,
          overlapFraction: widget.value,
          noOverlap: widget.noOverlap,
          scale: widget.scale,
          rotationDegrees: widget.rotationDegrees,
          horizontalOffsetFraction: widget.horizontalOffsetFraction,
          onGestureChanged: widget.onGestureChanged,
        ),
        Positioned(
          top: 10,
          left: 62,
          right: 10,
          child: IgnorePointer(
            child: Text(
              'Align ${widget.sectionNumberLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ),
        if (!_controlsVisible)
          Positioned(
            right: 10,
            bottom: 10,
            child: FilledButton.icon(
              onPressed: () => setState(() => _controlsVisible = true),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Show controls'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xE611181B),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (_controlsVisible)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: _ReceiptManualAlignmentControls(
              onReset: widget.onReset,
              onHide: () => setState(() => _controlsVisible = false),
            ),
          ),
      ],
    );
  }
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
