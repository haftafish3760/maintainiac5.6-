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
    final strings = MaintaniacLocalizations.of(context);
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
            label: strings.matchReceiptPhotos,
            onPressed: onMatch,
          ),
          const SizedBox(width: 6),
          _ReceiptActionRailButton(
            icon: Icons.crop_rounded,
            label: strings.cropCurrentReceiptPhoto,
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

class _ReceiptPhotoCountBadge extends StatelessWidget {
  const _ReceiptPhotoCountBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    final label = total <= 1
        ? strings.receiptPhoto
        : strings.receiptSectionOf(current, total);
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
