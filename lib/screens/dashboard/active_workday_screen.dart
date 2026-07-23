import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/device_capabilities/device_capability_scope.dart';
import '../../shared/context/operational_context_store.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/trip_tracking/trip_tracking_capability_guidance.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_dashboard_live_status_policy.dart';
import '../../shared/trip_tracking/trip_tracking_dashboard_guidance.dart';
import '../../shared/trip_tracking/trip_tracking_field_trial_summary.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_session_store.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/flow_placeholder_screen.dart';
import '../expenses/entry/expense_receipt_entry_screen.dart';
import '../expenses/profiles/expense_work_profile_screen.dart';
import '../settings/trip_tracking_settings_screen.dart';
import 'active_workday_actions.dart';
import 'active_workday_quick_action_editor.dart';
import 'data/active_workday_store.dart';
import 'vehicle_profile_flow.dart';
import 'vehicle_profile_widgets.dart';

part 'active_workday_context_bar.dart';
part 'active_workday_session_widgets.dart';
part 'active_workday_navigation_helpers.dart';

class ActiveWorkdayScreen extends StatefulWidget {
  const ActiveWorkdayScreen({
    super.key,
    required this.activeVehicle,
    required this.workProfileName,
  });

  final VehicleProfilePreview activeVehicle;
  final String workProfileName;

  @override
  State<ActiveWorkdayScreen> createState() => _ActiveWorkdayScreenState();
}

