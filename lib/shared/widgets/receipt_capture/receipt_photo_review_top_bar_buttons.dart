part of 'receipt_photo_review_screen.dart';

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xDD11181B),
        foregroundColor: Colors.white,
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

class _ReceiptShowReviewControlsButton extends StatelessWidget {
  const _ReceiptShowReviewControlsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Show receipt review controls',
      child: Semantics(
        button: true,
        label: 'Show receipt review controls',
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.fullscreen_exit_rounded, size: 17),
          label: const Text(
            'Controls',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: const Color(0xDD11181B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFF526168), width: .8),
            ),
            textStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
