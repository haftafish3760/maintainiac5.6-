import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart'
    show AppSection, GlobalOdometerHeader;
import '../../shared/widgets/record_text_field.dart';
import 'maintenance_draft_store.dart';
import 'maintenance_log_service_screen.dart';
import 'maintenance_models.dart';
import 'maintenance_svg_icon.dart';

part 'maintenance_item_detail_widgets.dart';
part 'maintenance_item_detail_controls.dart';
part 'maintenance_item_detail_last_service.dart';
part 'maintenance_item_detail_draft_restore.dart';
part 'maintenance_item_detail_leave_guard.dart';
part 'maintenance_item_detail_utils.dart';
part 'maintenance_item_detail_calculations.dart';

class MaintenanceItemDetailScreen extends StatefulWidget {
  const MaintenanceItemDetailScreen({required this.record, super.key});

  final MaintenanceRecord record;

  @override
  State<MaintenanceItemDetailScreen> createState() =>
      _MaintenanceItemDetailScreenState();
}

class _MaintenanceItemDetailScreenState
    extends State<MaintenanceItemDetailScreen> {
  late final MaintenanceCatalogItem _catalogItem = maintenanceCatalog
      .firstWhere(
        (item) => item.name == widget.record.itemName,
        orElse: () => MaintenanceCatalogItem(
          name: widget.record.itemName,
          icon: '',
          importance: widget.record.importance,
          defaultMiles: widget.record.intervalMiles,
          defaultMonths: widget.record.intervalMonths,
          detailA: 'Detail',
          detailB: 'Specification',
          timeOnly: widget.record.timeOnly,
        ),
      );
  late DateTime _lastServiceDate =
      widget.record.lastServiceDate ?? DateTime.now();
  late int _mileInterval = widget.record.setupComplete
      ? widget.record.intervalMiles
      : 0;
  late int _monthInterval = widget.record.setupComplete
      ? widget.record.intervalMonths
      : 0;
  late String _detailA = widget.record.detailA;
  late String _detailB = widget.record.detailB;
  late bool _advanced = false;
  late final bool _dateEstimated = widget.record.lastServiceEstimated;
  late final bool _odometerEstimated = widget.record.lastOdometerEstimated;
  late bool _thresholdsEnabled = widget.record.thresholdsEnabled;
  late bool _inAppNotifications = widget.record.inAppNotifications;
  late bool _pushNotifications = widget.record.pushNotifications;
  late bool _soundNotifications = widget.record.soundNotifications;
  late bool _pairOilFilter = widget.record.pairOilFilter;
  var _dateEntryMode = _LastDateEntryMode.date;
  var _odometerEntryMode = _LastOdometerEntryMode.reading;
  late final _lastServiceOdometer = TextEditingController(
    text: widget.record.lastServiceOdometer == 0
        ? ''
        : widget.record.lastServiceOdometer.toString(),
  );
  late final _monthsSinceService = TextEditingController(
    text: widget.record.monthsSinceService == 0
        ? ''
        : widget.record.monthsSinceService.toString(),
  );
  late final _milesSinceService = TextEditingController(
    text: widget.record.milesSinceService == 0
        ? ''
        : widget.record.milesSinceService.toString(),
  );
  late final _customMiles = TextEditingController();
  late final _customMonths = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreSetupDraft();
  }

  void _applyRestoredSetupDraft(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  void _updateSetupState(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  @override
  void dispose() {
    _lastServiceOdometer.dispose();
    _monthsSinceService.dispose();
    _milesSinceService.dispose();
    _customMiles.dispose();
    _customMonths.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final currentOdometer = GlobalOdometerScope.of(context).reading;
    final record = appState.maintenance.firstWhere(
      (item) =>
          item.itemName == widget.record.itemName &&
          item.vehicleName == widget.record.vehicleName,
      orElse: () => widget.record,
    );
    final nextOdometer = _canPreviewNextDue
        ? _nextOdometer(currentOdometer)
        : null;
    final nextDate = _canPreviewNextDue
        ? _addMonths(_lastServiceDate, _effectiveMonthInterval)
        : null;

    return PopScope(
      canPop: !_hasUnsavedSetupWork(record),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardSetup()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                const GlobalOdometerHeader(section: AppSection.maintenance),
                const SizedBox(height: 10),
                AppScreenHeader(title: record.itemName),
                const SizedBox(height: 10),
                _ItemIdentitySection(record: record),
                const SizedBox(height: 10),
                _SetupSection(
                  title: 'Last Service Information',
                  child: _LastServiceEntrySection(
                    timeOnly: record.timeOnly,
                    dateMode: _dateEntryMode,
                    odometerMode: _odometerEntryMode,
                    lastServiceDate: _lastServiceDate,
                    lastServiceOdometer: _lastServiceOdometer,
                    monthsSinceService: _monthsSinceService,
                    milesSinceService: _milesSinceService,
                    onDateModeChanged: (mode) =>
                        setState(() => _dateEntryMode = mode),
                    onOdometerModeChanged: (mode) =>
                        setState(() => _odometerEntryMode = mode),
                    onPickDate: _pickLastServiceDate,
                  ),
                ),
                const SizedBox(height: 10),
                _SetupSection(
                  title: 'Service Mode',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AdvancedDisclosure(
                        advanced: _advanced,
                        onTap: () => setState(() => _advanced = !_advanced),
                      ),
                      if (_catalogItem.name == 'Engine Oil') ...[
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _pairOilFilter,
                          activeThumbColor: AppActionColors.positive,
                          title: const Text(
                            'Also service oil filter',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: const Text(
                            'Keep this on if you normally change the filter with the oil.',
                          ),
                          onChanged: (value) =>
                              setState(() => _pairOilFilter = value),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (_advanced)
                        _ResponsiveTwoColumn(
                          left: _DetailDropdown(
                            label: _catalogItem.detailA,
                            value: _detailA,
                            options: _catalogItem.detailAOptions,
                            onChanged: (value) =>
                                setState(() => _detailA = value),
                          ),
                          right: _DetailDropdown(
                            label: _catalogItem.detailB,
                            value: _detailB,
                            options: _catalogItem.detailBOptions,
                            onChanged: (value) =>
                                setState(() => _detailB = value),
                          ),
                        ),
                      if (_advanced) const SizedBox(height: 10),
                      if (record.timeOnly)
                        _IntervalSelector(
                          label: 'Time Interval',
                          value: _effectiveMonthInterval,
                          options: _monthOptions,
                          itemLabel: _monthLabel,
                          onPreset: (value) => setState(() {
                            _monthInterval = value;
                            _customMonths.clear();
                          }),
                          onCustom: () => _setCustomMonths(),
                        )
                      else
                        _ResponsiveTwoColumn(
                          left: _IntervalSelector(
                            label: 'Mileage Interval',
                            value: _effectiveMileInterval,
                            options: _mileOptions,
                            itemLabel: _intervalLabel,
                            onPreset: (value) => setState(() {
                              _mileInterval = value;
                              _customMiles.clear();
                            }),
                            onCustom: () => _setCustomMiles(),
                          ),
                          right: _IntervalSelector(
                            label: 'Time Interval',
                            value: _effectiveMonthInterval,
                            options: _monthOptions,
                            itemLabel: _monthLabel,
                            onPreset: (value) => setState(() {
                              _monthInterval = value;
                              _customMonths.clear();
                            }),
                            onCustom: () => _setCustomMonths(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _NextDueSection(
                  nextOdometer: record.timeOnly ? null : nextOdometer,
                  nextDate: nextDate,
                ),
                const SizedBox(height: 10),
                _NotificationSection(
                  inApp: _inAppNotifications,
                  push: _pushNotifications,
                  sound: _soundNotifications,
                  onInApp: (value) =>
                      setState(() => _inAppNotifications = value),
                  onPush: (value) => setState(() => _pushNotifications = value),
                  onSound: (value) =>
                      setState(() => _soundNotifications = value),
                ),
                const SizedBox(height: 10),
                _SetupSection(
                  title: 'Thresholds',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _thresholdsEnabled,
                        activeThumbColor: AppActionColors.positive,
                        title: const Text(
                          'Use colored due thresholds',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        onChanged: (value) =>
                            setState(() => _thresholdsEnabled = value),
                      ),
                      if (_thresholdsEnabled) ...[
                        const SizedBox(height: 8),
                        _ThresholdBandColumns(
                          showMileage: !record.timeOnly,
                          longTimeWindow: _usesLongTimeThresholds,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    AppButton(
                      label: 'Log This Service',
                      compact: true,
                      onPressed: () => Navigator.of(context).push(
                        appNativeRoute<void>(
                          context,
                          MaintenanceLogServiceScreen(records: [record]),
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Save Setup',
                      tone: AppButtonTone.commit,
                      compact: true,
                      onPressed: _canPreviewNextDue
                          ? () => _save(appState, currentOdometer, record)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
