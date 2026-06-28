part of 'maintenance_log_service_screen.dart';

extension _MaintenanceLogServiceDraftRestore
    on _MaintenanceLogServiceScreenState {
  Future<void> _restoreLogDraft() async {
    final vehicleName = widget.records.isNotEmpty
        ? widget.records.first.vehicleName
        : 'Active vehicle';
    final draft = await MaintenanceDraftStore.loadLogDraft(
      vehicleName: vehicleName,
    );
    if (!mounted || draft == null) return;
    _applyRestoredLogDraft(() {
      final selectedNames = (draft['selectedItems'] as List?)
          ?.map((item) => item.toString())
          .toSet();
      if (selectedNames != null && selectedNames.isNotEmpty) {
        _selected
          ..clear()
          ..addAll(
            widget.records.where(
              (record) => selectedNames.contains(record.itemName),
            ),
          );
      }
      _step = _intFrom(draft['step'], _step).clamp(0, 2);
      _serviceDate =
          DateTime.tryParse(draft['serviceDate']?.toString() ?? '') ??
          _serviceDate;
      final odometer = draft['odometer']?.toString() ?? '';
      if (odometer.isNotEmpty) {
        _odometer.text = odometer;
        _seededOdometer = true;
      }
      _provider.text = draft['provider']?.toString() ?? _provider.text;
      _notes.text = draft['notes']?.toString() ?? _notes.text;
    });
  }

  int _intFrom(Object? value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
