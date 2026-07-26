part of 'expense_recap_screen.dart';

class _RecapHeroPanel extends StatelessWidget {
  const _RecapHeroPanel({required this.report, required this.rangeLabel});

  final ExpenseRecapReport report;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecapPanelHeader(
            eyebrow: 'SUMMARY',
            title: _money(report.totalExpenses),
            detail: rangeLabel,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Business',
                  value: _money(report.businessExpenses),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _MiniMetric(
                  label: 'Personal',
                  value: _money(report.personalExpenses),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _MiniMetric(
                  label: 'Receipts',
                  value: report.receiptCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapTileGrid extends StatelessWidget {
  const _RecapTileGrid({required this.tiles, required this.report});

  final List<ExpenseRecapTileDefinition> tiles;
  final ExpenseRecapReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 430 ? 2 : 3;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: _RecapTile(tile: tile, report: report),
              ),
          ],
        );
      },
    );
  }
}

class _RecapTile extends StatelessWidget {
  const _RecapTile({required this.tile, required this.report});

  final ExpenseRecapTileDefinition tile;
  final ExpenseRecapReport report;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tile.group.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9FAAAF),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tile.title,
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            Text(
              tile.valueFor(report),
              style: const TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tile.detailFor(report),
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecapTiles extends StatelessWidget {
  const _EmptyRecapTiles({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecapPanelHeader(
            eyebrow: 'RECAP',
            title: 'No tiles visible',
            detail: 'Turn recap tiles back on from settings.',
          ),
          const SizedBox(height: 8),
          _SmallRecapButton(
            label: 'Show Everything',
            icon: Icons.restart_alt_rounded,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class _RecapPanel extends StatelessWidget {
  const _RecapPanel({
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        border: Border.all(color: const Color(0xFF445159), width: 1.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecapPanelHeader extends StatelessWidget {
  const _RecapPanelHeader({
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
            height: 1.05,
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

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD166),
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

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
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
      color: selected ? const Color(0xFFFFD166) : const Color(0xFF172126),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF101416) : Colors.white,
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

class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFFFFD166), size: 24),
      ),
    );
  }
}

class _SmallRecapButton extends StatelessWidget {
  const _SmallRecapButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2E78B7),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 9, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
