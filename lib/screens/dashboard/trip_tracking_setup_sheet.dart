import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';

part 'trip_tracking_setup_widgets.dart';

enum TripTrackingSetupAction { skip, start, openSettings }

class TripTrackingSetupResult {
  const TripTrackingSetupResult({required this.action, required this.settings});

  final TripTrackingSetupAction action;
  final TripTrackingSettings settings;
}

Future<TripTrackingSetupResult?> openTripTrackingSetupSheet(
  BuildContext context, {
  required TripTrackingSettings currentSettings,
}) {
  return showModalBottomSheet<TripTrackingSetupResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (context) =>
        _TripTrackingSetupSheet(currentSettings: currentSettings),
  );
}

enum _SetupStep { workType, locationChoice, trackingOptions }

enum _WorkType { delivery, rideshare, contractor, multiple, other }

class _TripTrackingSetupSheet extends StatefulWidget {
  const _TripTrackingSetupSheet({required this.currentSettings});

  final TripTrackingSettings currentSettings;

  @override
  State<_TripTrackingSetupSheet> createState() =>
      _TripTrackingSetupSheetState();
}

class _TripTrackingSetupSheetState extends State<_TripTrackingSetupSheet> {
  late var _step = widget.currentSettings.tripTrackingSetupCompleted
      ? _SetupStep.locationChoice
      : _SetupStep.workType;
  late _WorkType? _workType = widget.currentSettings.tripTrackingSetupCompleted
      ? _workTypeFor(widget.currentSettings.defaultProfile)
      : null;
  bool? _useLocation;
  late var _samplingPreset =
      !widget.currentSettings.tripTrackingSetupCompleted ||
          widget.currentSettings.samplingPreset ==
              TripTrackingSamplingPreset.highAccuracy
      ? TripTrackingSamplingPreset.highAccuracy
      : TripTrackingSamplingPreset.enhancedAccuracy;
  late var _batteryProtection =
      widget.currentSettings.lowBatteryGpsProtectionEnabled;
  late var _walkingReview =
      widget.currentSettings.walkingTransitionReviewEnabled;
  late var _background = widget.currentSettings.backgroundTrackingEnabled;

