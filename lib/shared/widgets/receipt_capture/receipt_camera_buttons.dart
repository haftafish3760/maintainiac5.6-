part of 'receipt_camera_screen.dart';

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: active
            ? const Color(0xFFFFD166)
            : const Color(0xDD11181B),
        foregroundColor: active ? const Color(0xFF101416) : Colors.white,
        minimumSize: const Size(42, 42),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFF526168), width: .8),
        ),
      ),
    );
  }
}
