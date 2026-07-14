import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/flow_placeholder_screen.dart';
import '../expenses/entry/expense_receipt_entry_screen.dart';
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
  Timer? _timer;
  var _elapsed = Duration.zero;
  late var _activeVehicle = widget.activeVehicle;

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
    final quickActions = _quickActionsFor(session);
    final currentOdometer = GlobalOdometerScope.of(context).reading;
    final elapsed = session == null
        ? _elapsed
        : session.elapsedWorkTimeAt(DateTime.now());
    final milesToday = session?.milesSoFar(currentOdometer).toString() ?? '0';

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
                  onVehicleChanged: (vehicle) {
                    setState(() => _activeVehicle = vehicle);
                  },
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
                      child: _MetricTile(
                        label: 'Miles Today',
                        value: milesToday,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _GpsTripPanel(
                  onStart: _startGpsTrip,
                  onStop: _stopGpsTrip,
                  onReviewLatest: _reviewLatestGpsTrip,
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
  ) {
    if (session?.status != ActiveWorkdayStatus.paused) {
      return workdayQuickActions;
    }

    return [
      const WorkdayQuickActionSpec(
        icon: Icons.play_arrow_rounded,
        emoji: '▶️',
        label: 'Resume Day',
        color: Color(0xFF2AA875),
        flowTitle: 'Resume Workday',
        flowSummary: 'Resume the current workday without creating a new day.',
      ),
      ...workdayQuickActions.skip(1),
    ];
  }

  Future<void> _handleQuickAction(WorkdayQuickActionSpec action) async {
    switch (action.label) {
      case 'Pause Day':
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
      case 'Resume Day':
        await _recordStoredEvent(ActiveWorkdayEventType.resumed);
        if (!mounted) return;
        await _startGpsTrip();
        return;
      case 'End Day':
        final tripTracking = TripTrackingScope.maybeOf(context);
        if (tripTracking?.isTracking == true) {
          await tripTracking!.finishForReview();
        }
        final saved = await _recordOdometerEvent(
          title: 'Ending Odometer',
          saveLabel: 'End Day',
          type: ActiveWorkdayEventType.ended,
        );
        if (saved && mounted) Navigator.of(context).pop();
      case 'Add Fuel':
        await Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            const ExpenseReceiptEntryScreen(initialCategory: 'Fuel'),
          ),
        );
        await _recordStoredEvent(ActiveWorkdayEventType.fuel);
      case 'Expense':
        await Navigator.of(context).push(
          appNativeRoute<void>(context, const ExpenseReceiptEntryScreen()),
        );
        await _recordStoredEvent(ActiveWorkdayEventType.expense);
      case 'Add Stop':
        await _openStopDialog('Stop', ActiveWorkdayEventType.stop);
      case 'Add Pickup':
        await _openStopDialog('Pickup', ActiveWorkdayEventType.pickup);
      case 'Add Drop-Off':
        await _openStopDialog('Drop-off', ActiveWorkdayEventType.dropOff);
      default:
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
  }) async {
    if (!mounted) return;
    final activeWorkday = ActiveWorkdayScope.of(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    await activeWorkday.addEvent(
      type: type,
      odometerReading: GlobalOdometerScope.of(context).reading,
      note: note,
    );
    if (type == ActiveWorkdayEventType.stop ||
        type == ActiveWorkdayEventType.pickup ||
        type == ActiveWorkdayEventType.dropOff) {
      await tripTracking?.acknowledgeWalkingReview();
    }
  }

  Future<void> _openStopDialog(String kind, ActiveWorkdayEventType type) async {
    final noteController = TextEditingController();
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
            Text(
              'Odometer: ${GlobalOdometerScope.of(context).displayValue}',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
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
    final note = noteController.text.trim();
    noteController.dispose();
    if (!mounted) return;
    if (saved == true) {
      await _recordStoredEvent(type, note: note);
    }
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
    final settingsController = TripTrackingSettingsScope.maybeOf(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (settingsController == null || tripTracking == null) return;
    if (ActiveWorkdayScope.of(context).activeSession?.isPaused == true) {
      _showGpsMessage('Resume Day before restarting GPS-assisted tracking.');
      return;
    }
    final settings = settingsController.settings;
    if (!settings.gpsAssistedTrackingEnabled) {
      _showGpsMessage(
        'Enable GPS-assisted tracking in Dashboard Settings first.',
      );
      return;
    }
    var startedNewTrip = false;
    if (!tripTracking.isTracking) {
      startedNewTrip = await tripTracking.start(
        tripId: 'gps-trip-${DateTime.now().microsecondsSinceEpoch}',
        vehicleId: GlobalOdometerScope.of(context).vehicleId,
        profile: settings.defaultProfile,
      );
      if (!startedNewTrip) {
        _showGpsMessage('A GPS trip could not be created.');
        return;
      }
    }
    final started = await tripTracking.startNativeTracking(
      allowBackground: settings.backgroundTrackingEnabled,
      samplingOverride: _samplingForPreset(settings),
      adaptiveSamplingEnabled: settings.adaptiveSamplingEnabled,
      activityRecognitionEnabled: settings.activityRecognitionEnabled,
    );
    if (!started && startedNewTrip) await tripTracking.discardEmptyTrip();
    if (!mounted) return;
    _showGpsMessage(
      started
          ? 'GPS-assisted trip tracking started.'
          : (tripTracking.platformError ?? 'GPS tracking could not start.'),
    );
  }

  Future<void> _stopGpsTrip() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking == null || !tripTracking.isTracking) return;
    final review = await tripTracking.finishForReview();
    if (!mounted) return;
    final cloudMirrorError = tripTracking.cloudMirrorError;
    final odometerSaved = review == null
        ? false
        : await openOdometerEntry(
            context,
            title: 'Review GPS Trip Odometer',
            saveLabel: 'Confirm Odometer',
            tripReview: review,
          );
    if (!mounted) return;
    final reviewConfirmed =
        odometerSaved &&
        await tripTracking.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: GlobalOdometerScope.of(context).reading,
        );
    if (!mounted) return;
    _showGpsMessage(
      review == null
          ? (tripTracking.platformError ?? 'No active GPS trip to stop.')
          : reviewConfirmed
          ? 'GPS trip reviewed and odometer confirmed.'
          : cloudMirrorError == null
          ? 'GPS trip ended and is ready for review.'
          : 'GPS trip saved locally; cloud backup will retry.',
    );
  }

  Future<void> _reviewLatestGpsTrip() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    final review = tripTracking?.latestUnconfirmedReview;
    if (review == null) {
      _showGpsMessage('No saved GPS trip review is available.');
      return;
    }
    final saved = await openOdometerEntry(
      context,
      title: 'Review GPS Trip Odometer',
      saveLabel: 'Confirm Odometer',
      tripReview: review,
    );
    if (!mounted) return;
    final reviewConfirmed =
        saved &&
        await tripTracking!.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: GlobalOdometerScope.of(context).reading,
        );
    if (!mounted) return;
    _showGpsMessage(
      reviewConfirmed
          ? 'GPS trip reviewed and odometer confirmed.'
          : 'GPS trip review remains available locally.',
    );
  }

  void _showGpsMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GpsTripPanel extends StatelessWidget {
  const _GpsTripPanel({
    required this.onStart,
    required this.onStop,
    required this.onReviewLatest,
  });

  final Future<void> Function() onStart;
  final Future<void> Function() onStop;
  final Future<void> Function() onReviewLatest;

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingScope.maybeOf(context);
    final settings = TripTrackingSettingsScope.maybeOf(context)?.settings;
    final tracking = controller?.isTracking == true;
    final nativeTracking = controller?.nativeTracking == true;
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
                      ? 'Tracking ${controller!.acceptedMeters.toStringAsFixed(0)} m; odometer is live.'
                      : tracking
                      ? 'Trip is recoverable. Resume GPS when ready.'
                      : settings?.gpsAssistedTrackingEnabled == true
                      ? 'Ready when you are driving.'
                      : 'Off in trip tracking settings.',
                  style: const TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: nativeTracking ? onStop : onStart,
            style: FilledButton.styleFrom(
              backgroundColor: nativeTracking
                  ? const Color(0xFF8D2D2D)
                  : const Color(0xFF1976B9),
            ),
            child: Text(
              nativeTracking
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

TripSamplingRecommendation _samplingForPreset(
  TripTrackingSettings settings,
) => switch (settings.samplingPreset) {
  TripTrackingSamplingPreset.highAccuracy => const TripSamplingRecommendation(
    mode: TripSamplingMode.precision,
    interval: Duration(seconds: 3),
    minimumDisplacementMeters: 3,
  ),
  TripTrackingSamplingPreset.enhancedAccuracy =>
    const TripSamplingRecommendation(
      mode: TripSamplingMode.balanced,
      interval: Duration(seconds: 8),
      minimumDisplacementMeters: 5,
    ),
  TripTrackingSamplingPreset.balanced => const TripSamplingRecommendation(
    mode: TripSamplingMode.balanced,
    interval: Duration(seconds: 15),
    minimumDisplacementMeters: 8,
  ),
  TripTrackingSamplingPreset.batterySaver => const TripSamplingRecommendation(
    mode: TripSamplingMode.economy,
    interval: Duration(seconds: 30),
    minimumDisplacementMeters: 20,
  ),
  TripTrackingSamplingPreset.extremeOptimized =>
    const TripSamplingRecommendation(
      mode: TripSamplingMode.economy,
      interval: Duration(seconds: 60),
      minimumDisplacementMeters: 30,
    ),
  TripTrackingSamplingPreset.custom => TripSamplingRecommendation(
    mode: TripSamplingMode.balanced,
    interval: Duration(seconds: settings.customIntervalSeconds),
    minimumDisplacementMeters: 8,
  ),
};
