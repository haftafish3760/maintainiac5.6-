part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraShutterButton extends StatelessWidget {
  const _ReceiptNativeCameraShutterButton({
    required this.capturing,
    required this.onPressed,
  });

  final bool capturing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take receipt photo',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPressed == null
                  ? const Color(0xFF80888C)
                  : const Color(0xFFFFFFFF),
              border: Border.all(color: const Color(0xFF050607), width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: capturing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF101416),
                      ),
                    )
                  : const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF101416),
                      size: 30,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptNativeCameraIconButton extends StatelessWidget {
  const _ReceiptNativeCameraIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.visibleLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final String? visibleLabel;

  @override
  Widget build(BuildContext context) {
    final visible = visibleLabel?.trim();
    final button = IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: active
            ? const Color(0xFFFFD166)
            : const Color(0xDD11181B),
        foregroundColor: active ? const Color(0xFF101416) : Colors.white,
        disabledBackgroundColor: const Color(0x8811181B),
        disabledForegroundColor: const Color(0xFF8E9AA0),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF526168), width: .8),
        ),
      ),
    );
    if (visible == null || visible.isEmpty) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xCC11181B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF526168), width: .7),
          ),
          child: Text(
            visible,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptCameraVignette extends StatelessWidget {
  const _ReceiptCameraVignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x30000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0x54000000),
          ],
          stops: [0, .16, .78, 1],
        ),
      ),
    );
  }
}
