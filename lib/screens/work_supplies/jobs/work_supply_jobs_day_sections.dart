part of 'work_supply_jobs_screen.dart';

class _JobsForDayPanel extends StatelessWidget {
  const _JobsForDayPanel({required this.day, required this.jobs});

  final DateTime day;
  final List<WorkSupplyJob> jobs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateLabel(day),
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            if (jobs.isEmpty)
              const Text(
                'No job activity scheduled for this date.',
                style: TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              for (final job in jobs) _JobTimelineRow(job: job),
          ],
        ),
      ),
    );
  }
}

class _JobTimelineRow extends StatelessWidget {
  const _JobTimelineRow({required this.job});

  final WorkSupplyJob job;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        '${job.number} | ${job.name} | ${job.mileage.toStringAsFixed(1)} mi',
        style: const TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final WorkSupplyJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF111A1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF44555D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.name,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                job.number,
                style: const TextStyle(
                  color: Color(0xFF8FD3FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (job.customerName.isNotEmpty || job.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                job.customerName,
                job.address,
              ].where((v) => v.isNotEmpty).join(' | '),
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _JobStat(label: '${job.mileage.toStringAsFixed(1)} mi'),
              _JobStat(label: _money(job.expenses)),
              _JobStat(label: '${job.inventoryItems} inventory items'),
              _JobStat(label: '${_money(job.invoiceTotal)} invoice'),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobStat extends StatelessWidget {
  const _JobStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A30),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC7D0D4),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Map<DateTime, List<WorkSupplyCalendarMarker>> _jobMarkers(
  List<WorkSupplyJob> jobs,
) {
  final counts = <DateTime, int>{};
  for (final job in jobs) {
    final date = job.scheduledDate;
    if (date == null) continue;
    final key = _dayKey(date);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return {
    for (final entry in counts.entries)
      entry.key: [
        WorkSupplyCalendarMarker(
          label: 'J',
          color: const Color(0xFF8FD3FF),
          count: entry.value,
        ),
      ],
  };
}

DateTime _dayKey(DateTime day) => DateTime.utc(day.year, day.month, day.day);

String _dateLabel(DateTime day) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[day.month - 1]} ${day.day}, ${day.year}';
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