class _ActiveWorkdayScreenState extends State<ActiveWorkdayScreen> {
  late final DateTime _startedAt;
  final Random _tripIdRandom = Random.secure();
  Timer? _timer;
  var _elapsed = Duration.zero;
  late var _activeVehicle = widget.activeVehicle;
  var _gpsStartInFlight = false;
  var _gpsStopInFlight = false;
  var _gpsCancelInFlight = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkday = ActiveWorkdayScope.of(context);
    final session = activeWorkday.activeSession;
    final actionLayout =
        WorkdayQuickActionLayoutScope.maybeOf(context)?.layout ??
        WorkdayQuickActionLayout.defaults();
    final quickActions = _quickActionsFor(session, actionLayout);
    final odometer = GlobalOdometerScope.of(context);
    final elapsed = session == null
        ? _elapsed
        : session.elapsedWorkTimeAt(DateTime.now());

    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _WorkdayContextBar(
                  activeVehicle: _activeVehicle,
                  workProfileName: widget.workProfileName,
                  onVehicleChanged: _handleVehicleChanged,
                  onOpenWorkProfiles: _openWorkProfiles,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Shift Timer',
                        value: _formatElapsed(elapsed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: odometer,
                        builder: (context, _) => _MetricTile(
                          label: 'Miles Today',
                          value:
                              session
                                  ?.milesSoFar(odometer.reading)
                                  .toString() ??
                              '0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _GpsTripPanel(
                  onStart: _startGpsTrip,
                  onStop: _stopGpsTrip,
                  onCancel: _cancelGpsTrip,
                  onReviewLatest: _reviewLatestGpsTrip,
                  onReviewWalkingStop: _reviewWalkingStop,
                  onViewFieldSummary: _showLatestGpsFieldSummary,
                  onOpenSettings: () => Navigator.of(context).push(
                    appNativeRoute<void>(
                      context,
                      const TripTrackingSettingsScreen(),
                    ),
                  ),
                  startInFlight: _gpsStartInFlight,
                  stopInFlight: _gpsStopInFlight,
                  cancelInFlight: _gpsCancelInFlight,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: _SectionLabel('QUICK ACTIONS')),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        appNativeRoute<void>(
                          context,
                          const ActiveWorkdayQuickActionEditor(),
                        ),
                      ),
                      tooltip: 'Edit quick actions',
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFFE2E8EA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quickActions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 72,
                  ),
                  itemBuilder: (context, index) {
                    return _QuickActionButton(
                      action: quickActions[index],
                      onTap: () => _handleQuickAction(quickActions[index]),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SessionActivityList(events: session?.events ?? const []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  List<WorkdayQuickActionSpec> _quickActionsFor(
    ActiveWorkdaySessionRecord? session,
    WorkdayQuickActionLayout actionLayout,
  ) {
    if (session?.status != ActiveWorkdayStatus.paused) {
      return actionLayout.activeActions;
    }

    return [
      const WorkdayQuickActionSpec(
        kind: WorkdayQuickActionKind.resumeDay,
        icon: Icons.play_arrow_rounded,
        emoji: '▶️',
        label: 'Resume Day',
        color: Color(0xFF2AA875),
        flowTitle: 'Resume Workday',
        flowSummary: 'Resume the current workday without creating a new day.',
      ),
      ...actionLayout.activeActions.where(
        (action) => action.kind != WorkdayQuickActionKind.pauseDay,
      ),
    ];
  }

  Future<void> _handleVehicleChanged(VehicleProfilePreview vehicle) async {
    final appState = AppStateScope.of(context);
    final odometer = GlobalOdometerScope.of(context);
    final operationalContext = OperationalContextScope.maybeOf(context);
    final targetOdometerVehicleId = odometerVehicleIdForVehicleId(
      vehicle.id,
      fallbackLabel: vehicle.nickname,
    );
    final workday = ActiveWorkdayScope.of(context).activeSession;
    if (workday != null && workday.vehicleId != targetOdometerVehicleId) {
      await _restoreAppStateVehicle(appState, _activeVehicle.id);
      if (!mounted) return;
      _showGpsMessage(
        'End the current workday before switching vehicles. Its odometer and trip history remain preserved.',
      );
      return;
    }
    if (odometer.vehicleId != targetOdometerVehicleId) {
      final switched = await odometer.switchVehicleById(
        targetOdometerVehicleId,
      );
      if (!mounted) return;
      if (!switched) {
        await _restoreAppStateVehicle(appState, _activeVehicle.id);
        if (!mounted) return;
        _showGpsMessage(
          'End or review the active GPS trip before switching vehicles.',
        );
        return;
      }
    }
    VehicleProfile? selectedVehicle;
    for (final candidate in appState.vehicles) {
      if (candidate.id == vehicle.id) {
        selectedVehicle = candidate;
        break;
      }
    }
    if (selectedVehicle == null) {
      await _restoreAppStateVehicle(appState, _activeVehicle.id);
      if (!mounted) return;
      _showGpsMessage('The selected vehicle is no longer available.');
      return;
    }
    await appState.selectVehicle(selectedVehicle);
    if (operationalContext != null) {
      await operationalContext.setActiveVehicle(
        vehicleId: odometer.vehicleId,
        vehicleLabel: selectedVehicle.nickname,
        usage: selectedVehicle.usage,
      );
    }
    if (!mounted) return;
    setState(() => _activeVehicle = vehicle);
  }

  Future<void> _openWorkProfiles() async {
    final workday = ActiveWorkdayScope.of(context).activeSession;
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (workday != null || tripTracking?.isTracking == true) {
      _showGpsMessage(
        'End the current workday before switching work profiles. Its trip, odometer, and profile history remain preserved.',
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(appNativeRoute<void>(context, const ExpenseWorkProfileScreen()));
  }

  Future<void> _restoreAppStateVehicle(
    AppStateController appState,
    String vehicleId,
  ) async {
    for (final candidate in appState.vehicles) {
      if (candidate.id == vehicleId) {
        await appState.selectVehicle(candidate);
        return;
      }
    }
  }

  Future<void> _handleQuickAction(WorkdayQuickActionSpec action) async {
    switch (action.kind) {
      case WorkdayQuickActionKind.pauseDay:
        final paused = await _recordOdometerEvent(
          title: 'Pause Odometer',
          saveLabel: 'Pause Day',
          type: ActiveWorkdayEventType.paused,
        );
        if (paused) {
          if (!mounted) return;
          await TripTrackingScope.maybeOf(context)?.stopNativeTracking();
        }
        return;
      case WorkdayQuickActionKind.resumeDay:
        await _recordStoredEvent(ActiveWorkdayEventType.resumed);
        if (!mounted) return;
        await _startGpsTrip();
        return;
      case WorkdayQuickActionKind.endDay:
        final tripTracking = TripTrackingScope.maybeOf(context);
        int? confirmedTripEndingOdometer;
        if (tripTracking?.isTracking == true) {
          confirmedTripEndingOdometer = await _finishAndReviewGpsTrip(
            tripTracking!,
            missingTripMessage: 'GPS trip could not be reviewed before ending.',
          );
          if (!mounted) return;
          if (tripTracking.isTracking) return;
        }
        if (confirmedTripEndingOdometer != null) {
          final ended = await ActiveWorkdayScope.of(context).addEvent(
            type: ActiveWorkdayEventType.ended,
            odometerReading: confirmedTripEndingOdometer,
          );
          if (ended != null && mounted) Navigator.of(context).pop();
          return;
        }
        final saved = await _recordOdometerEvent(
          title: 'Ending Odometer',
          saveLabel: 'End Day',
          type: ActiveWorkdayEventType.ended,
        );
        if (saved && mounted) Navigator.of(context).pop();
      case WorkdayQuickActionKind.addFuel:
        await Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            const ExpenseReceiptEntryScreen(initialCategory: 'Fuel'),
          ),
        );
        await _recordStoredEvent(ActiveWorkdayEventType.fuel);
      case WorkdayQuickActionKind.expense:
        await Navigator.of(context).push(
          appNativeRoute<void>(context, const ExpenseReceiptEntryScreen()),
        );
        await _recordStoredEvent(ActiveWorkdayEventType.expense);
      case WorkdayQuickActionKind.addStop:
        await _openStopDialog('Stop', ActiveWorkdayEventType.stop);
      case WorkdayQuickActionKind.addPickup:
        await _openStopDialog('Pickup', ActiveWorkdayEventType.pickup);
      case WorkdayQuickActionKind.addDropOff:
        await _openStopDialog('Drop-off', ActiveWorkdayEventType.dropOff);
      case WorkdayQuickActionKind.payment:
      case WorkdayQuickActionKind.invoice:
      case WorkdayQuickActionKind.maintenance:
      case WorkdayQuickActionKind.materials:
      case WorkdayQuickActionKind.receipt:
      case WorkdayQuickActionKind.reminder:
      case WorkdayQuickActionKind.estimate:
      case WorkdayQuickActionKind.note:
        _openFlow(
          context,
          title: action.flowTitle,
          icon: action.icon,
          summary: action.flowSummary,
          requiresOdometer: action.requiresOdometer,
        );
    }
  }

  Future<bool> _recordOdometerEvent({
    required String title,
    required String saveLabel,
    required ActiveWorkdayEventType type,
  }) async {
    final saved = await openOdometerEntry(
      context,
      title: title,
      saveLabel: saveLabel,
    );
    if (!mounted) return false;
    if (saved) {
      await ActiveWorkdayScope.of(context).addEvent(
        type: type,
        odometerReading: GlobalOdometerScope.of(context).reading,
      );
    }
    return saved;
  }

  Future<void> _recordStoredEvent(
    ActiveWorkdayEventType type, {
    String? note,
    bool confirmGpsStopCandidate = false,
  }) async {
    if (!mounted) return;
    final activeWorkday = ActiveWorkdayScope.of(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    final updatedWorkday = await activeWorkday.addEvent(
      type: type,
      odometerReading: GlobalOdometerScope.of(context).reading,
      note: note,
    );
    if (type == ActiveWorkdayEventType.stop ||
        type == ActiveWorkdayEventType.pickup ||
        type == ActiveWorkdayEventType.dropOff) {
      final tripEventType = switch (type) {
        ActiveWorkdayEventType.stop => TripManualEventType.stop,
        ActiveWorkdayEventType.pickup => TripManualEventType.pickup,
        ActiveWorkdayEventType.dropOff => TripManualEventType.dropoff,
        _ => null,
      };
      final newWorkdayEvent =
          updatedWorkday == null || updatedWorkday.events.isEmpty
          ? null
          : updatedWorkday.events.last;
      if (tripTracking?.isTracking == true &&
          tripEventType != null &&
          newWorkdayEvent != null) {
        final recorded = await tripTracking!.recordUserTripEvent(
          commandId: 'workday.${newWorkdayEvent.id}',
          type: tripEventType,
          initiatingSource: 'dashboard',
          occurredAt: newWorkdayEvent.occurredAt,
          note: note,
        );
        if (!recorded) {
          if (!mounted) return;
          _showGpsMessage(
            'The stop was saved to your day, but could not be attached to the active GPS trip. The stop review remains available for retry.',
          );
          return;
        }
      }
      if (confirmGpsStopCandidate) {
        await tripTracking?.acknowledgeWalkingReview();
      }
    }
  }

  Future<void> _openStopDialog(
    String kind,
    ActiveWorkdayEventType type, {
    bool confirmGpsStopCandidate = false,
  }) async {
    var note = '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: Text(
          'Add $kind',
          style: const TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time: ${_timeLabel(DateTime.now())}',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const _LiveOdometerDialogLine(),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => note = value,
              decoration: const InputDecoration(
                labelText: 'Stop note',
                hintText: 'Customer, store, pickup, delivery, or break',
                filled: true,
                fillColor: Color(0xFFAAB4B9),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Stop'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      await _recordStoredEvent(
        type,
        note: note.trim(),
        confirmGpsStopCandidate: confirmGpsStopCandidate,
      );
    }
  }

  Future<void> _reviewWalkingStop() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking?.needsWalkingReview != true) return;
    final candidate = tripTracking?.latestPendingStopBoundaryCandidate;
    final candidateTime = candidate == null
        ? null
        : _timeLabel(candidate.proposedBoundaryAt.toLocal());
    final confidenceText = switch (candidate?.confidence) {
      TripTrackingConfidence.high => 'High-confidence motion evidence.',
      TripTrackingConfidence.medium => 'Moderate-confidence motion evidence.',
      TripTrackingConfidence.low => 'Low-confidence motion evidence.',
      TripTrackingConfidence.unknown ||
      null => 'Motion confidence is unavailable.',
    };
    final remaining = tripTracking?.pendingStopReviewCount ?? 0;
    final shouldAddStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: Text(
          candidateTime == null
              ? 'Possible Stop Detected'
              : 'Possible Stop at $candidateTime',
          style: const TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Driving followed by verified walking suggests that you stopped. '
          'Add it to your day, or dismiss it if you did not stop. This will '
          'not end GPS tracking or change your mileage.'
          ' $confidenceText'
          '${remaining > 1 ? ' $remaining possible stops remain for review.' : ''}',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not a Stop'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Stop'),
          ),
        ],
      ),
    );
    if (!mounted || shouldAddStop == null) return;
    if (shouldAddStop) {
      await _openStopDialog(
        'Stop',
        ActiveWorkdayEventType.stop,
        confirmGpsStopCandidate: true,
      );
      return;
    }
    await tripTracking!.reviewLatestStopAdvisory(
      TripTrackingAdvisoryDisposition.dismissed,
    );
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Future<void> _startGpsTrip() async {
    if (_gpsStartInFlight) return;
    setState(() => _gpsStartInFlight = true);
    try {
      await _startGpsTripImpl();
    } finally {
      if (mounted) {
        setState(() => _gpsStartInFlight = false);
      } else {
        _gpsStartInFlight = false;
      }
    }
  }

  Future<void> _startGpsTripImpl() async {
    final settingsController = TripTrackingSettingsScope.maybeOf(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (settingsController == null || tripTracking == null) return;
    final activeSession = ActiveWorkdayScope.of(context).activeSession;
    if (activeSession == null) {
      _showGpsMessage('Start Day before starting GPS-assisted tracking.');
      return;
    }
    if (activeSession.isPaused) {
      _showGpsMessage('Resume Day before restarting GPS-assisted tracking.');
      return;
    }
    final odometer = GlobalOdometerScope.of(context);
    if (activeSession.vehicleId != odometer.vehicleId) {
      _showGpsMessage(
        'Switch to the active workday vehicle before starting GPS-assisted tracking.',
      );
      return;
    }
    final settings = settingsController.settings;
    if (!settings.gpsAssistedTrackingEnabled) {
      _showGpsMessage(
        'Enable GPS-assisted tracking in Dashboard Settings first.',
      );
      return;
    }
    // GPS is heavy work. Refresh the shared runtime profile only after the
    // driver has actually opted in, so a disabled setting never wakes the
    // capability probe. This refresh informs dashboard guidance; it neither
    // grants permission nor silently changes the selected sampling preset.
    await DeviceCapabilityScope.refreshForHeavyWork(context);
    if (!mounted) return;
    var startedNewTrip = false;
    if (!tripTracking.isTracking) {
      startedNewTrip = await tripTracking.start(
        tripId:
            'gps-trip-${DateTime.now().microsecondsSinceEpoch}-${_tripIdRandom.nextInt(0x100000000).toRadixString(16)}',
        vehicleId: odometer.vehicleId,
        profile: settings.defaultProfile,
        profileId: activeSession.workProfileId,
      );
      if (!startedNewTrip) {
        _showGpsMessage(
          tripTracking.platformError ?? 'A GPS trip could not be created.',
        );
        return;
      }
    }
    final started = await tripTracking.startNativeTracking(
      allowBackground: settings.backgroundTrackingEnabled,
      samplingPreset: settings.samplingPreset,
      customIntervalSeconds: settings.customIntervalSeconds,
      adaptiveSamplingEnabled: settings.adaptiveSamplingEnabled,
      activityRecognitionEnabled: settings.activityRecognitionEnabled,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );
    if (!started && _gpsBatteryChoiceRequired(tripTracking.platformStatus)) {
      final choice = await _openLowBatteryGpsDialog(
        lowPowerMode:
            tripTracking.platformStatus?.startsWith('low_power_mode') == true,
      );
      if (!mounted) return;
      if (choice != null) {
        if (choice.rememberChoice) {
          await settingsController.update(
            settings.copyWith(
              lowBatteryGpsOverrideEnabled: choice.continueGps,
              lowBatteryGpsWarningDismissed: true,
            ),
          );
        }
        if (choice.continueGps) {
          final retryStarted = await tripTracking.startNativeTracking(
            allowBackground: settings.backgroundTrackingEnabled,
            samplingPreset: settings.samplingPreset,
            customIntervalSeconds: settings.customIntervalSeconds,
            adaptiveSamplingEnabled: settings.adaptiveSamplingEnabled,
            activityRecognitionEnabled: settings.activityRecognitionEnabled,
            lowBatteryProtectionEnabled:
                settings.lowBatteryGpsProtectionEnabled,
            lowBatteryOverrideEnabled: true,
            lowBatteryWarningDismissed: choice.rememberChoice,
          );
          if (!retryStarted && startedNewTrip) {
            await tripTracking.discardEmptyTrip();
          }
          if (!mounted) return;
          _showGpsMessage(
            retryStarted
                ? 'GPS-assisted trip tracking started.'
                : (tripTracking.platformError ??
                      'GPS tracking could not start.'),
          );
          return;
        }
      }
    }
    if (!started && startedNewTrip) await tripTracking.discardEmptyTrip();
    if (!mounted) return;
    _showGpsMessage(
      started
          ? 'GPS-assisted trip tracking started.'
          : (tripTracking.platformError ?? 'GPS tracking could not start.'),
    );
  }

  bool _gpsBatteryChoiceRequired(String? status) {
    return status == 'low_battery_requires_user_choice' ||
        status == 'low_power_mode_requires_user_choice';
  }

  Future<_LowBatteryGpsChoice?> _openLowBatteryGpsDialog({
    required bool lowPowerMode,
  }) {
    var rememberChoice = false;
    return showDialog<_LowBatteryGpsChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF101719),
          title: Text(
            lowPowerMode ? 'Battery saver is active' : 'Battery below 20%',
            style: const TextStyle(
              color: Color(0xFFF0F4F2),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GPS can use more battery while you drive. By default, Maintainiac pauses before starting GPS when battery safety protection is active so your phone keeps enough power.',
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: rememberChoice,
                onChanged: (value) =>
                    setDialogState(() => rememberChoice = value == true),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Do not show again',
                  style: TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'You can reverse this later in Dashboard GPS settings.',
                style: TextStyle(
                  color: Color(0xFF9FB0B6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                _LowBatteryGpsChoice(
                  continueGps: false,
                  rememberChoice: rememberChoice,
                ),
              ),
              child: const Text('Cancel GPS'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _LowBatteryGpsChoice(
                  continueGps: true,
                  rememberChoice: rememberChoice,
                ),
              ),
              child: const Text('Continue with GPS'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stopGpsTrip() async {
    if (_gpsStopInFlight) return;
    setState(() => _gpsStopInFlight = true);
    try {
      await _stopGpsTripImpl();
    } finally {
      if (mounted) {
        setState(() => _gpsStopInFlight = false);
      } else {
        _gpsStopInFlight = false;
      }
    }
  }

  Future<void> _cancelGpsTrip() async {
    if (_gpsCancelInFlight || _gpsStopInFlight || _gpsStartInFlight) return;
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking == null || !tripTracking.isTracking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'Cancel GPS Trip?',
          style: TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'GPS collection will stop. Existing locations, distance evidence, '
          'stops, and diagnostics will be preserved as a cancelled trip for '
          'review. Your workday and odometer will not be changed.',
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Tracking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8D2D2D),
            ),
            child: const Text('Cancel GPS Trip'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _gpsCancelInFlight = true);
    try {
      final review = await tripTracking.cancelActiveTrip(userConfirmed: true);
      if (!mounted) return;
      _showGpsMessage(
        review == null
            ? (tripTracking.platformError ??
                  'The GPS trip could not be cancelled safely.')
            : 'GPS trip cancelled and preserved for review. Your workday remains active.',
      );
    } finally {
      if (mounted) {
        setState(() => _gpsCancelInFlight = false);
      } else {
        _gpsCancelInFlight = false;
      }
    }
  }

  Future<void> _stopGpsTripImpl() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking == null || !tripTracking.isTracking) return;
    await _finishAndReviewGpsTrip(
      tripTracking,
      missingTripMessage: 'No active GPS trip to stop.',
    );
  }

  Future<int?> _finishAndReviewGpsTrip(
    TripTrackingController tripTracking, {
    required String missingTripMessage,
  }) async {
    final review = await tripTracking.finishForReview();
    if (!mounted) return null;
    final confirmedEndingOdometer = review == null
        ? null
        : await openOdometerEntryResult(
            context,
            title: 'Review GPS Trip Odometer',
            saveLabel: 'Confirm Odometer',
            tripReview: review,
          );
    if (!mounted) return null;
    final reviewConfirmed =
        confirmedEndingOdometer != null &&
        await tripTracking.confirmOdometerReview(
          reviewId: review!.id,
          confirmedEndingOdometer: confirmedEndingOdometer,
        );
    if (!mounted) return null;
    final confirmationError = confirmedEndingOdometer == null
        ? null
        : tripTracking.platformError;
    final cloudMirrorError = tripTracking.cloudMirrorError;
    _showGpsMessage(
      review == null
          ? (tripTracking.platformError ?? missingTripMessage)
          : reviewConfirmed
          ? _gpsReviewConfirmedMessage(
              tripTracking: tripTracking,
              cloudMirrorError: cloudMirrorError,
            )
          : confirmationError ??
                (cloudMirrorError == null
                    ? 'GPS trip ended and is ready for review.'
                    : 'GPS trip saved locally; cloud backup will retry.'),
    );
    return reviewConfirmed ? confirmedEndingOdometer : null;
  }

  Future<void> _reviewLatestGpsTrip() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    final review = tripTracking?.latestUnconfirmedReview;
    if (review == null) {
      _showGpsMessage('No saved GPS trip review is available.');
      return;
    }
    if (review.vehicleId != GlobalOdometerScope.of(context).vehicleId) {
      _showGpsMessage(
        'Switch to the vehicle used for this GPS trip before confirming its odometer.',
      );
      return;
    }
    final confirmedEndingOdometer = await openOdometerEntryResult(
      context,
      title: 'Review GPS Trip Odometer',
      saveLabel: 'Confirm Odometer',
      tripReview: review,
    );
    if (!mounted) return;
    final reviewConfirmed =
        confirmedEndingOdometer != null &&
        await tripTracking!.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: confirmedEndingOdometer,
        );
    if (!mounted) return;
    final confirmationError = confirmedEndingOdometer == null
        ? null
        : tripTracking!.platformError;
    final cloudMirrorError = tripTracking?.cloudMirrorError;
    _showGpsMessage(
      reviewConfirmed
          ? _gpsReviewConfirmedMessage(
              tripTracking: tripTracking,
              cloudMirrorError: cloudMirrorError,
            )
          : confirmationError ?? 'GPS trip review remains available locally.',
    );
  }

  Future<void> _showLatestGpsFieldSummary() async {
    final review = TripTrackingScope.maybeOf(
      context,
    )?.latestReviewForVehicle(GlobalOdometerScope.of(context).vehicleId);
    if (review == null) {
      _showGpsMessage('No completed GPS trip summary is available.');
      return;
    }
    final summary = TripTrackingFieldTrialSummary.fromReview(review);
    final summaryText = summary.toPlainText();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'GPS Field Summary',
          style: TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            summaryText,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: summaryText));
                if (context.mounted) {
                  _showGpsMessage(
                    'GPS field summary copied without route coordinates.',
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  _showGpsMessage('GPS field summary could not be copied.');
                }
              }
            },
            child: const Text('Copy Summary'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _gpsReviewConfirmedMessage({
    required TripTrackingController tripTracking,
    required String? cloudMirrorError,
  }) {
    final backupMessage = cloudMirrorError == null
        ? 'GPS trip reviewed and odometer confirmed.'
        : 'GPS trip reviewed and saved locally; cloud backup will retry.';
    if (tripTracking.platformStatus != 'odometer_reconciliation_review') {
      return backupMessage;
    }
    return '$backupMessage ${tripTracking.platformError ?? 'Review the GPS and odometer mileage difference.'}';
  }

  void _showGpsMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LiveOdometerDialogLine extends StatelessWidget {
  const _LiveOdometerDialogLine();

  @override
  Widget build(BuildContext context) {
    final odometer = GlobalOdometerScope.of(context);
    return AnimatedBuilder(
      animation: odometer,
      builder: (context, _) {
        final display = odometer.liveDisplaySnapshot;
        final status = display.statusLabelAt(DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${display.label}: ${display.displayValue}',
              semanticsLabel: display.semanticsLabelAt(DateTime.now()),
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 3),
              Text(
                '$status • confirmed ${display.confirmedDisplayValue}',
                style: const TextStyle(
                  color: Color(0xFF20F060),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LiveOdometerPanelLine extends StatelessWidget {
  const _LiveOdometerPanelLine();

  @override
  Widget build(BuildContext context) {
    final odometer = GlobalOdometerScope.of(context);
    return AnimatedBuilder(
      animation: odometer,
      builder: (context, _) {
        final display = odometer.liveDisplaySnapshot;
        final status = display.statusLabelAt(DateTime.now());
        return Text(
          'GPS estimate: ${display.displayValue} • Confirmed: ${display.confirmedDisplayValue}${status == null ? '' : ' • $status'}',
          style: const TextStyle(
            color: Color(0xFF9CC7E8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          semanticsLabel: display.semanticsLabelAt(DateTime.now()),
        );
      },
    );
  }
}

class _GpsTripPanel extends StatelessWidget {
  const _GpsTripPanel({
    required this.onStart,
    required this.onStop,
    required this.onCancel,
    required this.onReviewLatest,
    required this.onReviewWalkingStop,
    required this.onViewFieldSummary,
    required this.onOpenSettings,
    required this.startInFlight,
    required this.stopInFlight,
    required this.cancelInFlight,
  });

  final Future<void> Function() onStart;
  final Future<void> Function() onStop;
  final Future<void> Function() onCancel;
  final Future<void> Function() onReviewLatest;
  final Future<void> Function() onReviewWalkingStop;
  final Future<void> Function() onViewFieldSummary;
  final VoidCallback onOpenSettings;
  final bool startInFlight;
  final bool stopInFlight;
  final bool cancelInFlight;

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingScope.maybeOf(context);
    final settings = TripTrackingSettingsScope.maybeOf(context)?.settings;
    final activeWorkday = ActiveWorkdayScope.maybeOf(context)?.activeSession;
    final guidance = settings == null
        ? null
        : TripTrackingDashboardGuidance.fromSettings(settings);
    final capabilityGuidance =
        settings != null && controller?.lastKnownCapabilities != null
        ? TripTrackingCapabilityGuidance.fromCapabilities(
            capabilities: controller!.lastKnownCapabilities!,
            settings: settings,
          )
        : null;
    final odometerAlertEnabled =
        settings?.gpsAssistedTrackingEnabled == true &&
        settings?.odometerAnomalyAlertsEnabled == true;
    final usageSignal =
        odometerAlertEnabled && controller != null && activeWorkday != null
        ? controller.odometerUsageAnomalySignalForCurrentDay(
            startingOdometer: activeWorkday.startOdometer,
          )
        : null;
    final calibrationSignal = odometerAlertEnabled && controller != null
        ? controller.odometerCalibrationSignal()
        : null;
    final driverPattern =
        settings != null && controller != null && activeWorkday != null
        ? controller.driverPatternDecision(
            profileId: activeWorkday.workProfileId,
          )
        : null;
    final tracking = controller?.isTracking == true;
    final nativeTracking = controller?.nativeTracking == true;
    final pendingStopReviewCount = controller?.pendingStopReviewCount ?? 0;
    final latestVehicleReview = controller?.latestReviewForVehicle(
      GlobalOdometerScope.of(context).vehicleId,
    );
    final liveTrackingWarning = TripTrackingDashboardLiveStatusPolicy.warning(
      tracking: tracking,
      platformStatus: controller?.platformStatus,
      platformError: controller?.platformError,
      awaitingInitialFix: controller?.awaitingInitialFix == true,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF142126),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: nativeTracking
              ? const Color(0xFF20F060)
              : const Color(0xFF52656D),
        ),
      ),
      child: Row(
        children: [
          Icon(
            nativeTracking
                ? Icons.gps_fixed_rounded
                : Icons.gps_not_fixed_rounded,
            color: nativeTracking
                ? const Color(0xFF20F060)
                : const Color(0xFFFFD166),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS-ASSISTED TRIP',
                  style: TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nativeTracking
                      ? 'GPS assist ${controller!.acceptedMiles.toStringAsFixed(2)} mi; confirmed odometer stays official.'
                      : tracking
                      ? 'Trip is recoverable. Resume GPS when ready.'
                      : guidance?.enabled == true
                      ? guidance!.primaryStatus
                      : 'Off in trip tracking settings.',
                  style: const TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tracking) ...[
                  const SizedBox(height: 3),
                  const _LiveOdometerPanelLine(),
                ],
                if (liveTrackingWarning != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    liveTrackingWarning,
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (capabilityGuidance != null) ...[
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _GpsTripBadge(
                        label: capabilityGuidance.dashboardBadge,
                        active:
                            capabilityGuidance.readiness !=
                            TripTrackingCapabilityReadiness.unavailable,
                      ),
                      _GpsTripBadge(
                        label: capabilityGuidance.safeStatus,
                        active:
                            capabilityGuidance.readiness ==
                            TripTrackingCapabilityReadiness.fullSafetyAssist,
                      ),
                    ],
                  ),
                ],
                if (guidance != null && !tracking) ...[
                  const SizedBox(height: 3),
                  Text(
                    guidance.stopDetectionStatus,
                    style: const TextStyle(
                      color: Color(0xFF95A2A8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: guidance.dashboardBadges
                        .map(
                          (badge) => _GpsTripBadge(
                            label: badge,
                            active: guidance.enabled,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (guidance?.shouldShowActivityRecognitionRecommendation ==
                    true) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Motion assist is recommended for this work profile, but it remains opt-in.',
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (guidance?.shouldShowOdometerReview == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    guidance!.odometerStatus,
                    style: const TextStyle(
                      color: Color(0xFFCAD2D5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (usageSignal?.shouldPromptUser == true) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Odometer mileage is unusually high for reviewed history. Review before confirming; GPS stays advisory.',
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (calibrationSignal?.shouldPromptUser == true) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Repeated GPS/odometer drift detected. Check tire size or calibration; odometer stays official.',
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (driverPattern?.dashboardSuggestion != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    driverPattern!.dashboardSuggestion!,
                    style: const TextStyle(
                      color: Color(0xFF9CC7E8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (controller?.needsWalkingReview == true) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Possible stop detected. Review before adding it to your day.',
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onReviewWalkingStop,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        pendingStopReviewCount > 1
                            ? 'REVIEW POSSIBLE STOPS ($pendingStopReviewCount)'
                            : 'REVIEW POSSIBLE STOP',
                      ),
                    ),
                  ),
                ],
                if (controller?.cloudMirrorError != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    controller!.cloudMirrorError!,
                    style: const TextStyle(
                      color: Color(0xFFFF9F43),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: controller.retryCloudBackup,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('RETRY BACKUP'),
                    ),
                  ),
                ],
                if (!tracking && controller?.latestUnconfirmedReview != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onReviewLatest,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('REVIEW LATEST GPS TRIP'),
                    ),
                  ),
                if (latestVehicleReview != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onViewFieldSummary,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('VIEW GPS FIELD SUMMARY'),
                    ),
                  ),
                if (tracking)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: startInFlight || stopInFlight || cancelInFlight
                          ? null
                          : onCancel,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFFFF9F9F),
                      ),
                      child: Text(
                        cancelInFlight ? 'CANCELLING TRIP' : 'CANCEL GPS TRIP',
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onOpenSettings,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.only(top: 3, right: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('GPS & MOTION SETTINGS'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: startInFlight || stopInFlight || cancelInFlight
                ? null
                : nativeTracking
                ? onStop
                : onStart,
            style: FilledButton.styleFrom(
              backgroundColor: nativeTracking
                  ? const Color(0xFF8D2D2D)
                  : const Color(0xFF1976B9),
            ),
            child: Text(
              startInFlight
                  ? 'STARTING'
                  : stopInFlight
                  ? 'STOPPING'
                  : nativeTracking
                  ? 'STOP'
                  : tracking
                  ? 'RESUME'
                  : 'START',
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsTripBadge extends StatelessWidget {
  const _GpsTripBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E342B) : const Color(0xFF2A3033),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF20F060) : const Color(0xFF52656D),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFE8FFF0) : const Color(0xFFCAD2D5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LowBatteryGpsChoice {
  const _LowBatteryGpsChoice({
    required this.continueGps,
    required this.rememberChoice,
  });

  final bool continueGps;
  final bool rememberChoice;
}
