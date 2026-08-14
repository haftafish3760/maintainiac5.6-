part of 'receipt_photo_review_screen.dart';

class _ReceiptCropActions extends StatelessWidget {
  const _ReceiptCropActions({
    required this.cropProcessing,
    required this.straightenControlsVisible,
    required this.straightenAngleDegrees,
    required this.onToggleStraighten,
    required this.onStraightenAngleChanged,
    required this.onApplyStraighten,
    required this.onResetCrop,
    required this.onApplyCrop,
    required this.onCancelCrop,
  });

  final bool cropProcessing;
  final bool straightenControlsVisible;
  final double straightenAngleDegrees;
  final VoidCallback onToggleStraighten;
  final ValueChanged<double> onStraightenAngleChanged;
  final VoidCallback onApplyStraighten;
  final VoidCallback onResetCrop;
  final VoidCallback onApplyCrop;
  final VoidCallback onCancelCrop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: straightenControlsVisible
          ? _ReceiptStraightenSlider(
              processing: cropProcessing,
              angleDegrees: straightenAngleDegrees,
              onChanged: onStraightenAngleChanged,
              onCancel: onToggleStraighten,
              onApply: onApplyStraighten,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                return Row(
                  children: [
                    _CropTextAction(
                      icon: Icons.close_rounded,
                      label: compact ? '' : 'Cancel',
                      tooltip: 'Cancel crop',
                      onPressed: cropProcessing ? null : onCancelCrop,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('receipt-review-straighten-button'),
                        onPressed: cropProcessing ? null : onToggleStraighten,
                        icon: const Icon(Icons.straighten_rounded, size: 18),
                        label: const Text('Straighten image'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: const Color(0xFFE8ECEE),
                          side: const BorderSide(color: Color(0xFF526168)),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Tooltip(
                      message: 'Reset crop edges',
                      child: IconButton.outlined(
                        onPressed: cropProcessing ? null : onResetCrop,
                        icon: const Icon(Icons.fit_screen_rounded),
                      ),
                    ),
                    const SizedBox(width: 7),
                    FilledButton.icon(
                      onPressed: cropProcessing ? null : onApplyCrop,
                      icon: cropProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(cropProcessing ? 'Working' : 'Apply'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        minimumSize: Size(compact ? 84 : 104, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ReceiptStraightenSlider extends StatelessWidget {
  const _ReceiptStraightenSlider({
    required this.processing,
    required this.angleDegrees,
    required this.onChanged,
    required this.onCancel,
    required this.onApply,
  });

  final bool processing;
  final double angleDegrees;
  final ValueChanged<double> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Cancel straightening',
          onPressed: processing ? null : onCancel,
          icon: const Icon(Icons.close_rounded),
        ),
        Expanded(
          child: Semantics(
            label: 'Straighten receipt image',
            value: '${angleDegrees.toStringAsFixed(1)} degrees',
            hint:
                'Slide until receipt lines are level. The crop frame stays fixed.',
            child: Slider(
              key: const ValueKey('receipt-review-straighten-slider'),
              value: angleDegrees,
              min: -5,
              max: 5,
              divisions: 100,
              label: '${angleDegrees.toStringAsFixed(1)}°',
              onChanged: processing ? null : onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${angleDegrees.toStringAsFixed(1)}°',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 5),
        FilledButton(
          onPressed: processing ? null : onApply,
          style: FilledButton.styleFrom(
            minimumSize: const Size(84, 44),
            backgroundColor: const Color(0xFF28A745),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: processing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Apply'),
        ),
      ],
    );
  }
}

class _CropTextAction extends StatelessWidget {
  const _CropTextAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: label.isEmpty
          ? IconButton.outlined(onPressed: onPressed, icon: Icon(icon))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE8ECEE),
                disabledForegroundColor: const Color(0xFF76848A),
                side: const BorderSide(color: Color(0xFF526168), width: .9),
                minimumSize: const Size(96, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
    );
  }
}
