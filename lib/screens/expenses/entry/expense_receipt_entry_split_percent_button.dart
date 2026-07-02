part of 'expense_receipt_entry_screen.dart';

class _SplitPercentButton extends StatelessWidget {
  const _SplitPercentButton({
    required this.label,
    required this.percent,
    required this.onSelected,
  });

  final String label;
  final double percent;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onSelected(percent),
      icon: const Icon(Icons.percent_rounded, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8ECEE),
        side: const BorderSide(color: Color(0xFF526168)),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
