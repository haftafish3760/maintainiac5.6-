part of 'expense_export_screen.dart';

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B1113),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF445159)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFFFFD166),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportPanel extends StatelessWidget {
  const _ExportPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD166), size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Color(0xFFC8D0D3),
      fontWeight: FontWeight.w800,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFFF0F4F2),
      fontWeight: FontWeight.w900,
    ),
    filled: true,
    fillColor: const Color(0xFF0B1113),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFF56666E)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFF56666E)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFFFFD166)),
    ),
  );
}

DateTime _dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);
DateTime _monthStart(DateTime day) => DateTime(day.year, day.month);

String _shortDate(DateTime day) {
  return '${day.month}/${day.day}/${day.year}';
}

String _fullDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_shortDate(value)} $hour:$minute $period';
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

IconData _destinationIcon(ExpenseExportDestination destination) {
  return switch (destination) {
    ExpenseExportDestination.share => Icons.ios_share_rounded,
    ExpenseExportDestination.saveFiles => Icons.folder_rounded,
    ExpenseExportDestination.email => Icons.email_rounded,
    ExpenseExportDestination.textMessage => Icons.sms_rounded,
    ExpenseExportDestination.print => Icons.print_rounded,
  };
}
