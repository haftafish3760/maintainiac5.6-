part of 'app_screen_shell.dart';

class _AppBackgroundPainter extends CustomPainter {
  const _AppBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3337), Color(0xFF354147), Color(0xFF222B30)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AppBackgroundPainter oldDelegate) => false;
}
