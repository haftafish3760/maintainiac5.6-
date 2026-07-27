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
    return Column(
      children: [
        _ManualReceiptDateTimeAction(
          icon: Icons.calendar_month_rounded,
          label: 'Date · Required',
          value: date,
          onTap: onSelectDate,
        ),
        const SizedBox(height: 8),
        _ManualReceiptDateTimeAction(
          icon: Icons.schedule_rounded,
          label: 'Time · Optional',
          value: time,
          onTap: onSelectTime,
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
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF283337),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF41545B)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFFFD166)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFB7C8CE),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFFF2F7F8),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFD166)),
            ],
          ),
        ),
      ),
    );
  }
}
