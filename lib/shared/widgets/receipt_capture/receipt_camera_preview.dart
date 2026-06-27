part of 'receipt_camera_screen.dart';

class _FullScreenCameraPreview extends StatelessWidget {
  const _FullScreenCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Color(0xFF050607));
    }
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviousSectionGuide extends StatelessWidget {
  const _ReceiptPreviousSectionGuide({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x5A101618),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xAAFFD166), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: .34,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: .28,
                        child: Image.file(
                          File(photoPath),
                          fit: BoxFit.fitWidth,
                          width: double.infinity,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: Color(0xAAFFD166),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        color: const Color(0xCC050607),
                        child: const Text(
                          'Line up this previous bottom slice with the top of the next photo.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFE8ECEE),
                            fontSize: 11,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptLiveEdgeOverlay extends StatelessWidget {
  const _ReceiptLiveEdgeOverlay({required this.frame});

  final _ReceiptDocumentFrame frame;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ReceiptLiveEdgePainter(frame),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ReceiptLiveEdgePainter extends CustomPainter {
  const _ReceiptLiveEdgePainter(this.frame);

  final _ReceiptDocumentFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !frame.isUsable) return;
    final rect = Rect.fromLTRB(
      frame.normalizedRect.left * size.width,
      frame.normalizedRect.top * size.height,
      frame.normalizedRect.right * size.width,
      frame.normalizedRect.bottom * size.height,
    );
    final confidence = frame.confidence.clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFFFFD166),
      const Color(0xFF8EF6A4),
      confidence,
    )!;
    final stroke = Paint()
      ..color = color.withValues(alpha: .86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    final guideRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(guideRect, glow);
    canvas.drawRRect(guideRect, stroke);

    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final corner = math.min(rect.shortestSide * .18, 38.0);
    canvas
      ..drawLine(rect.topLeft, rect.topLeft + Offset(corner, 0), cornerPaint)
      ..drawLine(rect.topLeft, rect.topLeft + Offset(0, corner), cornerPaint)
      ..drawLine(rect.topRight, rect.topRight - Offset(corner, 0), cornerPaint)
      ..drawLine(rect.topRight, rect.topRight + Offset(0, corner), cornerPaint)
      ..drawLine(
        rect.bottomLeft,
        rect.bottomLeft + Offset(corner, 0),
        cornerPaint,
      )
      ..drawLine(
        rect.bottomLeft,
        rect.bottomLeft - Offset(0, corner),
        cornerPaint,
      )
      ..drawLine(
        rect.bottomRight,
        rect.bottomRight - Offset(corner, 0),
        cornerPaint,
      )
      ..drawLine(
        rect.bottomRight,
        rect.bottomRight - Offset(0, corner),
        cornerPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _ReceiptLiveEdgePainter oldDelegate) {
    return oldDelegate.frame.normalizedRect != frame.normalizedRect ||
        oldDelegate.frame.confidence != frame.confidence;
  }
}
