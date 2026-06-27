part of 'maintenance_item_detail_screen.dart';

extension _MaintenanceItemDetailLeaveGuard
    on _MaintenanceItemDetailScreenState {
  bool _hasUnsavedSetupWork(MaintenanceRecord record) {
    if (_dateEntryMode != _LastDateEntryMode.date) return true;
    if (_odometerEntryMode != _LastOdometerEntryMode.reading) return true;
    if (_monthsSinceService.text.trim().isNotEmpty) return true;
    if (_milesSinceService.text.trim().isNotEmpty) return true;
    if (_customMiles.text.trim().isNotEmpty) return true;
    if (_customMonths.text.trim().isNotEmpty) return true;
    if (_lastServiceDate != (record.lastServiceDate ?? _lastServiceDate)) {
      return true;
    }
    if (_lastServiceOdometer.text.trim() !=
        (record.lastServiceOdometer == 0
            ? ''
            : record.lastServiceOdometer.toString())) {
      return true;
    }
    return _mileInterval != (record.setupComplete ? record.intervalMiles : 0) ||
        _monthInterval != (record.setupComplete ? record.intervalMonths : 0) ||
        _detailA != record.detailA ||
        _detailB != record.detailB ||
        _advanced ||
        _thresholdsEnabled != record.thresholdsEnabled ||
        _inAppNotifications != record.inAppNotifications ||
        _pushNotifications != record.pushNotifications ||
        _soundNotifications != record.soundNotifications ||
        _pairOilFilter != record.pairOilFilter;
  }

  Future<bool> _confirmDiscardSetup() async {
    await _saveSetupDraft();
    if (!mounted) return false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF182023),
        title: const Text('Leave setup?'),
        content: const Text(
          'This maintenance setup has changes that are not saved yet.',
        ),
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

  Future<void> _saveSetupDraft() {
    return MaintenanceDraftStore.saveSetupDraft(
      vehicleName: widget.record.vehicleName,
      itemName: widget.record.itemName,
      values: {
        'dateEntryMode': _dateEntryMode.name,
        'odometerEntryMode': _odometerEntryMode.name,
        'lastServiceDate': _lastServiceDate.toIso8601String(),
        'lastServiceOdometer': _lastServiceOdometer.text.trim(),
        'monthsSinceService': _monthsSinceService.text.trim(),
        'milesSinceService': _milesSinceService.text.trim(),
        'mileInterval': _mileInterval,
        'monthInterval': _monthInterval,
        'customMiles': _customMiles.text.trim(),
        'customMonths': _customMonths.text.trim(),
        'detailA': _detailA,
        'detailB': _detailB,
        'advanced': _advanced,
        'thresholdsEnabled': _thresholdsEnabled,
        'inAppNotifications': _inAppNotifications,
        'pushNotifications': _pushNotifications,
        'soundNotifications': _soundNotifications,
        'pairOilFilter': _pairOilFilter,
      },
    );
  }
}
