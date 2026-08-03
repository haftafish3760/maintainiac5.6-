part of 'receipt_photo_review_screen.dart';

class _ReceiptAlignmentGuidePreview extends StatelessWidget {
  const _ReceiptAlignmentGuidePreview({
    required this.photoPath,
    required this.label,
    required this.alignment,
    required this.height,
  });

  final String photoPath;
  final String label;
  final Alignment alignment;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1113),
          border: Border.all(color: const Color(0xFF526168)),
        ),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  1.35,
                  0,
                  0,
                  0,
                  -44,
                  0,
                  1.35,
                  0,
                  0,
                  -44,
                  0,
                  0,
                  1.35,
                  0,
                  -44,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.cover,
                  alignment: alignment,
                  cacheWidth: 1400,
                  cacheHeight: 900,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Previous receipt section could not be previewed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xEE050607),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptAlignmentGuideNote extends StatelessWidget {
  const _ReceiptAlignmentGuideNote({
    required this.hasPreviousReference,
    required this.hasNextReference,
  });

  final bool hasPreviousReference;
  final bool hasNextReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334047)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF8FD3FF),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _instruction,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _instruction {
    if (hasPreviousReference && hasNextReference) {
      return 'The camera will show a narrow reference at the top and bottom. Keep the center clear, then match the printed lines at both references.';
    }
    if (hasNextReference) {
      return 'The camera will show a narrow reference at the bottom. Match the printed lines at the bottom of your new photo before reviewing it.';
    }
    return 'The camera will show a narrow reference at the top. Start your new photo with the same 3-5 readable printed lines.';
  }
}
