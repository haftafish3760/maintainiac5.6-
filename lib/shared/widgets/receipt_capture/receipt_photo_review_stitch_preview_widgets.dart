part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchAssemblySurface extends StatelessWidget {
  const _ReceiptStitchAssemblySurface();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF050607),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF5CE17A),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Putting your receipt together…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep this screen open. Your finished receipt will appear when it is ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptStitchFailureSurface extends StatelessWidget {
  const _ReceiptStitchFailureSurface({
    required this.onRetake,
    required this.onAlign,
  });

  final VoidCallback onRetake;
  final VoidCallback onAlign;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050607),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFFFD166),
                  size: 42,
                ),
                const SizedBox(height: 16),
                const Text(
                  'These photos did not line up clearly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your original photos are unchanged. Retake the affected photo or align the sections yourself.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Retake Photos'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: const Color(0xFFE8ECEE),
                    side: const BorderSide(color: Color(0xFF526168)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onAlign,
                  icon: const Icon(Icons.join_full_rounded),
                  label: const Text('Align Photos Myself'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
