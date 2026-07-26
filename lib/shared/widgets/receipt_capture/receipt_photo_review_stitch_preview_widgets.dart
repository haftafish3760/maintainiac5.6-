part of 'receipt_photo_review_screen.dart';

class _DataSaverPreviewLoadingBanner extends StatelessWidget {
  const _DataSaverPreviewLoadingBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFFD166),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Preparing saved proof preview...',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontWeight: FontWeight.w900,
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
