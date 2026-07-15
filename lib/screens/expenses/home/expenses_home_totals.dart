part of 'expenses_home_screen.dart';

class _ExpenseTotalsPanel extends StatelessWidget {
  const _ExpenseTotalsPanel({
    required this.period,
    required this.anchorDate,
    required this.showAllProfiles,
    required this.onToggleProfileScope,
  });

  final _ExpenseViewPeriod period;
  final DateTime anchorDate;
  final bool showAllProfiles;
  final VoidCallback onToggleProfileScope;

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final activeContext = OperationalContextScope.of(context).context;
    final range = period.rangeFor(anchorDate);
    final scope = showAllProfiles
        ? const ExpenseLedgerScopeFilter()
        : ExpenseLedgerScopeFilter(
            workProfileId: activeContext.workProfileId,
            vehicleId: activeContext.activeVehicleId,
          );
    final ledgerSummary = ledger.summaryForRange(range, scope: scope);
    final rangeLabel = period.rangeLabel(anchorDate);
    final detailLabel = '${period.buttonLabel} | $rangeLabel';
    final scopeLabel = showAllProfiles
        ? 'All profiles'
        : '${activeContext.workProfileName} · ${activeContext.activeVehicleLabel}';
    return _SolidSection(
      backgroundColor: _paper,
      borderColor: const Color(0xFF3E4A50),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionHeader(
                  eyebrow: period.eyebrow,
                  title: period.title,
                  detail: '$rangeLabel | $scopeLabel',
                ),
              ),
              _BigMoney(
                value: _money(ledgerSummary.total),
                caption: period.totalCaption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final stats = [
                _MoneyStatData(
                  '${period.statPrefix} Business Expenses',
                  _money(ledgerSummary.business),
                  _green,
                  scope: 'Business',
                  range: range,
                  detail: detailLabel,
                ),
                _MoneyStatData(
                  '${period.statPrefix} Personal Expenses',
                  _money(ledgerSummary.personal),
                  _blue,
                  scope: 'Personal',
                  range: range,
                  detail: detailLabel,
                ),
              ];
              if (narrow) {
                return Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final stat in stats)
                      SizedBox(
                        width: (constraints.maxWidth - 7) / 2,
                        child: _MoneyStat(stat: stat),
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < stats.length; index++) ...[
                    if (index > 0) const SizedBox(width: 7),
                    Expanded(child: _MoneyStat(stat: stats[index])),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onToggleProfileScope,
              icon: Icon(
                showAllProfiles ? Icons.filter_alt_off : Icons.filter_alt,
                size: 18,
              ),
              label: Text(
                showAllProfiles ? 'Show current profile' : 'Show all profiles',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _SmallTextButton(
              label: 'View Day',
              icon: Icons.calendar_today_rounded,
              backgroundColor: _gold,
              foregroundColor: _ink,
              iconColor: _ink,
              onTap: () => Navigator.of(context).push(
                appNativeRoute<void>(
                  context,
                  ExpenseDayScreen(day: anchorDate),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
