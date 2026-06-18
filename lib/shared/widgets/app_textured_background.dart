part of 'app_screen_shell.dart';

class AppTexturedBackground extends StatelessWidget {
  const AppTexturedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _AppBackgroundPainter(),
      child: SizedBox.expand(child: child),
    );
  }
}
