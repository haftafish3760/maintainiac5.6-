part of 'receipt_photo_review_screen.dart';

class _ReceiptMultiPhotoActionRail extends StatelessWidget {
  const _ReceiptMultiPhotoActionRail({
    required this.onOrder,
    required this.onMatch,
  });

  final VoidCallback? onOrder;
  final VoidCallback? onMatch;

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ReceiptActionRailButton(
            icon: Icons.swap_vert_rounded,
            label: 'Reorder Photos',
            onPressed: onOrder,
          ),
          const SizedBox(width: 6),
          _ReceiptActionRailButton(
            icon: Icons.join_full_rounded,
            label: strings.matchReceiptPhotos,
            onPressed: onMatch,
          ),
        ],
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
