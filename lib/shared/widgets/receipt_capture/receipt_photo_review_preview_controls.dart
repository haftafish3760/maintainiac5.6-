part of 'receipt_photo_review_screen.dart';

class _ReceiptMultiPhotoActionRail extends StatelessWidget {
  const _ReceiptMultiPhotoActionRail({
    required this.selectedIndex,
    required this.total,
    required this.onAddPhoto,
    required this.onOrder,
    required this.onMatch,
    required this.onCrop,
  });

  final int selectedIndex;
  final int total;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onOrder;
  final VoidCallback? onMatch;
  final VoidCallback? onCrop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ReceiptActionRailButton(
            icon: Icons.add_a_photo_rounded,
            label: _ReceiptPhotoSectionLabels.addNextSectionLabel(total: total),
            emphasized: true,
            onPressed: onAddPhoto,
          ),
          const SizedBox(width: 6),
          _ReceiptActionRailButton(
            icon: Icons.swap_vert_rounded,
            label: _ReceiptPhotoSectionLabels.sectionHeader,
            onPressed: onOrder,
          ),
          const SizedBox(width: 6),
          _ReceiptActionRailButton(
            icon: Icons.join_full_rounded,
            label: 'Match Photos',
            onPressed: onMatch,
          ),
          const SizedBox(width: 6),
          _ReceiptActionRailButton(
            icon: Icons.crop_rounded,
            label: 'Crop Current',
            onPressed: onCrop,
          ),
          const SizedBox(width: 6),
          _ReceiptSectionPositionChip(
            selectedIndex: selectedIndex,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _ReceiptSectionPositionChip extends StatelessWidget {
  const _ReceiptSectionPositionChip({
    required this.selectedIndex,
    required this.total,
  });

  final int selectedIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Center(
          child: Text(
            _ReceiptPhotoSectionLabels.orderedStripHint(
              selectedIndex: selectedIndex,
              total: total,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptSinglePhotoActionRow extends StatelessWidget {
  const _ReceiptSinglePhotoActionRow({
    required this.openingCamera,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onModeChanged,
  });

  final bool openingCamera;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final ValueChanged<_ReceiptReviewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.add_a_photo_rounded,
            label: 'Add Another Photo',
            emphasized: true,
            onPressed: openingCamera ? null : onAddPhoto,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.camera_alt_rounded,
            label: 'Retake',
            onPressed: openingCamera ? null : onRetake,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.crop_rounded,
            label: 'Crop',
            onPressed: openingCamera
                ? null
                : () => onModeChanged(_ReceiptReviewMode.crop),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.storage_rounded,
            label: 'Proof',
            onPressed: openingCamera
                ? null
                : () => onModeChanged(_ReceiptReviewMode.dataSaver),
          ),
        ),
      ],
    );
  }
}

class _ReceiptPhotoCountBadge extends StatelessWidget {
  const _ReceiptPhotoCountBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final label = 'Photo $current of $total';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111A1F),
        border: Border.all(color: const Color(0xFF43515A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
