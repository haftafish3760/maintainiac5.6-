part of 'receipt_photo_review_screen.dart';

class _ReceiptCropActions extends StatelessWidget {
  const _ReceiptCropActions({
    required this.cropProcessing,
    required this.onStraightenLeft,
    required this.onStraightenRight,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onResetCrop,
    required this.onApplyCrop,
    required this.onCancelCrop,
  });

  final bool cropProcessing;
  final VoidCallback onStraightenLeft;
  final VoidCallback onStraightenRight;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onResetCrop;
  final VoidCallback onApplyCrop;
  final VoidCallback onCancelCrop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              _CropTextAction(
                icon: Icons.close_rounded,
                label: 'Cancel',
                onPressed: cropProcessing ? null : onCancelCrop,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CompactEditButton(
                      icon: Icons.rotate_left_rounded,
                      label: 'Straighten Left',
                      onPressed: cropProcessing ? null : onStraightenLeft,
                    ),
                    _CompactEditButton(
                      icon: Icons.rotate_right_rounded,
                      label: 'Straighten Right',
                      onPressed: cropProcessing ? null : onStraightenRight,
                    ),
                    _CompactEditButton(
                      icon: Icons.undo_rounded,
                      label: 'Rotate Left',
                      onPressed: cropProcessing ? null : onRotateLeft,
                    ),
                    _CompactEditButton(
                      icon: Icons.redo_rounded,
                      label: 'Rotate Right',
                      onPressed: cropProcessing ? null : onRotateRight,
                    ),
                    _CompactEditButton(
                      icon: Icons.fit_screen_rounded,
                      label: 'Reset Edges',
                      onPressed: cropProcessing ? null : onResetCrop,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: cropProcessing ? null : onApplyCrop,
                icon: cropProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(cropProcessing ? 'Cropping' : 'Apply Crop'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(112, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropTextAction extends StatelessWidget {
  const _CropTextAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8ECEE),
        disabledForegroundColor: const Color(0xFF76848A),
        side: const BorderSide(color: Color(0xFF526168), width: .9),
        minimumSize: const Size(96, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CompactEditButton extends StatelessWidget {
  const _CompactEditButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8ECEE),
          side: const BorderSide(color: Color(0xFF526168)),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
