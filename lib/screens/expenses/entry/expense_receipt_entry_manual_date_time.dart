part of 'expense_receipt_entry_screen.dart';

class _ManualReceiptDateTimeStrip extends StatelessWidget {
  const _ManualReceiptDateTimeStrip({
    required this.date,
    required this.time,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  final String date;
  final String time;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ManualReceiptDateTimeAction(
            icon: Icons.calendar_month_rounded,
            label: 'DATE',
            value: date,
            onTap: onSelectDate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ManualReceiptDateTimeAction(
            icon: Icons.schedule_rounded,
            label: 'TIME (OPTIONAL)',
            value: time,
            onTap: onSelectTime,
          ),
        ),
      ],
    );
  }
}

class _ManualReceiptDateTimeAction extends StatelessWidget {
  const _ManualReceiptDateTimeAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 82,
          padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
          decoration: BoxDecoration(
            color: _receiptReferenceSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _receiptReferenceBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _receiptReferenceMuted),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _receiptReferenceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _receiptReferenceText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _receiptReferenceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
