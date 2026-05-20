import 'package:flutter/material.dart';

class IndustrialPanelSurface extends StatelessWidget {
  const IndustrialPanelSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.dark = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IndustrialPanelPainter(dark: dark),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _IndustrialPanelPainter extends CustomPainter {
  const _IndustrialPanelPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      const Radius.circular(5),
    );

    canvas.drawShadow(Path()..addRRect(rrect), Colors.black, 7, false);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [
              Color(0xFF4B5253),
              Color(0xFF252B2C),
              Color(0xFF121617),
              Color(0xFF555E60),
            ]
          : const [
              Color(0xFFE9EEF0),
              Color(0xFFC7CFD2),
              Color(0xFF8D979B),
              Color(0xFFDDE3E5),
            ],
      stops: const [0, 0.36, 0.72, 1],
    );
    canvas.drawRRect(rrect, Paint()..shader = gradient.createShader(rect));

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF111517),
    );

    if (size.width >= 70 && size.height >= 44) {
      _fastener(canvas, const Offset(9, 9));
      _fastener(canvas, Offset(size.width - 9, 9));
      _fastener(canvas, Offset(9, size.height - 9));
      _fastener(canvas, Offset(size.width - 9, size.height - 9));
    }
  }

  void _fastener(Canvas canvas, Offset center) {
    final rect = Rect.fromCircle(center: center, radius: 4.4);
    canvas.drawCircle(
      center,
      4.4,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFF4F6F6), Color(0xFF778185), Color(0xFF181D1F)],
          stops: [0, 0.58, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      4.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF111517),
    );
    canvas.drawLine(
      center.translate(-2.2, 0),
      center.translate(2.2, 0),
      Paint()
        ..color = const Color(0xCC23282B)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IndustrialPanelPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
