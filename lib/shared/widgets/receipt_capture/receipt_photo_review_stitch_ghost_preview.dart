part of 'receipt_photo_review_screen.dart';

class _ReceiptManualAlignmentUpdate {
  const _ReceiptManualAlignmentUpdate({
    required this.overlapFraction,
    required this.scale,
    required this.rotationDegrees,
    required this.horizontalOffsetFraction,
  });

  final double overlapFraction;
  final double scale;
  final double rotationDegrees;
  final double horizontalOffsetFraction;
}

class _ReceiptGhostAlignmentPreview extends StatefulWidget {
  const _ReceiptGhostAlignmentPreview({
    required this.previousPath,
    required this.nextPath,
    required this.overlapFraction,
    required this.noOverlap,
    required this.scale,
    required this.rotationDegrees,
    required this.horizontalOffsetFraction,
    required this.onGestureChanged,
  });

  final String previousPath;
  final String nextPath;
  final double overlapFraction;
  final bool noOverlap;
  final double scale;
  final double rotationDegrees;
  final double horizontalOffsetFraction;
  final ValueChanged<_ReceiptManualAlignmentUpdate> onGestureChanged;

  @override
  State<_ReceiptGhostAlignmentPreview> createState() =>
      _ReceiptGhostAlignmentPreviewState();
}

class _ReceiptGhostAlignmentPreviewState
    extends State<_ReceiptGhostAlignmentPreview> {
  Offset _gestureStart = Offset.zero;
  double _startOverlap = .20;
  double _startScale = 1;
  double _startRotationDegrees = 0;
  double _startHorizontalOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.noOverlap
          ? 'Receipt sections shown without shared lines'
          : 'Ghost alignment preview for the bottom of the previous photo and top of the next photo',
      hint:
          'Drag the lower photo to move it. Pinch to resize it. Twist to straighten it.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final overlap = widget.overlapFraction.clamp(.08, .48);
          final nextTop = widget.noOverlap
              ? constraints.maxHeight * .52
              : constraints.maxHeight * (.52 - overlap);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              _gestureStart = details.localFocalPoint;
              _startOverlap = widget.overlapFraction;
              _startScale = widget.scale;
              _startRotationDegrees = widget.rotationDegrees;
              _startHorizontalOffset = widget.horizontalOffsetFraction;
            },
            onScaleUpdate: (details) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                return;
              }
              final delta = details.localFocalPoint - _gestureStart;
              widget.onGestureChanged(
                _ReceiptManualAlignmentUpdate(
                  overlapFraction: widget.noOverlap
                      ? widget.overlapFraction
                      : (_startOverlap - delta.dy / constraints.maxHeight)
                            .clamp(.08, .48),
                  scale: (_startScale * details.scale).clamp(.75, 1.25),
                  rotationDegrees:
                      (_startRotationDegrees + details.rotation * 180 / math.pi)
                          .clamp(-8, 8),
                  horizontalOffsetFraction:
                      (_startHorizontalOffset + delta.dx / constraints.maxWidth)
                          .clamp(-.20, .20),
                ),
              );
            },
            child: ColoredBox(
              color: const Color(0xFF050607),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.previousPath),
                    // Preserve the receipt's true proportions. Cover crops a
                    // narrow receipt into a wide phone viewport and makes a
                    // valid join look skewed or stretched.
                    fit: BoxFit.fitWidth,
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
                        // A ghost must still be readable. The selected lower
                        // section is deliberately strong enough to match text
                        // lines against the fixed upper section.
                        opacity: widget.noOverlap ? 1 : .82,
                        child: Transform.translate(
                          offset: Offset(
                            constraints.maxWidth *
                                widget.horizontalOffsetFraction,
                            0,
                          ),
                          child: Transform.rotate(
                            angle: widget.rotationDegrees * math.pi / 180,
                            child: Transform.scale(
                              scale: widget.scale,
                              alignment: Alignment.topCenter,
                              child: Image.file(
                                File(widget.nextPath),
                                fit: BoxFit.fitWidth,
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
                      thickness: 2,
                      color: Color(0xFFFFD166),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    bottom: 10,
                    child: _ReceiptGhostLegend(
                      color: Color(0xFFFFD166),
                      label: 'Drag lower section to align',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
