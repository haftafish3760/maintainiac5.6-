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

class _StitchPreviewStatusBanner extends StatelessWidget {
  const _StitchPreviewStatusBanner({
    required this.stitch,
    required this.rebuilding,
  });

  final ReceiptStitchResult stitch;
  final bool rebuilding;

  @override
  Widget build(BuildContext context) {
    final title = rebuilding
        ? 'Checking Receipt Image'
        : 'Combined Receipt Preview';
    final detail = rebuilding
        ? 'Maintainiac is checking whether the receipt photos still line up.'
        : stitch.nextStepLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF28A745)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            rebuilding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF28A745),
                    ),
                  )
                : const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFF28A745),
                    size: 19,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
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
}

class _StitchFallbackBanner extends StatelessWidget {
  const _StitchFallbackBanner({required this.stitch});

  final ReceiptStitchResult stitch;

  @override
  Widget build(BuildContext context) {
    final pair = stitch.failedPairLabel;
    final detail = stitch.warning.trim().isEmpty
        ? 'The repeated lines were not clear enough to combine safely.'
        : stitch.warning;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.call_split_rounded,
              color: Color(0xFFFFD166),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Review Photos Top To Bottom',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  if (pair.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$pair needs match review.',
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$detail If these sections show repeated lines, adjust the '
                    'match below. For bottom-section photos, keep 3-5 readable '
                    'lines in the top ghost slice. If not, use these photos and '
                    'Maintainiac opens receipt details from each section, top '
                    'to bottom.',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
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
}
