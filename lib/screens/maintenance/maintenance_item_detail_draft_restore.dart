part of 'maintenance_item_detail_screen.dart';

extension _MaintenanceItemDetailDraftRestore
    on _MaintenanceItemDetailScreenState {
  Future<void> _restoreSetupDraft() async {
    final draft = await MaintenanceDraftStore.loadSetupDraft(
      vehicleName: widget.record.vehicleName,
      itemName: widget.record.itemName,
    );
    if (!mounted || draft == null) return;
    _applyRestoredSetupDraft(() {
      _dateEntryMode = _dateModeFrom(draft['dateEntryMode']);
      _odometerEntryMode = _odometerModeFrom(draft['odometerEntryMode']);
      _lastServiceDate =
          DateTime.tryParse(draft['lastServiceDate']?.toString() ?? '') ??
          _lastServiceDate;
      _lastServiceOdometer.text =
          draft['lastServiceOdometer']?.toString() ?? _lastServiceOdometer.text;
      _monthsSinceService.text =
          draft['monthsSinceService']?.toString() ?? _monthsSinceService.text;
      _milesSinceService.text =
          draft['milesSinceService']?.toString() ?? _milesSinceService.text;
      _mileInterval = _intFrom(draft['mileInterval'], _mileInterval);
      _monthInterval = _intFrom(draft['monthInterval'], _monthInterval);
      _customMiles.text = draft['customMiles']?.toString() ?? '';
      _customMonths.text = draft['customMonths']?.toString() ?? '';
      _detailA = draft['detailA']?.toString() ?? _detailA;
      _detailB = draft['detailB']?.toString() ?? _detailB;
      _advanced = draft['advanced'] == true;
      _thresholdsEnabled = draft['thresholdsEnabled'] is bool
          ? draft['thresholdsEnabled'] as bool
          : _thresholdsEnabled;
      _inAppNotifications = draft['inAppNotifications'] is bool
          ? draft['inAppNotifications'] as bool
          : _inAppNotifications;
      _pushNotifications = draft['pushNotifications'] is bool
          ? draft['pushNotifications'] as bool
          : _pushNotifications;
      _soundNotifications = draft['soundNotifications'] is bool
          ? draft['soundNotifications'] as bool
          : _soundNotifications;
      _pairOilFilter = draft['pairOilFilter'] is bool
          ? draft['pairOilFilter'] as bool
          : _pairOilFilter;
    });
  }

  _LastDateEntryMode _dateModeFrom(Object? value) {
    return value?.toString() == _LastDateEntryMode.elapsed.name
        ? _LastDateEntryMode.elapsed
        : _LastDateEntryMode.date;
  }

  _LastOdometerEntryMode _odometerModeFrom(Object? value) {
    return value?.toString() == _LastOdometerEntryMode.distance.name
        ? _LastOdometerEntryMode.distance
        : _LastOdometerEntryMode.reading;
  }

  int _intFrom(Object? value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
