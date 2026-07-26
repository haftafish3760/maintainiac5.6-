part of 'expense_receipt_entry_screen.dart';

class _ReceiptWholeUseButton extends StatelessWidget {
  const _ReceiptWholeUseButton({
    required this.label,
    required this.helper,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String helper;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, textAlign: TextAlign.center, softWrap: true),
          Text(
            helper,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: const Color(0xFF76848A),
        side: BorderSide(
          color: onPressed == null
              ? const Color(0xFF526168)
              : color.withValues(alpha: .72),
        ),
        alignment: Alignment.centerLeft,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
