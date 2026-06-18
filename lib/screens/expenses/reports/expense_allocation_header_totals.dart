part of 'expense_allocation_screen.dart';

class _ReportHeader extends StatelessWidget {
  const _ReportHeader();

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business vs Personal',
                  style: TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Expenses',
                  style: TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalAllocationCard extends StatelessWidget {
  const _TotalAllocationCard({required this.report, required this.rangeLabel});

  final _AllocationReport report;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionTitle(
                  eyebrow: 'SHARED',
                  title: 'Shared Expenses',
                  detail: 'Business vs Personal',
                ),
              ),
              _TotalAmount(
                value: _money(report.total),
                caption: 'Total Shared',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rangeLabel,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _AllocationBar(
            businessPercent: report.businessPercent,
            personalPercent: report.personalPercent,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniAmount(
                  label: 'Business',
                  value: report.business,
                  percent: report.businessPercent,
                  color: const Color(0xFF249D62),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniAmount(
                  label: 'Personal',
                  value: report.personal,
                  percent: report.personalPercent,
                  color: const Color(0xFF2E78B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalAmount extends StatelessWidget {
  const _TotalAmount({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF0B43C),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: .95,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          caption,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
