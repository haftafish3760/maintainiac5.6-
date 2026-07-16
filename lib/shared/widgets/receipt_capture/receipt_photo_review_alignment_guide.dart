part of 'receipt_photo_review_screen.dart';

class _ReceiptAlignmentGuidePreview extends StatelessWidget {
  const _ReceiptAlignmentGuidePreview({required this.photoPath});

  final String photoPath;

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
          height: 126,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photoPath),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
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
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66050607),
                        Color(0x11050607),
                        Color(0xAA050607),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xDD11181B),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFFFD166)),
                  ),
                  child: const Text(
                    'Repeat 3-5 readable lines from this bottom area in the next photo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: 0,
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
  const _ReceiptAlignmentGuideNote({required this.missingBottomAndTotals});

  final bool missingBottomAndTotals;

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
              missingBottomAndTotals
                  ? 'This is your reference photo. After you tap the green button, your phone camera opens. Begin the next photo with 3-5 of the same readable lines so Maintainiac can line up the sections.'
                  : 'This is your reference photo. After you tap the green button, your phone camera opens. Begin the next photo with 3-5 of the same readable lines.',
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
}
