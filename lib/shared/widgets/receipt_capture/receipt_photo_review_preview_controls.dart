part of 'receipt_photo_review_screen.dart';

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
