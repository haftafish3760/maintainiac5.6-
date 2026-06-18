part of 'expenses_home_screen.dart';

class _ExpenseTotalsPanel extends StatelessWidget {
  const _ExpenseTotalsPanel({required this.period, required this.anchorDate});

  final _ExpenseViewPeriod period;
  final DateTime anchorDate;

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final range = period.rangeFor(anchorDate);
    final ledgerSummary = ledger.summaryForRange(range);
    final rangeLabel = period.rangeLabel(anchorDate);
    final detailLabel = '${period.buttonLabel} | $rangeLabel';
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
                  detail: '$rangeLabel | Active vehicle only',
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
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.end,
              children: [
                _SmallTextButton(
                  label: 'Export',
                  icon: Icons.file_download_rounded,
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  iconColor: Colors.white,
                  onTap: () => _openExpenseExport(context),
                ),
                _SmallTextButton(
                  label: 'Business vs Personal',
                  icon: Icons.compare_arrows_rounded,
                  backgroundColor: _gold,
                  foregroundColor: _ink,
                  iconColor: _ink,
                  onTap: () => _openExpenseAllocationReport(
                    context,
                    range: range,
                    rangeLabel: detailLabel,
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
