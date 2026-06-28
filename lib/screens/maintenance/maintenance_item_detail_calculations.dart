part of 'maintenance_item_detail_screen.dart';

extension _MaintenanceItemDetailCalculations
    on _MaintenanceItemDetailScreenState {
  List<int> get _mileOptions {
    final options = [..._catalogItem.mileageIntervalOptions];
    if (_mileInterval > 0 && !options.contains(_mileInterval)) {
      options.add(_mileInterval);
    }
    options.sort();
    return options;
  }

  List<int> get _monthOptions {
    final options = [..._catalogItem.monthIntervalOptions];
    if (_monthInterval > 0 && !options.contains(_monthInterval)) {
      options.add(_monthInterval);
    }
    options.sort();
    return options;
  }

  String _intervalLabel(int miles) =>
      miles == 0 ? 'Time only' : '${_formatNumber(miles)} miles';

  String _monthLabel(int months) => months == 1 ? '1 month' : '$months months';

  bool get _usesLongTimeThresholds => _effectiveMonthInterval > 12;

  int get _timeYellowDefault => _usesLongTimeThresholds ? 42 : 30;

  int get _timeOrangeDefault => _usesLongTimeThresholds ? 28 : 20;

  int get _timeRedDefault => _usesLongTimeThresholds ? 14 : 10;

  bool get _canPreviewNextDue {
    if (_effectiveMonthInterval <= 0) return false;
    if (!_catalogItem.timeOnly && _effectiveMileInterval <= 0) return false;
    return true;
  }

  int get _effectiveMileInterval {
    final custom = int.tryParse(_customMiles.text.trim());
    return custom == null || custom <= 0 ? _mileInterval : custom;
  }

  int get _effectiveMonthInterval {
    final custom = int.tryParse(_customMonths.text.trim());
    return custom == null || custom <= 0 ? _monthInterval : custom;
  }

  Future<void> _pickLastServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastServiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _updateSetupState(() => _lastServiceDate = picked);
  }

  int _nextOdometer(AppStateController appState) {
    final exact = int.tryParse(_lastServiceOdometer.text.trim());
    final distance = int.tryParse(_milesSinceService.text.trim());
    if (_odometerEntryMode == _LastOdometerEntryMode.distance &&
        distance != null &&
        distance > 0) {
      return (appState.odometer - distance).clamp(0, 9999999) +
          _effectiveMileInterval;
    }
    return (exact == null || exact == 0 ? appState.odometer : exact) +
        _effectiveMileInterval;
  }

  Future<void> _save(
    AppStateController appState,
    MaintenanceRecord record,
  ) async {
    if (!_canPreviewNextDue) return;
    final enteredMonths = int.tryParse(_monthsSinceService.text.trim());
    final enteredMiles = int.tryParse(_milesSinceService.text.trim());
    final exactOdometer = int.tryParse(_lastServiceOdometer.text.trim());
    final effectiveLastDate =
        _dateEntryMode == _LastDateEntryMode.elapsed && enteredMonths != null
        ? _addMonths(DateTime.now(), -enteredMonths)
        : _lastServiceDate;
    final lastOdometer =
        _odometerEntryMode == _LastOdometerEntryMode.distance &&
            enteredMiles != null
        ? (appState.odometer - enteredMiles).clamp(0, 9999999)
        : exactOdometer ?? 0;
    final effectiveMiles = _effectiveMileInterval;
    final effectiveMonths = _effectiveMonthInterval;
    final milesSince = record.timeOnly
        ? record.milesSinceService
        : _odometerEntryMode == _LastOdometerEntryMode.distance &&
              enteredMiles != null
        ? enteredMiles.clamp(0, 9999999)
        : lastOdometer == 0
        ? record.milesSinceService
        : (appState.odometer - lastOdometer).clamp(0, 9999999);
    final monthsSince =
        _dateEntryMode == _LastDateEntryMode.elapsed && enteredMonths != null
        ? enteredMonths.clamp(0, 999)
        : _monthsBetween(effectiveLastDate, DateTime.now());
    appState.updateMaintenanceRecord(
      record.copyWith(
        intervalMiles: effectiveMiles,
        intervalMonths: effectiveMonths,
        milesSinceService: milesSince,
        monthsSinceService: monthsSince,
        lastServiceDate: effectiveLastDate,
        lastServiceOdometer: lastOdometer,
        detailA: _detailA,
        detailB: _detailB,
        setupComplete: true,
        lastServiceEstimated: _dateEntryMode == _LastDateEntryMode.elapsed
            ? true
            : _dateEstimated,
        lastOdometerEstimated:
            _odometerEntryMode == _LastOdometerEntryMode.distance
            ? true
            : _odometerEstimated,
        thresholdsEnabled: _thresholdsEnabled,
        mileageYellowAt: 900,
        mileageOrangeAt: 600,
        mileageRedAt: 300,
        timeYellowDays: _timeYellowDefault,
        timeOrangeDays: _timeOrangeDefault,
        timeRedDays: _timeRedDefault,
        inAppNotifications: _inAppNotifications,
        pushNotifications: _pushNotifications,
        soundNotifications: _soundNotifications,
        pairOilFilter: _pairOilFilter,
      ),
    );
    await MaintenanceDraftStore.clearSetupDraft(
      vehicleName: record.vehicleName,
      itemName: record.itemName,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _setCustomMiles() async {
    final value = await _showCustomNumberDialog(
      context: context,
      title: 'Custom Mileage Interval',
      label: 'Miles until next service',
      initialValue: _effectiveMileInterval,
    );
    if (value == null) return;
    _updateSetupState(() {
      _customMiles.text = value.toString();
      _mileInterval = value;
    });
  }

  Future<void> _setCustomMonths() async {
    final value = await _showCustomNumberDialog(
      context: context,
      title: 'Custom Time Interval',
      label: 'Months until next service',
      initialValue: _effectiveMonthInterval,
    );
    if (value == null) return;
    _updateSetupState(() {
      _customMonths.text = value.toString();
      _monthInterval = value;
    });
  }
}
