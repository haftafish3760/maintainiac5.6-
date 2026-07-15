part of 'expense_receipt_entry_screen.dart';

class _ExpenseOdometerPanel extends StatelessWidget {
  const _ExpenseOdometerPanel({required this.reading, required this.onEdit});

  final int? reading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return RecordFormPanel(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Optional vehicle odometer'),
          subtitle: Text(
            reading == null
                ? 'No reading added to this expense'
                : '${reading.toString()} miles',
          ),
          trailing: OutlinedButton(
            onPressed: onEdit,
            child: Text(reading == null ? 'Add' : 'Edit'),
          ),
        ),
      ],
    );
  }
}
