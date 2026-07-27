part of 'receipt_photo_review_screen.dart';

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foregroundColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xDD11181B),
        foregroundColor: foregroundColor,
        disabledBackgroundColor: const Color(0x6611181B),
        disabledForegroundColor: const Color(0xFF6E7B81),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF526168), width: .8),
        ),
      ),
    );
  }
}
