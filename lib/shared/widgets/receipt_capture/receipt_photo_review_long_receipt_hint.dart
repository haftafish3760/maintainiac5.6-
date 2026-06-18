part of 'receipt_photo_review_screen.dart';

class _ReceiptLongReceiptReviewHint extends StatelessWidget {
  const _ReceiptLongReceiptReviewHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10181C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF56666E)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFFFD166),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Long receipt? Add more photos before saving this receipt.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
