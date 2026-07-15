import 'package:flutter/material.dart';

import '../../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import '../data/expense_work_profile_store.dart';
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
  var _selectedVehicleId = '';
  var _selectedWorkProfileId = '';

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
    final appState = AppStateScope.of(context);
    final profiles = ExpenseWorkProfileScope.of(context);
    final vehicleId = _selectedVehicleId.isEmpty
        ? null
        : odometerVehicleIdForVehicleId(
            _selectedVehicleId,
            fallbackLabel: appState.vehicles
                .firstWhere(
                  (vehicle) => vehicle.id == _selectedVehicleId,
                  orElse: () => appState.activeVehicle!,
                )
                .nickname,
          );
    final range = _period.rangeFor(_anchorDate, customRange: _customRange);
    final report = ExpenseRecapReport.fromLedger(
      ExpenseLedgerScope.of(context),
      range,
      vehicleId: vehicleId,
      workProfileId: _selectedWorkProfileId,
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
            selectedVehicleId: _selectedVehicleId,
            selectedWorkProfileId: _selectedWorkProfileId,
            vehicles: appState.vehicles,
            workProfiles: profiles.profiles,
            onVehicleChanged: (vehicleId) =>
                setState(() => _selectedVehicleId = vehicleId),
            onWorkProfileChanged: (profileId) =>
                setState(() => _selectedWorkProfileId = profileId),
          ),
          const SizedBox(height: 8),
          _RecapHeroPanel(
            report: report,
            rangeLabel: _scopeRangeLabel(appState, profiles),
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

  String _scopeRangeLabel(
    AppStateController appState,
    ExpenseWorkProfileController profiles,
  ) {
    final vehicleScope = _selectedVehicleId.isEmpty
        ? 'All vehicles'
        : appState.vehicles
              .firstWhere(
                (vehicle) => vehicle.id == _selectedVehicleId,
                orElse: () => appState.activeVehicle!,
              )
              .nickname;
    final profileScope = _selectedWorkProfileId.isEmpty
        ? 'Grand Total'
        : profiles.profiles
              .firstWhere(
                (profile) => profile.id == _selectedWorkProfileId,
                orElse: () => profiles.activeWorkProfile,
              )
              .name;
    return '$profileScope · $vehicleScope | $_rangeLabel';
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
String _money(double value) => '\$${value.toStringAsFixed(2)}';
