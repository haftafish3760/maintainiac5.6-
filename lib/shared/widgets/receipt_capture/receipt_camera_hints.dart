part of 'receipt_camera_screen.dart';

class _ReceiptCameraHints extends StatelessWidget {
  const _ReceiptCameraHints();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        _HintChip(icon: Icons.crop_free_rounded, label: 'Fill the frame'),
        _HintChip(icon: Icons.pan_tool_alt_rounded, label: 'Hold steady'),
        _HintChip(icon: Icons.touch_app_rounded, label: 'Tap text to focus'),
        _HintChip(icon: Icons.light_mode_rounded, label: 'Avoid glare'),
        _HintChip(
          icon: Icons.receipt_long_rounded,
          label: 'Long receipt: use sections',
        ),
      ],
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD11181B),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF526168), width: .8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFFFD166)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
