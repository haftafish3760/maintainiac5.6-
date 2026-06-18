part of 'receipt_camera_screen.dart';

class _ReceiptCameraFrameOverlay extends StatelessWidget {
  const _ReceiptCameraFrameOverlay({required this.mode, required this.quality});

  final _ReceiptCameraMode mode;
  final _ReceiptLiveFrameQuality? quality;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReceiptCameraFramePainter(mode: mode, quality: quality),
    );
  }
}

class _ReceiptCameraFramePainter extends CustomPainter {
  const _ReceiptCameraFramePainter({required this.mode, required this.quality});

  final _ReceiptCameraMode mode;
  final _ReceiptLiveFrameQuality? quality;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height * .13).clamp(88.0, 132.0);
    final bottom = (size.height * .79).clamp(size.height - 250, size.height);
    final frame = Rect.fromLTRB(
      size.width * .09,
      top,
      size.width * .91,
      bottom,
    );
    final frameColor = _frameColor();
    final fullPath = Path()..addRect(Offset.zero & size);
    final framePath = Path()..addRRect(RRect.fromRectXY(frame, 18, 18));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, framePath),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(
      RRect.fromRectXY(frame, 18, 18),
      Paint()
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = mode == _ReceiptCameraMode.assisted ? 3 : 2,
    );
    _drawLineBands(canvas, frame, frameColor);

    final handlePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const handle = 38.0;
    canvas.drawLine(
      frame.topLeft,
      frame.topLeft + const Offset(handle, 0),
      handlePaint,
    );
    canvas.drawLine(
      frame.topLeft,
      frame.topLeft + const Offset(0, handle),
      handlePaint,
    );
    canvas.drawLine(
      frame.topRight,
      frame.topRight + const Offset(-handle, 0),
      handlePaint,
    );
    canvas.drawLine(
      frame.topRight,
      frame.topRight + const Offset(0, handle),
      handlePaint,
    );
    canvas.drawLine(
      frame.bottomLeft,
      frame.bottomLeft + const Offset(handle, 0),
      handlePaint,
    );
    canvas.drawLine(
      frame.bottomLeft,
      frame.bottomLeft + const Offset(0, -handle),
      handlePaint,
    );
    canvas.drawLine(
      frame.bottomRight,
      frame.bottomRight + const Offset(-handle, 0),
      handlePaint,
    );
    canvas.drawLine(
      frame.bottomRight,
      frame.bottomRight + const Offset(0, -handle),
      handlePaint,
    );
    final labelPainter = TextPainter(
      text: TextSpan(
        text: mode == _ReceiptCameraMode.assisted
            ? 'Live receipt guide'
            : 'Receipt guide',
        style: TextStyle(
          color: frameColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(frame.left, frame.bottom + 10).translate(0, 0),
    );
  }

  void _drawLineBands(Canvas canvas, Rect frame, Color frameColor) {
    final live = quality;
    if (mode != _ReceiptCameraMode.assisted ||
        live == null ||
        live.lineBands.isEmpty) {
      return;
    }
    final bandPaint = Paint()
      ..color = frameColor.withValues(alpha: .58)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final left = frame.left + frame.width * .14;
    final right = frame.right - frame.width * .14;
    for (final band in live.lineBands.take(14)) {
      final y = frame.top + frame.height * band.clamp(0.0, 1.0);
      canvas.drawLine(Offset(left, y), Offset(right, y), bandPaint);
    }
  }

  Color _frameColor() {
    final live = quality;
    if (mode == _ReceiptCameraMode.standard || live == null) {
      return const Color(0xFFFFD166);
    }
    return switch (live.readiness) {
      _ReceiptCameraReadiness.notReady => const Color(0xFFFF4D5E),
      _ReceiptCameraReadiness.almostReady => const Color(0xFFFFD166),
      _ReceiptCameraReadiness.ready => const Color(0xFF8EF6A4),
    };
  }

  @override
  bool shouldRepaint(covariant _ReceiptCameraFramePainter oldDelegate) {
    return oldDelegate.mode != mode || oldDelegate.quality != quality;
  }
}
