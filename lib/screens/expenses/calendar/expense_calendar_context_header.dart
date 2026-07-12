part of 'expense_calendar.dart';

class _ExpenseCalendarContextHeader extends StatelessWidget {
  const _ExpenseCalendarContextHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final vehicle = AppStateScope.of(context).activeVehicle?.displayName;
    final scope = vehicle == null || vehicle.trim().isEmpty
        ? 'All vehicles'
        : vehicle.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY',
            style: TextStyle(
              color: Color(0xFF9FAAAF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Daily Expenses',
            style: TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$scope expenses | ${calendarFullDateLabel(day)}',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
