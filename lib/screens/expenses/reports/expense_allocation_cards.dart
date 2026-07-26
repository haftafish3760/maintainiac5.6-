part of 'expense_allocation_screen.dart';

class _CategoryAllocationCard extends StatelessWidget {
  const _CategoryAllocationCard({required this.row});

  final _AllocationRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _ReportSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: const TextStyle(
                      color: Color(0xFFF0F4F2),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  _money(row.total),
                  style: const TextStyle(
                    color: Color(0xFFF0B43C),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AllocationBar(
              businessPercent: row.businessPercent,
              personalPercent: row.personalPercent,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniAmount(
                    label: 'Business',
                    value: row.business,
                    percent: row.businessPercent,
                    color: const Color(0xFF249D62),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniAmount(
                    label: 'Personal',
                    value: row.personal,
                    percent: row.personalPercent,
                    color: const Color(0xFF2E78B7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.businessPercent,
    required this.personalPercent,
  });

  final double businessPercent;
  final double personalPercent;

  @override
  Widget build(BuildContext context) {
    final businessFlex = (businessPercent * 1000).round();
    final personalFlex = (personalPercent * 1000).round();
    final hasBusiness = businessFlex > 0;
    final hasPersonal = personalFlex > 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (hasBusiness)
              Expanded(
                flex: businessFlex.clamp(1, 1000),
                child: Container(color: const Color(0xFF249D62)),
              ),
            if (hasPersonal)
              Expanded(
                flex: personalFlex.clamp(1, 1000),
                child: Container(color: const Color(0xFF2E78B7)),
              ),
            if (!hasBusiness && !hasPersonal)
              Expanded(child: Container(color: const Color(0xFF56666E))),
          ],
        ),
      ),
    );
  }
}

class _MiniAmount extends StatelessWidget {
  const _MiniAmount({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final double value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4C585E)),
      ),
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
          const SizedBox(height: 4),
          Text(
            '${_money(value)} | ${(percent * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0B43C) : const Color(0xFF101719),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF11181B) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF9FAAAF),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF0F4F2),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _EmptyReportCard extends StatelessWidget {
  const _EmptyReportCard();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      child: Text(
        'No saved expenses in this period yet.',
        style: TextStyle(
          color: Color(0xFFC8D0D3),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2226),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3E4A50), width: 1.25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
