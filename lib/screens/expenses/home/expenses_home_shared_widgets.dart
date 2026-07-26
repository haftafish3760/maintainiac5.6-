part of 'expenses_home_screen.dart';

class _SolidSection extends StatelessWidget {
  const _SolidSection({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.25),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
            height: 1.18,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _BigMoney extends StatelessWidget {
  const _BigMoney({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: _gold,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: .95,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _MoneyStat extends StatelessWidget {
  const _MoneyStat({required this.stat});

  final _MoneyStatData stat;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _openMoneyStat(context, stat),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4C585E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.label,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.value,
                style: TextStyle(
                  color: stat.color,
                  fontSize: 17,
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

class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor = const Color(0xFF101719),
    this.foregroundColor = const Color(0xFFEAF0EE),
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 9, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor ?? _gold, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
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

class _QuickExpenseTile extends StatelessWidget {
  const _QuickExpenseTile({
    required this.category,
    this.onTap,
    this.range,
    this.periodLabel,
    this.initialDate,
  });

  final ExpenseCategoryDefinition category;
  final VoidCallback? onTap;
  final ExpenseDateRange? range;
  final String? periodLabel;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    final accent = category.gradient.first;
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap:
            onTap ??
            () => _showCategoryEntries(
              context,
              category,
              range ?? _weekRange(DateTime.now()),
              periodLabel ?? 'Selected period',
            ),
        borderRadius: BorderRadius.circular(8),
        onLongPress: () =>
            _showCategoryInfo(context, category, initialDate: initialDate),
        child: Container(
          height: 94,
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF385864), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF071013),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: accent, width: 1.1),
                    ),
                    child: Icon(
                      _iconFor(category.icon),
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: accent, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                category.label,
                style: const TextStyle(
                  color: Color(0xFFF0F4F2),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              _TileAmountPill(
                label: _quickActionTotalFor(
                  context,
                  category.category,
                  range: range,
                  periodLabel: periodLabel,
                ),
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileAmountPill extends StatelessWidget {
  const _TileAmountPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 124),
        padding: const EdgeInsets.fromLTRB(6, 3, 6, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF071013),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF4C585E)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
