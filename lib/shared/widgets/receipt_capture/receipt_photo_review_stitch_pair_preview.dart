part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchPairPreview extends StatelessWidget {
  const _ReceiptStitchPairPreview({
    required this.firstPath,
    required this.secondPath,
    required this.pairIndex,
    required this.totalPairs,
    required this.overlapFraction,
    required this.bottomInset,
  });

  final String firstPath;
  final String secondPath;
  final int pairIndex;
  final int totalPairs;
  final double overlapFraction;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final overlapPercent = (overlapFraction * 100).round();
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF050607)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 6, 6, bottomInset),
          child: Column(
            children: [
              Expanded(
                child: _StitchPreviewPhoto(
                  path: firstPath,
                  label: 'Photo ${pairIndex + 1}',
                  alignment: Alignment.bottomCenter,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xCCFFD166),
                  border: Border.all(color: const Color(0xFFFFE7A8)),
                ),
                child: Text(
                  'Align repeated lines • $overlapPercent% • Photos ${pairIndex + 1}-${pairIndex + 2}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF11181B),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Expanded(
                child: _StitchPreviewPhoto(
                  path: secondPath,
                  label: 'Photo ${pairIndex + 2}',
                  alignment: Alignment.topCenter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StitchPreviewPhoto extends StatelessWidget {
  const _StitchPreviewPhoto({
    required this.path,
    required this.label,
    required this.alignment,
  });

  final String path;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          panEnabled: true,
          scaleEnabled: true,
          clipBehavior: Clip.hardEdge,
          child: SizedBox.expand(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              alignment: alignment,
            ),
          ),
        ),
        Align(
          alignment: alignment == Alignment.topCenter
              ? Alignment.topLeft
              : Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCC050607),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
