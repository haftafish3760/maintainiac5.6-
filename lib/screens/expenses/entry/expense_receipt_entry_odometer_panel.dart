part of 'expense_receipt_entry_screen.dart';

class _ExpenseOdometerPanel extends StatelessWidget {
  const _ExpenseOdometerPanel({required this.reading, required this.onEdit});

  final int? reading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.speed_rounded,
            color: Color(0xFF8FC9FF),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reading == null
                  ? 'Add the current odometer to include it with this expense.'
                  : 'Odometer included: $reading miles',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8FC9FF),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(reading == null ? 'Add Odometer' : 'Edit'),
          ),
        ],
      ),
    );
  }
}
