part of 'receipt_photo_review_screen.dart';

class _ReceiptBestShotQualityCard extends StatelessWidget {
  const _ReceiptBestShotQualityCard({required this.quality});

  final ReceiptPhotoQualityCheck quality;

  @override
  Widget build(BuildContext context) {
    final score = quality.reviewScore;
    final color = _scoreColor(score);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10181C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(_scoreIcon(score), color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Photo quality ${quality.reviewScoreLabel}',
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quality.focusLabel} • ${quality.resolutionLabel} • ${_scoreMessage(score)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF58D67D);
    if (score >= 55) return const Color(0xFFFFD166);
    return const Color(0xFFFF6B6B);
  }

  static IconData _scoreIcon(int score) {
    if (score >= 80) return Icons.check_circle_rounded;
    if (score >= 55) return Icons.info_rounded;
    return Icons.warning_rounded;
  }

  static String _scoreMessage(int score) {
    if (score >= 80) return 'good for review';
    if (score >= 55) return 'usable, check before saving';
    return 'retake if the receipt looks blurry';
  }
}
