import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

part 'receipt_edge_cropper_handles.dart';

enum _ReceiptCropHandle {
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class ReceiptEdgeCropper extends StatelessWidget {
  const ReceiptEdgeCropper({
    super.key,
    required this.imageBytes,
    required this.imageSize,
    required this.cropRect,
    required this.onCropRectChanged,
    required this.onDisplayRectChanged,
  });

  final Uint8List imageBytes;
  final Size imageSize;
  final Rect? cropRect;
  final ValueChanged<Rect> onCropRectChanged;
  final ValueChanged<Rect> onDisplayRectChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _containedImageRect(canvasSize, imageSize);
        _notifyAfterLayout(context, () => onDisplayRectChanged(imageRect));
        final activeCropRect = cropRect ?? imageRect;
        if (cropRect == null) {
          _notifyAfterLayout(context, () => onCropRectChanged(imageRect));
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: imageRect,
              child: Image.memory(imageBytes, fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ReceiptCropOverlayPainter(
                  imageRect: imageRect,
                  cropRect: activeCropRect,
                ),
              ),
            ),
            for (final handle in _ReceiptCropHandle.values)
              _CropHandle(
                imageRect: imageRect,
                cropRect: activeCropRect,
                handle: handle,
                onDrag: _dragCropHandle,
              ),
          ],
        );
      },
    );
  }

  Rect _containedImageRect(Size canvasSize, Size sourceImageSize) {
    if (canvasSize.isEmpty || sourceImageSize.isEmpty) {
      return Offset.zero & canvasSize;
    }
    final scale = math.min(
      canvasSize.width / sourceImageSize.width,
      canvasSize.height / sourceImageSize.height,
    );
    final fittedSize = Size(
      sourceImageSize.width * scale,
      sourceImageSize.height * scale,
    );
    return Rect.fromLTWH(
      (canvasSize.width - fittedSize.width) / 2,
      (canvasSize.height - fittedSize.height) / 2,
      fittedSize.width,
      fittedSize.height,
    );
  }

  void _notifyAfterLayout(BuildContext context, VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      callback();
    });
  }

  void _dragCropHandle(
    _ReceiptCropHandle handle,
    DragUpdateDetails details,
    Rect imageRect,
    Rect current,
  ) {
    const minSize = 72.0;
    var left = current.left;
    var right = current.right;
    var top = current.top;
    var bottom = current.bottom;
    switch (handle) {
      case _ReceiptCropHandle.left:
        left = (left + details.delta.dx).clamp(imageRect.left, right - minSize);
      case _ReceiptCropHandle.right:
        right = (right + details.delta.dx).clamp(
          left + minSize,
          imageRect.right,
        );
      case _ReceiptCropHandle.top:
        top = (top + details.delta.dy).clamp(imageRect.top, bottom - minSize);
      case _ReceiptCropHandle.bottom:
        bottom = (bottom + details.delta.dy).clamp(
          top + minSize,
          imageRect.bottom,
        );
      case _ReceiptCropHandle.topLeft:
        left = (left + details.delta.dx).clamp(imageRect.left, right - minSize);
        top = (top + details.delta.dy).clamp(imageRect.top, bottom - minSize);
      case _ReceiptCropHandle.topRight:
        right = (right + details.delta.dx).clamp(
          left + minSize,
          imageRect.right,
        );
        top = (top + details.delta.dy).clamp(imageRect.top, bottom - minSize);
      case _ReceiptCropHandle.bottomLeft:
        left = (left + details.delta.dx).clamp(imageRect.left, right - minSize);
        bottom = (bottom + details.delta.dy).clamp(
          top + minSize,
          imageRect.bottom,
        );
      case _ReceiptCropHandle.bottomRight:
        right = (right + details.delta.dx).clamp(
          left + minSize,
          imageRect.right,
        );
        bottom = (bottom + details.delta.dy).clamp(
          top + minSize,
          imageRect.bottom,
        );
    }
    onCropRectChanged(Rect.fromLTRB(left, top, right, bottom));
  }
}

class _ReceiptCropOverlayPainter extends CustomPainter {
  const _ReceiptCropOverlayPainter({
    required this.imageRect,
    required this.cropRect,
  });

  final Rect imageRect;
  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    final imagePath = Path()..addRect(imageRect);
    final cropPath = Path()..addRect(cropRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, imagePath),
      Paint()..color = const Color(0xFF050607),
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cropPath),
      Paint()..color = const Color(0x99000000),
    );

    canvas.drawRect(
      cropRect,
      Paint()
        ..color = const Color(0xFFFFD166)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final gridPaint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..strokeWidth = 1.2;
    for (var index = 1; index < 3; index += 1) {
      final dx = cropRect.left + cropRect.width * index / 3;
      final dy = cropRect.top + cropRect.height * index / 3;
      canvas.drawLine(
        Offset(dx, cropRect.top),
        Offset(dx, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, dy),
        Offset(cropRect.right, dy),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptCropOverlayPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect;
  }
}