  @override
  Widget build(BuildContext context) {
    final isFirstSetup = !widget.currentSettings.tripTrackingSetupCompleted;
    final stepNumber = switch (_step) {
      _SetupStep.workType => 1,
      _SetupStep.locationChoice => isFirstSetup ? 2 : 1,
      _SetupStep.trackingOptions => isFirstSetup ? 3 : 2,
    };
    final stepCount = isFirstSetup ? 3 : 2;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Step $stepNumber of $stepCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFBFD0D7),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_step) {
                _SetupStep.workType => _workTypeStep(),
                _SetupStep.locationChoice => _locationChoiceStep(),
                _SetupStep.trackingOptions => _trackingOptionsStep(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _workTypeStep() {
    return _SetupPage(
      key: const ValueKey('work-type'),
      title: 'What Type of Work Do You Do?',
      body:
          'Choose the closest match. This changes how possible stops are '
          'suggested. You can change it later.',
      children: [
        _WorkTypeChoice(
          title: 'Delivery and gig work',
          body: 'Food, packages, shopping, and other pickup or delivery work.',
          value: _WorkType.delivery,
          selected: _workType == _WorkType.delivery,
          onChanged: _selectWorkType,
        ),
        _WorkTypeChoice(
          title: 'Rideshare and passenger work',
          body: 'Passenger trips where you may remain in the vehicle at stops.',
          value: _WorkType.rideshare,
          selected: _workType == _WorkType.rideshare,
          onChanged: _selectWorkType,
        ),
        _WorkTypeChoice(
          title: 'Contractor and service work',
          body: 'Jobsites, estimates, suppliers, and service calls.',
          value: _WorkType.contractor,
          selected: _workType == _WorkType.contractor,
          onChanged: _selectWorkType,
        ),
        _WorkTypeChoice(
          title: 'More than one work type',
          body: 'Use a general driving style and change it later when needed.',
          value: _WorkType.multiple,
          selected: _workType == _WorkType.multiple,
          onChanged: _selectWorkType,
        ),
        _WorkTypeChoice(
          title: 'Other business driving',
          body: 'Sales calls, site visits, mail routes, or similar work.',
          value: _WorkType.other,
          selected: _workType == _WorkType.other,
          onChanged: _selectWorkType,
        ),
        const SizedBox(height: 4),
        _FooterActions(
          primaryLabel: 'Continue',
          primaryEnabled: _workType != null,
          onPrimary: () => setState(() => _step = _SetupStep.locationChoice),
        ),
      ],
    );
  }

  Widget _locationChoiceStep() {
    return _SetupPage(
      key: const ValueKey('location-choice'),
      title: 'Would You Like Location Assistance?',
      body:
          'Your beginning and ending odometer readings stay official. '
          'Phone location can estimate miles and suggest stops for you to review.',
      children: [
        _BinaryChoice(
          icon: Icons.location_on_rounded,
          title: 'Use GPS assistance',
          body: 'Estimate distance and suggest possible stops while you work.',
          selected: _useLocation == true,
          onTap: () => setState(() => _useLocation = true),
        ),
        const SizedBox(height: 8),
        _BinaryChoice(
          icon: Icons.edit_road_rounded,
          title: 'Enter mileage myself',
          body:
              'Do not use phone location. Enter the odometer at the beginning '
              'and end of each workday.',
          selected: _useLocation == false,
          onTap: () => setState(() => _useLocation = false),
        ),
        const SizedBox(height: 8),
        _FooterActions(
          secondaryLabel: widget.currentSettings.tripTrackingSetupCompleted
              ? null
              : 'Back',
          onSecondary: widget.currentSettings.tripTrackingSetupCompleted
              ? null
              : () => setState(() => _step = _SetupStep.workType),
          primaryLabel: _useLocation == false
              ? 'Use Manual Mileage'
              : 'Continue',
          primaryEnabled: _useLocation != null,
          onPrimary: () {
            if (_useLocation == false) {
              Navigator.of(context).pop(
                TripTrackingSetupResult(
                  action: TripTrackingSetupAction.skip,
                  settings: _manualSettings(),
                ),
              );
              return;
            }
            setState(() => _step = _SetupStep.trackingOptions);
          },
        ),
      ],
    );
  }

  Widget _trackingOptionsStep() {
    return _SetupPage(
      key: const ValueKey('tracking-options'),
      title: 'Choose How Tracking Works',
      body:
          'Your phone will ask for precise location next. You can '
          'change these choices at any time.',
      children: [
        _SamplingChoice(
          title: 'Highest accuracy',
          body:
              'Checks about every 2 seconds while tracking. Uses more battery.',
          value: TripTrackingSamplingPreset.highAccuracy,
          selected: _samplingPreset == TripTrackingSamplingPreset.highAccuracy,
          onChanged: _selectSampling,
        ),
        _SamplingChoice(
          title: 'Better battery life',
          body:
              'Checks about every 8 seconds. Very short movement may be less exact.',
          value: TripTrackingSamplingPreset.enhancedAccuracy,
          selected:
              _samplingPreset == TripTrackingSamplingPreset.enhancedAccuracy,
          onChanged: _selectSampling,
        ),
        const SizedBox(height: 2),
        _SetupSwitch(
          title: 'Track with the screen locked',
          body:
              'Keeps recording during your workday when the phone screen is off.',
          value: _background,
          onChanged: (value) => setState(() => _background = value),
        ),
        const SizedBox(height: 8),
        _SetupSwitch(
          title: 'Suggest stops when I get out',
          body:
              'If driving stops and walking begins, mark a possible stop for review.',
          value: _walkingReview,
          onChanged: (value) => setState(() => _walkingReview = value),
        ),
        const SizedBox(height: 8),
        _SetupSwitch(
          title: 'Protect my battery',
          body:
              'Pause location at a critically low battery unless the phone is charging.',
          value: _batteryProtection,
          onChanged: (value) => setState(() => _batteryProtection = value),
        ),
        const SizedBox(height: 10),
        const _PermissionNotice(),
        const SizedBox(height: 8),
        _FooterActions(
          secondaryLabel: 'Back',
          onSecondary: () => setState(() => _step = _SetupStep.locationChoice),
          primaryLabel: 'Turn On Location',
          onPrimary: () => Navigator.of(context).pop(
            TripTrackingSetupResult(
              action: TripTrackingSetupAction.start,
              settings: _gpsSettings(),
            ),
          ),
        ),
      ],
    );
  }

  void _selectWorkType(_WorkType value) => setState(() => _workType = value);

  void _selectSampling(TripTrackingSamplingPreset value) {
    setState(() => _samplingPreset = value);
  }

  TripTrackingSettings _manualSettings() {
    return widget.currentSettings.copyWith(
      tripTrackingSetupCompleted: true,
      gpsAssistedTrackingEnabled: false,
      defaultProfile: _selectedProfile,
      backgroundTrackingEnabled: false,
      activityRecognitionEnabled: false,
      automaticStartAssistanceEnabled: false,
    );
  }

  TripTrackingSettings _gpsSettings() {
    return widget.currentSettings.copyWith(
      tripTrackingSetupCompleted: true,
      gpsAssistedTrackingEnabled: true,
      samplingPreset: _samplingPreset,
      defaultProfile: _selectedProfile,
      backgroundTrackingEnabled: _background,
      walkingTransitionReviewEnabled: _walkingReview,
      activityRecognitionEnabled: _walkingReview,
      lowBatteryGpsProtectionEnabled: _batteryProtection,
      lowBatteryGpsOverrideEnabled: false,
      lowBatteryGpsWarningDismissed: false,
    );
  }

  TripTrackingProfile get _selectedProfile => switch (_workType) {
    _WorkType.delivery => TripTrackingProfile.deliveryVehicle,
    _WorkType.rideshare => TripTrackingProfile.rideshareVehicle,
    _WorkType.contractor => TripTrackingProfile.contractorVehicle,
    _WorkType.multiple ||
    _WorkType.other ||
    null => TripTrackingProfile.roadVehicle,
  };
}

_WorkType _workTypeFor(TripTrackingProfile profile) => switch (profile) {
  TripTrackingProfile.deliveryVehicle => _WorkType.delivery,
  TripTrackingProfile.rideshareVehicle => _WorkType.rideshare,
  TripTrackingProfile.contractorVehicle => _WorkType.contractor,
  TripTrackingProfile.roadVehicle ||
  TripTrackingProfile.lowSpeedEquipment => _WorkType.other,
};
