import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart'
    show AppSection, GlobalOdometerHeader;
import '../../shared/widgets/record_text_field.dart';
import '../../shared/widgets/structural_border_label.dart';
import 'maintenance_draft_store.dart';
import 'maintenance_form_surface.dart';
import 'maintenance_item_detail_screen.dart';
import 'maintenance_svg_icon.dart';

part 'maintenance_log_service_widgets.dart';
part 'maintenance_log_service_draft_restore.dart';
part 'maintenance_log_service_steps.dart';

class MaintenanceLogServiceScreen extends StatefulWidget {
  const MaintenanceLogServiceScreen({required this.records, super.key});

  final List<MaintenanceRecord> records;

  @override
  State<MaintenanceLogServiceScreen> createState() =>
      _MaintenanceLogServiceScreenState();
}

class _MaintenanceLogServiceScreenState
    extends State<MaintenanceLogServiceScreen> {
  late final Set<MaintenanceRecord> _selected = widget.records.length == 1
      ? {widget.records.first}
      : <MaintenanceRecord>{};
  late var _step = widget.records.length == 1 ? 1 : 0;
  var _activeItemIndex = 0;
  var _serviceDate = DateTime.now();
  final _odometer = TextEditingController();
  final _provider = TextEditingController();
  final _notes = TextEditingController();
  var _seededOdometer = false;
  var _odometerAutoSeeded = false;
  var _updatingOdometerProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _odometer.addListener(_refreshFormState);
    _restoreLogDraft();
  }

  void _applyRestoredLogDraft(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  void _updateLogState(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  void _goToStep(int step) {
    _updateLogState(() => _step = step);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seedOdometerWhenRequired();
  }

  void _seedOdometerWhenRequired() {
    if (_seededOdometer || !_requiresOdometer) return;
    _setOdometerProgrammatically(
      GlobalOdometerScope.of(context).reading.toString(),
      autoSeeded: true,
    );
    _seededOdometer = true;
  }

  void _setOdometerProgrammatically(String value, {required bool autoSeeded}) {
    _updatingOdometerProgrammatically = true;
    _odometer.text = value;
    _updatingOdometerProgrammatically = false;
    _odometerAutoSeeded = autoSeeded;
  }

  @override
  void dispose() {
    _odometer.removeListener(_refreshFormState);
    _odometer.dispose();
    _provider.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _refreshFormState() {
    if (!_updatingOdometerProgrammatically) _odometerAutoSeeded = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedLogWork,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardLog()) {
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
                const AppScreenHeader(title: 'Log Maintenance'),
                const SizedBox(height: 10),
                if (_step == 0) _buildItemStep(),
                if (_step == 1) _buildDetailsStep(),
                if (_step == 2) _buildReviewStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _vehicleLabel {
    if (_selected.isNotEmpty) return _selected.first.vehicleName;
    if (widget.records.isNotEmpty) return widget.records.first.vehicleName;
    return 'Active vehicle';
  }

  bool get _requiresOdometer => _selected.any((record) => !record.timeOnly);

  bool get _canReview =>
      _selected.isNotEmpty &&
      (!_requiresOdometer || _odometer.text.trim().isNotEmpty) &&
      _detailsIssueText == null;

  bool get _canSave => _canReview;

  bool get _hasUnsavedLogWork {
    final defaultSingle =
        widget.records.length == 1 &&
        _selected.length == 1 &&
        _selected.contains(widget.records.first);
    final defaultMulti = widget.records.length != 1 && _selected.isEmpty;
    final untouchedSelection = defaultSingle || defaultMulti;
    return !untouchedSelection ||
        _step != (widget.records.length == 1 ? 1 : 0) ||
        _provider.text.trim().isNotEmpty ||
        _notes.text.trim().isNotEmpty;
  }

  String get _odometerHelperText => _requiresOdometer
      ? 'Enter the odometer from when this service was done.'
      : 'Odometer is optional for time-only items such as registration or inspection.';

  String? get _detailsIssueText {
    final today = DateTime.now();
    final serviceDay = DateTime(
      _serviceDate.year,
      _serviceDate.month,
      _serviceDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (serviceDay.isAfter(todayOnly)) {
      return 'Service date cannot be in the future.';
    }
    final odometerText = _odometer.text.trim();
    if (_requiresOdometer && odometerText.isEmpty) {
      return 'Enter the odometer from the day this service was done.';
    }
    if (odometerText.isNotEmpty) {
      final odometer = int.tryParse(odometerText);
      if (odometer == null || odometer < 0) {
        return 'Enter a valid odometer reading.';
      }
    }
    return null;
  }

  String? get _odometerAttentionText {
    final odometer = int.tryParse(_odometer.text.trim());
    if (odometer == null) return null;
    final knownOdometers = _selected
        .map((record) => record.lastServiceOdometer)
        .where((value) => value > 0);
    if (knownOdometers.isEmpty) return null;
    final highestKnown = knownOdometers.reduce((a, b) => a > b ? a : b);
    if (odometer >= highestKnown) return null;
    return 'This is below the last saved service odometer. That may be right for a back-dated record, but check it before saving.';
  }

  String get _odometerReviewLabel {
    final value = _odometer.text.trim();
    return value.isEmpty ? 'Not entered' : value;
  }

  String get _providerReviewLabel {
    final value = _provider.text.trim();
    return value.isEmpty ? 'Not entered' : value;
  }

  List<MaintenanceRecord> get _selectedList =>
      _selected.toList()..sort((a, b) => b.importance.compareTo(a.importance));

  MaintenanceRecord? get _activeManualItem {
    final items = _selectedList;
    if (items.isEmpty) return null;
    final index = _activeItemIndex.clamp(0, items.length - 1);
    return items[index];
  }

  void _changeActiveItem(int offset) {
    final items = _selectedList;
    if (items.isEmpty) return;
    _updateLogState(() {
      _activeItemIndex = (_activeItemIndex + offset).clamp(0, items.length - 1);
    });
  }

  MaintenanceRecord? get _oilFilterSuggestion {
    final hasEngineOil = _selected.any(
      (record) => record.itemName == 'Engine Oil',
    );
    final hasOilFilter = _selected.any(
      (record) => record.itemName == 'Oil Filter',
    );
    if (!hasEngineOil || hasOilFilter) return null;
    for (final record in widget.records) {
      if (record.itemName == 'Oil Filter') return record;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _toggle(MaintenanceRecord record) {
    setState(() {
      _selected.contains(record)
          ? _selected.remove(record)
          : _selected.add(record);
    });
    if (!_requiresOdometer && _odometerAutoSeeded) {
      _setOdometerProgrammatically('', autoSeeded: false);
      _seededOdometer = false;
    } else {
      _seedOdometerWhenRequired();
    }
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _serviceDate = picked);
  }

  Future<bool> _confirmDiscardLog() async {
    await _saveLogDraft();
    if (!mounted) return false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF182023),
        title: const Text('Leave service log?'),
        content: const Text('This service log has not been saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _saveLogDraft() {
    return MaintenanceDraftStore.saveLogDraft(
      vehicleName: _vehicleLabel,
      values: {
        'selectedItems': _selected.map((record) => record.itemName).toList(),
        'step': _step,
        'serviceDate': _serviceDate.toIso8601String(),
        'odometer': _odometer.text.trim(),
        'provider': _provider.text.trim(),
        'notes': _notes.text.trim(),
      },
    );
  }

  Future<void> _save() async {
    final odometerText = _odometer.text.trim();
    final odometer = odometerText.isEmpty
        ? (_requiresOdometer ? GlobalOdometerScope.of(context).reading : 0)
        : int.tryParse(odometerText);
    if (odometer == null || odometer < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid service odometer.')),
      );
      return;
    }
    final state = AppStateScope.of(context);
    try {
      await state.logMaintenanceServices([
        for (final record in _selected)
          MaintenanceServiceEvent(
            itemName: record.itemName,
            vehicleName: record.vehicleName,
            vehicleId: record.vehicleId,
            serviceDate: _serviceDate,
            odometer: odometer,
            provider: _provider.text.trim(),
            notes: _notes.text.trim(),
          ),
      ]);
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    await MaintenanceDraftStore.clearLogDraft(vehicleName: _vehicleLabel);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
