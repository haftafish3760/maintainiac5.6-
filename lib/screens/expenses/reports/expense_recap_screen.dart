import 'package:flutter/material.dart';

import '../../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import 'expense_recap_models.dart';

class ExpenseRecapScreen extends StatefulWidget {
  const ExpenseRecapScreen({super.key, this.initialDate, this.initialRange});

  final DateTime? initialDate;
  final ExpenseDateRange? initialRange;

  @override
  State<ExpenseRecapScreen> createState() => _ExpenseRecapScreenState();
}

class _ExpenseRecapScreenState extends State<ExpenseRecapScreen> {
  late var _anchorDate = _dateOnly(widget.initialDate ?? DateTime.now());
  late var _customRange =
      widget.initialRange ??
      ExpenseDateRange(start: _anchorDate, end: _anchorDate);
  var _period = ExpenseRecapPeriod.month;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _period = ExpenseRecapPeriod.custom;
      _anchorDate = widget.initialRange!.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ExpenseSettingsScope.of(context);
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    final vehicleId = activeVehicle == null
        ? null
        : odometerVehicleIdForLabel(activeVehicle.nickname);
    final range = _period.rangeFor(_anchorDate, customRange: _customRange);
    final report = ExpenseRecapReport.fromLedger(
      ExpenseLedgerScope.of(context),
      range,
      vehicleId: vehicleId,
    );
    final visibleTiles = expenseRecapTileDefinitions
        .where((tile) => settings.recapTileVisible(tile.id))
        .toList(growable: false);
    return AppScreenShell(
      section: AppSection.expenses,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        children: [
          const AppScreenHeader(title: 'Expense Recap'),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(section: AppSection.expenses),
          const SizedBox(height: 8),
          _RecapRangePanel(
            period: _period,
            anchorDate: _anchorDate,
            customRange: _customRange,
            onPeriodChanged: (period) => setState(() => _period = period),
            onShift: (direction) {
              if (_period == ExpenseRecapPeriod.custom) return;
              setState(
                () => _anchorDate = _period.shift(_anchorDate, direction),
              );
            },
            onCustomRangeChanged: (range) => setState(() {
              _customRange = range;
              _period = ExpenseRecapPeriod.custom;
              _anchorDate = range.end;
            }),
          ),
          const SizedBox(height: 8),
          _RecapHeroPanel(
            report: report,
            rangeLabel: _scopeRangeLabel(activeVehicle),
          ),
          const SizedBox(height: 8),
          if (visibleTiles.isEmpty)
            _EmptyRecapTiles(onReset: settings.resetRecapTiles)
          else
            _RecapTileGrid(tiles: visibleTiles, report: report),
        ],
      ),
    );
  }

  String get _rangeLabel =>
      _period.rangeLabel(_anchorDate, customRange: _customRange);

  String _scopeRangeLabel(VehicleProfile? activeVehicle) {
    final scope = activeVehicle == null
        ? 'All company expenses'
        : activeVehicle.nickname;
    return '$scope • $_rangeLabel';
  }
}

class _RecapRangePanel extends StatelessWidget {
  const _RecapRangePanel({
    required this.period,
    required this.anchorDate,
    required this.customRange,
    required this.onPeriodChanged,
    required this.onShift,
    required this.onCustomRangeChanged,
  });

  final ExpenseRecapPeriod period;
  final DateTime anchorDate;
  final ExpenseDateRange customRange;
  final ValueChanged<ExpenseRecapPeriod> onPeriodChanged;
  final ValueChanged<int> onShift;
  final ValueChanged<ExpenseDateRange> onCustomRangeChanged;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecapPanelHeader(
            eyebrow: 'RANGE',
            title: 'Recap period',
            detail: 'Choose the time window for every visible tile.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in ExpenseRecapPeriod.values)
                _PeriodChip(
                  label: option.label,
                  selected: option == period,
                  onTap: () => onPeriodChanged(option),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _IconSquare(
                icon: Icons.chevron_left_rounded,
                onTap: () => onShift(-1),
              ),
              Expanded(
                child: Text(
                  period.rangeLabel(anchorDate, customRange: customRange),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _IconSquare(
                icon: Icons.chevron_right_rounded,
                onTap: () => onShift(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CustomRangeButtons(
            range: customRange,
            onChanged: onCustomRangeChanged,
          ),
        ],
      ),
    );
  }
}

class _CustomRangeButtons extends StatelessWidget {
  const _CustomRangeButtons({required this.range, required this.onChanged});

  final ExpenseDateRange range;
  final ValueChanged<ExpenseDateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _SmallRecapButton(
          label: 'Start',
          icon: Icons.first_page_rounded,
          onTap: () => _pickDate(context, isStart: true),
        ),
        _SmallRecapButton(
          label: 'End',
          icon: Icons.last_page_rounded,
          onTap: () => _pickDate(context, isStart: false),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? range.start : range.end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    final clean = _dateOnly(picked);
    final next = isStart
        ? ExpenseDateRange(
            start: clean,
            end: clean.isAfter(range.end) ? clean : range.end,
          )
        : ExpenseDateRange(
            start: clean.isBefore(range.start) ? clean : range.start,
            end: clean,
          );
    onChanged(next);
  }
}

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
String _money(double value) => '\$${value.toStringAsFixed(2)}';
