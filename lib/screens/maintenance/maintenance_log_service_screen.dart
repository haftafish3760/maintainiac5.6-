import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart'
    show AppSection, GlobalOdometerHeader;
import '../../shared/widgets/record_text_field.dart';
import '../../shared/widgets/receipt_capture/receipt_attachment_panel.dart';
import '../../shared/widgets/receipt_capture/receipt_capture_models.dart';
import '../../shared/widgets/receipt_capture/receipt_capture_settings_store.dart';
import '../../shared/widgets/structural_border_label.dart';
import 'maintenance_draft_store.dart';
import 'maintenance_form_surface.dart';
import 'maintenance_svg_icon.dart';

part 'maintenance_log_service_widgets.dart';

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
  var _serviceDate = DateTime.now();
  final _odometer = TextEditingController();
  final _provider = TextEditingController();
  final _totalCost = TextEditingController();
  final _notes = TextEditingController();
  var _hasReceipt = false;
  var _receiptAttachments = <ReceiptAttachmentRecord>[];
  var _seededOdometer = false;

  @override
  void initState() {
    super.initState();
    _odometer.addListener(_refreshFormState);
    _totalCost.addListener(_refreshFormState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededOdometer) return;
    _odometer.text = AppStateScope.of(context).odometer.toString();
    _seededOdometer = true;
  }

  @override
  void dispose() {
    _odometer.removeListener(_refreshFormState);
    _totalCost.removeListener(_refreshFormState);
    _odometer.dispose();
    _provider.dispose();
    _totalCost.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _refreshFormState() {
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
                _LogFlowProgress(step: _step),
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

  Widget _buildItemStep() {
    return _LogSection(
      title: 'What Was Serviced?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InlineNotice(
            text:
                'Select every item handled during this visit. One service event can update several maintenance records.',
          ),
          const SizedBox(height: 10),
          for (final record in widget.records) ...[
            _ServiceChoice(
              record: record,
              selected: _selected.contains(record),
              onTap: () => _toggle(record),
            ),
            const SizedBox(height: 8),
          ],
          if (_oilFilterSuggestion != null) ...[
            const SizedBox(height: 2),
            _CompanionServicePrompt(
              label: 'Oil filter usually goes with engine oil.',
              actionLabel: 'Add Oil Filter',
              onPressed: () => _toggle(_oilFilterSuggestion!),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Continue',
              tone: AppButtonTone.commit,
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(() => _step = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LogSection(
          title: 'Service Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SelectedServiceSummary(
                records: _selected.toList(),
                onChangeItems: widget.records.length == 1
                    ? null
                    : () => setState(() => _step = 0),
              ),
              const SizedBox(height: 12),
              _ResponsiveLogPair(
                left: _DateButton(
                  label: 'Service Date',
                  date: _serviceDate,
                  onTap: _pickServiceDate,
                ),
                right: RecordTextField(
                  label: 'Service Odometer',
                  controller: _odometer,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 8),
              _InlineNotice(text: _odometerHelperText),
              const SizedBox(height: 12),
              _ResponsiveLogPair(
                left: RecordTextField(
                  label: 'Shop / Provider',
                  controller: _provider,
                ),
                right: RecordTextField(
                  label: 'Total Cost',
                  controller: _totalCost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RecordTextField(
                label: 'Service Notes',
                controller: _notes,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SharedReceiptAttachmentPanel(
          hasReceipt: _hasReceipt,
          area: ReceiptCaptureArea.maintenanceRepair,
          onChanged: (value) => setState(() => _hasReceipt = value),
          onAttachmentsChanged: (attachments) =>
              setState(() => _receiptAttachments = attachments),
          onImportedText: (_) async {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Receipt proof attached. Maintenance parsing comes later.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (widget.records.length > 1)
              AppButton(
                label: 'Back',
                tone: AppButtonTone.general,
                onPressed: () => setState(() => _step = 0),
              ),
            const Spacer(),
            AppButton(
              label: 'Review',
              tone: AppButtonTone.commit,
              onPressed: _canReview ? () => setState(() => _step = 2) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return _LogSection(
      title: 'Review Service',
      child: Column(
        children: [
          _ReviewLine(
            label: 'Items serviced',
            value: _selected.map((item) => item.itemName).join(', '),
          ),
          _ReviewLine(label: 'Vehicle', value: _vehicleLabel),
          _ReviewLine(label: 'Service date', value: _formatDate(_serviceDate)),
          _ReviewLine(label: 'Odometer', value: _odometerReviewLabel),
          _ReviewLine(label: 'Provider', value: _providerReviewLabel),
          _ReviewLine(label: 'Cost', value: _costReviewLabel),
          _ReviewLine(
            label: 'Receipt proof',
            value: _receiptAttachments.isEmpty
                ? 'Not attached'
                : '${_receiptAttachments.length} attached',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppButton(
                label: 'Back',
                tone: AppButtonTone.general,
                onPressed: () => setState(() => _step = 1),
              ),
              const Spacer(),
              AppButton(
                label: 'Save Service',
                tone: AppButtonTone.commit,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ],
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
      (!_requiresOdometer || _odometer.text.trim().isNotEmpty);

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
        _totalCost.text.trim().isNotEmpty ||
        _notes.text.trim().isNotEmpty ||
        _receiptAttachments.isNotEmpty ||
        _hasReceipt;
  }

  String get _odometerHelperText => _requiresOdometer
      ? 'Enter the odometer from when this service was done.'
      : 'Odometer is optional for time-only items such as registration or inspection.';

  String get _odometerReviewLabel {
    final value = _odometer.text.trim();
    return value.isEmpty ? 'Not entered' : value;
  }

  String get _providerReviewLabel {
    final value = _provider.text.trim();
    return value.isEmpty ? 'Not entered' : value;
  }

  String get _costReviewLabel {
    final value = _totalCost.text.trim();
    return value.isEmpty ? 'Not entered' : '\$$value';
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
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035, 12, 31),
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
        'totalCost': _totalCost.text.trim(),
        'notes': _notes.text.trim(),
        'hasReceipt': _hasReceipt,
        'receiptProofCount': _receiptAttachments.length,
      },
    );
  }

  void _save() {
    final odometerText = _odometer.text.trim();
    final odometer = odometerText.isEmpty
        ? AppStateScope.of(context).odometer
        : int.tryParse(odometerText);
    if (odometer == null || odometer < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid service odometer.')),
      );
      return;
    }
    final costText = _totalCost.text.trim().replaceAll(',', '');
    final totalCost = costText.isEmpty ? 0.0 : double.tryParse(costText);
    if (totalCost == null || totalCost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid service cost.')),
      );
      return;
    }
    final state = AppStateScope.of(context);
    for (final record in _selected) {
      state.logMaintenanceService(
        MaintenanceServiceEvent(
          itemName: record.itemName,
          vehicleName: record.vehicleName,
          serviceDate: _serviceDate,
          odometer: odometer,
          provider: _provider.text.trim(),
          totalCost: totalCost,
          receiptProofCount: _receiptAttachments.length,
          notes: _notes.text.trim(),
        ),
      );
    }
    MaintenanceDraftStore.clearLogDraft(vehicleName: _vehicleLabel);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
