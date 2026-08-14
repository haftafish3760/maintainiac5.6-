part of 'receipt_photo_review_screen.dart';

/// Keeps the receipt itself usable while a person aligns two sections.
/// Movement, resize, and rotation happen directly on the lower section; this
/// strip deliberately stays short so it never covers the join being aligned.
class _ReceiptManualAlignmentControls extends StatelessWidget {
  const _ReceiptManualAlignmentControls({
    required this.onReset,
    required this.onHide,
  });

  final VoidCallback onReset;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Android and iOS users can both close the small help tray without
      // hunting for an icon. A right swipe is deliberately reserved for the
      // tray, while one-finger movement remains on the receipt itself.
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 240) onHide();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xD911181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF526168)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFF8FC9FF)),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Drag lower photo. Pinch to resize. Twist to straighten.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
              ),
              TextButton(onPressed: onReset, child: const Text('Reset')),
              OutlinedButton(
                onPressed: onHide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF0F4F2),
                  side: const BorderSide(color: Color(0xFF70808A)),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
                child: const Text('Hide'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
