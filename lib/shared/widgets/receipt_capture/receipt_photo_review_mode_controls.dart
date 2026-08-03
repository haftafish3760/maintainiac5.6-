part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewStepStrip extends StatelessWidget {
  const _ReceiptReviewStepStrip({
    required this.selected,
    required this.photoCount,
    required this.enabled,
    required this.onSelected,
  });

  final _ReceiptReviewMode selected;
  final int photoCount;
  final bool enabled;
  final ValueChanged<_ReceiptReviewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    // Never leave a partially visible action at the edge of the phone. The
    // full labels matter more than forcing every review tool onto one row.
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StepStripButton(
          label: 'Review',
          icon: Icons.visibility_rounded,
          selected: selected == _ReceiptReviewMode.preview,
          onTap: enabled ? () => onSelected(_ReceiptReviewMode.preview) : null,
        ),
        const SizedBox(width: 6),
        _StepStripButton(
          label: 'Crop',
          icon: Icons.crop_rounded,
          selected: selected == _ReceiptReviewMode.crop,
          onTap: enabled ? () => onSelected(_ReceiptReviewMode.crop) : null,
        ),
        const SizedBox(width: 6),
        _StepStripButton(
          label: 'Photo Order',
          icon: Icons.swap_vert_rounded,
          selected: selected == _ReceiptReviewMode.order,
          onTap: enabled && photoCount > 1
              ? () => onSelected(_ReceiptReviewMode.order)
              : null,
        ),
        const SizedBox(width: 6),
        _StepStripButton(
          label: 'Align Photos',
          icon: Icons.join_full_rounded,
          selected: selected == _ReceiptReviewMode.stitch,
          onTap: enabled && photoCount > 1
              ? () => onSelected(_ReceiptReviewMode.stitch)
              : null,
        ),
        const SizedBox(width: 6),
        _StepStripButton(
          label: 'Save Space',
          icon: Icons.storage_rounded,
          selected: selected == _ReceiptReviewMode.dataSaver,
          onTap: enabled
              ? () => onSelected(_ReceiptReviewMode.dataSaver)
              : null,
        ),
      ],
    );
  }
}

class _StepStripButton extends StatelessWidget {
  const _StepStripButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFFFFD166)
            : const Color(0xFF172126),
        foregroundColor: selected ? const Color(0xFF101416) : Colors.white,
        minimumSize: const Size(92, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ReceiptToolModeHeader extends StatelessWidget {
  const _ReceiptToolModeHeader({
    required this.reviewMode,
    required this.photoCount,
    required this.previewEnabled,
    required this.onBackToPreview,
  });

  final _ReceiptReviewMode reviewMode;
  final int photoCount;
  final bool previewEnabled;
  final VoidCallback onBackToPreview;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = switch (reviewMode) {
      _ReceiptReviewMode.crop => (
        Icons.crop_rounded,
        'Crop Receipt',
        'Adjust the image edges, rotate, or straighten before review.',
      ),
      _ReceiptReviewMode.order => (
        Icons.swap_vert_rounded,
        'Check Photo Order',
        'Photo 1 is the top; each next photo continues lower.',
      ),
      _ReceiptReviewMode.stitch => (
        Icons.join_full_rounded,
        'Align Receipt Photos',
        photoCount > 1
            ? 'Maintainiac combines the photos automatically. Adjust only if the receipt did not line up.'
            : 'Add another photo before aligning a long receipt.',
      ),
      _ReceiptReviewMode.dataSaver => (
        Icons.storage_rounded,
        'Choose Saved Image Size',
        'Preview exactly how the saved image will look. Receipt assistance still uses the clearest source first.',
      ),
      _ReceiptReviewMode.preview => (
        Icons.visibility_rounded,
        'Review Photo',
        'Check the photo before opening the receipt details.',
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD166), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: previewEnabled ? onBackToPreview : null,
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('Preview'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD166),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
