import 'package:flutter/material.dart';

import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/expense_job_store.dart';
import '../data/expense_ledger_scope_filter.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import '../data/expense_work_profile_store.dart';
import '../data/expense_vehicle_profile_store.dart';
import 'expense_recap_models.dart';

part 'expense_recap_range_panel.dart';
part 'expense_recap_scope_panel.dart';
part 'expense_recap_tile_panels.dart';

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
  var _workProfileId = '';
  var _vehicleId = '';
  var _jobId = '';

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
    final workProfiles = ExpenseWorkProfileScope.of(context).activeProfiles;
    final vehicleProfiles = ExpenseVehicleProfileScope.of(
      context,
    ).activeProfiles;
    final jobs = ExpenseJobScope.of(context).activeJobs;
    final range = _period.rangeFor(_anchorDate, customRange: _customRange);
    final report = ExpenseRecapReport.fromLedger(
      ExpenseLedgerScope.of(context),
      range,
      scope: ExpenseLedgerScopeFilter(
        workProfileId: _workProfileId,
        vehicleId: _vehicleId,
        jobId: _jobId,
      ),
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
          _RecapScopePanel(
            workProfileId: _workProfileId,
            vehicleId: _vehicleId,
            jobId: _jobId,
            workProfiles: workProfiles,
            vehicles: vehicleProfiles,
            jobs: jobs,
            onWorkProfileChanged: (value) =>
                setState(() => _workProfileId = value),
            onVehicleChanged: (value) => setState(() => _vehicleId = value),
            onJobChanged: (value) => setState(() => _jobId = value),
          ),
          const SizedBox(height: 8),
          _RecapHeroPanel(
            report: report,
            rangeLabel: _scopeRangeLabel(
              workProfiles: workProfiles,
              vehicles: vehicleProfiles,
              jobs: jobs,
            ),
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

  String _scopeRangeLabel({
    required List<ExpenseWorkProfileRecord> workProfiles,
    required List<ExpenseVehicleProfileRecord> vehicles,
    required List<ExpenseJobRecord> jobs,
  }) {
    final selectedJob = _firstMatching(jobs, _jobId);
    final selectedWorkProfile = _firstMatching(workProfiles, _workProfileId);
    final selectedVehicle = _firstMatching(
      vehicles,
      _vehicleId,
      idFor: (vehicle) => vehicle.id,
    );
    final scopes = [
      if (selectedWorkProfile != null) selectedWorkProfile.name,
      if (selectedVehicle != null) selectedVehicle.nickname,
      if (selectedJob != null) selectedJob.name,
    ];
    final scope = scopes.isEmpty ? 'Everything together' : scopes.join(' | ');
    return '$scope | $_rangeLabel';
  }
}

T? _firstMatching<T>(
  Iterable<T> values,
  String id, {
  String Function(T value)? idFor,
}) {
  final normalizedId = id.trim();
  if (normalizedId.isEmpty) return null;
  for (final value in values) {
    final candidate = idFor?.call(value) ?? (value as dynamic).id as String;
    if (candidate == normalizedId) return value;
  }
  return null;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
String _money(double value) => '\$${value.toStringAsFixed(2)}';
