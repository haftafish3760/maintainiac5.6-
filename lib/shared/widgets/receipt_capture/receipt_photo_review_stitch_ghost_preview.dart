part of 'receipt_photo_review_screen.dart';

class _ReceiptGhostAlignmentPreview extends StatelessWidget {
  const _ReceiptGhostAlignmentPreview({
    required this.previousPath,
    required this.nextPath,
    required this.overlapFraction,
    required this.noOverlap,
    required this.scale,
    required this.rotationDegrees,
    required this.horizontalOffsetFraction,
  });

  final String previousPath;
  final String nextPath;
  final double overlapFraction;
  final bool noOverlap;
  final double scale;
  final double rotationDegrees;
  final double horizontalOffsetFraction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: noOverlap
          ? 'Receipt sections shown without shared lines'
          : 'Ghost alignment preview for the bottom of the previous photo and top of the next photo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF050607),
                  border: Border.all(color: const Color(0xFF6D7B81)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final overlap = overlapFraction.clamp(.08, .48);
                    final nextTop = noOverlap
                        ? constraints.maxHeight * .52
                        : constraints.maxHeight * (.52 - overlap);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(previousPath),
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.medium,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: nextTop,
                          bottom: 0,
                          child: ClipRect(
                            child: Opacity(
                              opacity: noOverlap ? 1 : .62,
                              child: Transform.translate(
                                offset: Offset(
                                  constraints.maxWidth *
                                      horizontalOffsetFraction,
                                  0,
                                ),
                                child: Transform.rotate(
                                  angle: rotationDegrees * math.pi / 180,
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.topCenter,
                                    child: Image.file(
                                      File(nextPath),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: nextTop.clamp(1, constraints.maxHeight - 2),
                          child: const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFFFD166),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ReceiptGhostLegend(
                color: Color(0xFFE8ECEE),
                label: 'Previous bottom',
              ),
              SizedBox(width: 14),
              _ReceiptGhostLegend(
                color: Color(0xFFFFD166),
                label: 'Next top (ghost)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptGhostLegend extends StatelessWidget {
  const _ReceiptGhostLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
