import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/calendar/calendar.dart';
import '../../shared/device_capabilities/device_capability_scope.dart';
import '../../shared/context/operational_context_models.dart';
import '../../shared/context/operational_context_store.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/odometer/odometer_distance_value.dart';
import '../../shared/odometer/odometer_correction_review.dart';
import '../../shared/odometer/odometer_entry_sheet.dart'
    show OdometerMinimumReadingReviewHandler;
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
import '../../shared/trip_tracking/trip_tracking_signal_quality.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../expenses/entry/expense_receipt_entry_screen.dart';
import '../expenses/data/expense_ledger_models.dart';
import '../expenses/data/expense_work_profile_store.dart';
import '../expenses/reminders/expense_reminder_screen.dart';
import '../invoices/data/invoice_ledger_models.dart';
import '../invoices/home/invoice_form_screen.dart';
import '../invoices/home/invoice_info_screens.dart';
import '../settings/trip_tracking_settings_screen.dart';
import 'active_workday_actions.dart';
import 'active_workday_context_handoff_sheet.dart';
import 'contractor/contractor_dashboard_screen.dart';
import 'active_workday_financial_summary_panel.dart';
import 'active_workday_vehicle_use_summary_panel.dart';
import 'active_workday_odometer_review_panel.dart';
import 'active_workday_tracking_status_line.dart';
import 'trip_automatic_evidence_review_sheet.dart';
import 'active_workday_quick_action_editor.dart';
import 'data/active_workday_elapsed_clock.dart';
import 'data/active_workday_context_handoff_coordinator.dart';
import 'data/active_workday_store.dart';
import 'gig_dashboard_record_review_screens.dart';
import 'trip_background_location_settings_prompt.dart';
import 'trip_tracking_setup_sheet.dart';
import 'vehicle_profile_widgets.dart';
import 'workday_note_sheet.dart';

part 'active_workday_context_bar.dart';
part 'active_workday_session_widgets.dart';
part 'active_workday_expense_actions.dart';

class ActiveWorkdayScreen extends StatefulWidget {
  const ActiveWorkdayScreen({
    super.key,
    required this.activeVehicle,
    required this.workProfileName,
    this.promptForTripTrackingSetup = false,
    this.startGpsWhenOpened = false,
  });

  final VehicleProfilePreview activeVehicle;
  final String workProfileName;
  final bool promptForTripTrackingSetup;
  final bool startGpsWhenOpened;

  @override
  State<ActiveWorkdayScreen> createState() => _ActiveWorkdayScreenState();
}

class _ActiveWorkdayScreenState extends State<ActiveWorkdayScreen> {
  final Random _tripIdRandom = Random.secure();
  final ActiveWorkdayElapsedClock _elapsedClock =
      ActiveWorkdayElapsedClock.runtime();
  Timer? _timer;
  var _gpsStartInFlight = false;
  var _gpsCancelInFlight = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (widget.promptForTripTrackingSetup || widget.startGpsWhenOpened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startGpsTrip();
      });
    }
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
    final quickActionTileHeight =
        66 + (MediaQuery.textScalerOf(context).scale(10) * 2.4);
    final odometer = GlobalOdometerScope.of(context);
    final elapsed = _elapsedClock.elapsedFor(session, wallNow: DateTime.now());

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
                  workProfileName: widget.workProfileName,
                  onChangeContext: _openContextHandoff,
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
                ActiveWorkdayTrackingStatusLine(
                  onStart: _startGpsTrip,
                  onResume: _startGpsTrip,
                  onStop: _cancelGpsTrip,
                  onReview: _reviewLatestGpsTrip,
                  onReviewAutomaticEvidence: () =>
                      showTripAutomaticEvidenceReviewSheet(context),
                  resumeInFlight: _gpsStartInFlight,
                  stopInFlight: _gpsCancelInFlight,
                ),
                if (session?.odometerReviews.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  ActiveWorkdayOdometerReviewNotice(
                    reviews: session!.odometerReviews,
                    onPressed: () => showActiveWorkdayOdometerReviews(
                      context,
                      reviews: session.odometerReviews,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ActiveWorkdayFinancialSummaryPanel(
                  session: session,
                  day: DateTime.now(),
                ),
                if (session != null) ...[
                  const SizedBox(height: 8),
                  ActiveWorkdayVehicleUseSummaryPanel(
                    vehicleId: session.vehicleId,
                    day: DateTime.now(),
                  ),
                ],
                const SizedBox(height: 12),
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: quickActionTileHeight,
                  ),
                  itemBuilder: (context, index) {
                    return _QuickActionButton(
                      action: quickActions[index],
                      onTap: () => _handleQuickAction(quickActions[index]),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SessionActivityList(
                  events: session?.events ?? const [],
                  pendingGpsStopReviews:
                      TripTrackingScope.maybeOf(
                        context,
                      )?.pendingStopReviewCount ??
                      0,
                  onReviewGpsStops: _reviewWalkingStop,
                ),
                const SizedBox(height: 16),
                // The Dashboard Calendar remains available while a workday is
                // active. It projects scheduled and recorded source records;
                // the activity list above is not a replacement for it. Like
                // every major landing screen, Calendar remains at the bottom.
                const DashboardCalendar(),
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
        label: 'Resume Day',
        color: Color(0xFF2AA875),
      ),
      ...actionLayout.activeActions.where(
        (action) => action.kind != WorkdayQuickActionKind.pauseDay,
      ),
    ];
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
          // Stopping GPS creates a durable completion-pending review. If the
          // driver dismisses that review, keep the workday open instead of
          // bypassing it with a second generic ending-odometer sheet.
          if (tripTracking.isTracking || confirmedTripEndingOdometer == null) {
            return;
          }
          final ended = await ActiveWorkdayScope.of(context).addEvent(
            type: ActiveWorkdayEventType.ended,
            odometerReading: confirmedTripEndingOdometer,
          );
          if (ended != null && mounted) {
            _returnToDashboardAfterEndDay();
          }
          return;
        }
        final saved = await _recordOdometerEvent(
          title: 'Ending Odometer',
          saveLabel: 'End Day',
          type: ActiveWorkdayEventType.ended,
          minimumReading: ActiveWorkdayScope.of(
            context,
          ).activeSession?.startOdometer,
          minimumReadingTenths: ActiveWorkdayScope.of(
            context,
          ).activeSession?.currentContextSegment.effectiveStartOdometerTenths,
          minimumReadingMessage:
              'Your workday stays open until this lower reading is reviewed.',
          onMinimumReadingReview: _recordEndDayOdometerReview,
        );
        if (saved && mounted) {
          _returnToDashboardAfterEndDay();
        }
      case WorkdayQuickActionKind.addFuel:
        await _openExpenseReview(category: 'Fuel');
      case WorkdayQuickActionKind.expense:
        await _openExpenseReview();
      case WorkdayQuickActionKind.receipt:
        await _openExpenseAndRecord(
          title: 'Receipt Odometer',
          saveLabel: 'Continue to Receipt',
          eventType: ActiveWorkdayEventType.expense,
        );
      case WorkdayQuickActionKind.addStop:
        await _openStopDialog('Stop', ActiveWorkdayEventType.stop);
      case WorkdayQuickActionKind.addPickup:
        await _openStopDialog('Pickup', ActiveWorkdayEventType.pickup);
      case WorkdayQuickActionKind.addDropOff:
        await _openStopDialog('Drop-off', ActiveWorkdayEventType.dropOff);
      case WorkdayQuickActionKind.payment:
        await Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoicePaymentScreen()));
      case WorkdayQuickActionKind.invoice:
        await Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const InvoiceFormScreen()));
      case WorkdayQuickActionKind.maintenance:
        openAppSectionRoot(context, AppSection.maintenance);
      case WorkdayQuickActionKind.materials:
        openAppSectionRoot(context, AppSection.materials);
      case WorkdayQuickActionKind.reminder:
        await Navigator.of(
          context,
        ).push(appNativeRoute<void>(context, const ExpenseReminderScreen()));
      case WorkdayQuickActionKind.estimate:
        await Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            const InvoiceFormScreen(documentType: InvoiceDocumentType.estimate),
          ),
        );
      case WorkdayQuickActionKind.note:
        final note = await openWorkdayNoteSheet(context);
        if (!mounted || note == null) return;
        await _recordStoredEvent(ActiveWorkdayEventType.note, note: note);
      case WorkdayQuickActionKind.reviewStops:
        await _reviewWalkingStop();
      case WorkdayQuickActionKind.reviewGpsTrip:
        await _reviewLatestGpsTrip();
      case WorkdayQuickActionKind.stopGpsTracking:
        await _cancelGpsTrip();
      case WorkdayQuickActionKind.tripDetails:
        await _showLatestGpsFieldSummary();
      case WorkdayQuickActionKind.retryTripLog:
        await _retryLatestTripLogProposal();
      case WorkdayQuickActionKind.gpsSettings:
        await Navigator.of(context).push(
          appNativeRoute<void>(context, const TripTrackingSettingsScreen()),
        );
    }
  }

  void _returnToDashboardAfterEndDay() {
    // The active day may be a pushed route or Dashboard's rebuilt root body.
    // Pop only this screen when it is pushed. Popping an arbitrary route stack
    // after the odometer sheet closes can expose an empty intermediary surface.
    // At the root, ActiveWorkdayScope's notification rebuilds Dashboard instead.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _openContextHandoff() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking?.isTracking == true) {
      _showGpsMessage(
        'Finish and review the active GPS trip before changing vehicles or work profiles.',
      );
      return;
    }
    final session = ActiveWorkdayScope.of(context).activeSession;
    final coordinator = ActiveWorkdayContextHandoffScope.maybeOf(context);
    final appState = AppStateScope.of(context);
    final workProfiles = ExpenseWorkProfileScope.of(context);
    if (session == null || coordinator == null) {
      _showGpsMessage('Workday context changes are not available right now.');
      return;
    }
    final activeContext = session.currentContextSegment;
    final currentVehicle = appState.vehicleById(activeContext.vehicleId);
    final currentProfile = workProfiles.profileById(
      activeContext.workProfileId,
    );
    if (currentVehicle == null || currentProfile == null) {
      _showGpsMessage(
        'Reload the active vehicle and work profile before changing this workday.',
      );
      return;
    }
    final draft = await openActiveWorkdayContextHandoffSheet(
      context,
      currentVehicle: currentVehicle,
      currentWorkProfile: currentProfile,
      currentOdometer: session.latestOdometerForContext(activeContext.id),
      vehicles: appState.vehicles,
      workProfiles: workProfiles.profiles,
    );
    if (!mounted || draft == null) return;
    final operationId =
        'workday-handoff-${DateTime.now().toUtc().microsecondsSinceEpoch}-${_tripIdRandom.nextInt(1 << 32)}';
    final result = await coordinator.apply(
      ActiveWorkdayContextHandoffRequest(
        operationId: operationId,
        workdayId: session.id,
        vehicleId: draft.vehicle.id,
        vehicleLabel: draft.vehicle.nickname,
        workProfileId: draft.workProfile.id,
        endingOdometer: draft.endingOdometer,
        startingOdometer: draft.startingOdometer,
        occurredAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    _showGpsMessage(
      result.completed
          ? 'Workday context changed. Your earlier segment remains unchanged.'
          : result.message ?? 'Review the saved workday context change.',
    );
  }

  Future<bool> _recordOdometerEvent({
    required String title,
    required String saveLabel,
    required ActiveWorkdayEventType type,
    int? minimumReading,
    int? minimumReadingTenths,
    String? minimumReadingMessage,
    OdometerMinimumReadingReviewHandler? onMinimumReadingReview,
  }) async {
    final reading = await _recordOdometerExactReading(
      title: title,
      saveLabel: saveLabel,
      minimumReading: minimumReading,
      minimumReadingTenths: minimumReadingTenths,
      minimumReadingMessage: minimumReadingMessage,
      onMinimumReadingReview: onMinimumReadingReview,
    );
    if (!mounted) return false;
    if (reading != null) {
      await ActiveWorkdayScope.of(context).addEvent(
        type: type,
        odometerReading: reading.wholeReading,
        odometerReadingTenths: reading.readingTenths,
      );
    }
    return reading != null;
  }

  Future<OdometerExactEntryResult?> _recordOdometerExactReading({
    required String title,
    required String saveLabel,
    int? minimumReading,
    int? minimumReadingTenths,
    String? minimumReadingMessage,
    OdometerMinimumReadingReviewHandler? onMinimumReadingReview,
  }) {
    return openOdometerExactEntryResult(
      context,
      title: title,
      saveLabel: saveLabel,
      minimumReading: minimumReading,
      minimumReadingTenths: minimumReadingTenths,
      minimumReadingMessage: minimumReadingMessage,
      onMinimumReadingReview: onMinimumReadingReview,
    );
  }

  /// Legacy whole-mile bridge for Dashboard-owned actions that do not yet
  /// persist an exact odometer boundary. The entry sheet still validates an
  /// optional tenth-mile minimum before this presentation value is returned.
  Future<int?> _recordOdometerReading({
    required String title,
    required String saveLabel,
    int? minimumReading,
    int? minimumReadingTenths,
    String? minimumReadingMessage,
    OdometerMinimumReadingReviewHandler? onMinimumReadingReview,
  }) async {
    final exact = await _recordOdometerExactReading(
      title: title,
      saveLabel: saveLabel,
      minimumReading: minimumReading,
      minimumReadingTenths: minimumReadingTenths,
      minimumReadingMessage: minimumReadingMessage,
      onMinimumReadingReview: onMinimumReadingReview,
    );
    return exact?.wholeReading;
  }

  Future<bool> _recordEndDayOdometerReview({
    required int enteredOdometer,
    int? enteredOdometerTenths,
    required OdometerCorrectionReview review,
  }) async {
    final saved = await ActiveWorkdayScope.of(context).requestOdometerReview(
      enteredOdometer: enteredOdometer,
      enteredOdometerTenths: enteredOdometerTenths,
      reason: review.reason,
    );
    if (saved == null || !mounted) return false;
    _showGpsMessage(
      'Odometer review saved. Your day is still open; nothing was changed automatically.',
    );
    return true;
  }

  Future<void> _recordStoredEvent(
    ActiveWorkdayEventType type, {
    int? odometerReading,
    String? note,
    bool confirmGpsStopCandidate = false,
  }) async {
    if (!mounted) return;
    final activeWorkday = ActiveWorkdayScope.of(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    final updatedWorkday = await activeWorkday.addEvent(
      type: type,
      odometerReading:
          odometerReading ?? GlobalOdometerScope.of(context).reading,
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
        odometerReading: GlobalOdometerScope.of(context).confirmedReading,
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
    final activeContext = activeSession.currentContextSegment;
    final odometer = GlobalOdometerScope.of(context);
    if (activeContext.vehicleId != odometer.vehicleId) {
      _showGpsMessage(
        'Switch to the active workday vehicle before starting GPS-assisted tracking.',
      );
      return;
    }
    final settings = settingsController.settings;
    if (!settings.gpsAssistedTrackingEnabled) {
      final setup = await openTripTrackingSetupSheet(
        context,
        currentSettings: settings,
      );
      if (!mounted || setup == null) return;
      await settingsController.update(setup.settings);
      if (!mounted) return;
      await _applySetupDashboardMode(setup.settings.defaultProfile);
      if (!mounted) return;
      if (setup.action == TripTrackingSetupAction.skip) return;
      if (setup.action == TripTrackingSetupAction.openSettings) {
        await Navigator.of(context).push(
          appNativeRoute<void>(context, const TripTrackingSettingsScreen()),
        );
        return;
      }
      return _startGpsTripImpl();
    }
    // GPS is heavy work. Refresh the shared runtime profile only after the
    // driver has actually opted in, so a disabled setting never wakes the
    // capability probe. This refresh informs dashboard guidance; it neither
    // grants permission nor silently changes the selected sampling preset.
    await DeviceCapabilityScope.refreshForHeavyWork(context);
    if (!mounted) return;
    final deviceIntervalFloorSeconds = DeviceCapabilityScope.maybeOf(
      context,
    )?.profile?.budget.tripLocationIntervalSeconds;
    if (tripTracking.nativeTracking) {
      _showGpsMessage('GPS-assisted trip tracking is already active.');
      return;
    }
    var startedNewTrip = false;
    if (!tripTracking.isTracking) {
      startedNewTrip = await tripTracking.start(
        tripId:
            'gps-trip-${DateTime.now().microsecondsSinceEpoch}-${_tripIdRandom.nextInt(0x100000000).toRadixString(16)}',
        vehicleId: odometer.vehicleId,
        profile: settings.defaultProfile,
        profileId: activeContext.workProfileId,
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
      deviceIntervalFloorSeconds: deviceIntervalFloorSeconds ?? 1,
    );
    final nativeStartFailureMessage = started
        ? null
        : tripTracking.lastKnownCapabilities?.locationAvailable == false
        ? 'Device location is unavailable. Your workday is active and manual mileage is still available.'
        : tripTracking.platformError;
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
            deviceIntervalFloorSeconds: deviceIntervalFloorSeconds ?? 1,
          );
          final retryFailureMessage = retryStarted
              ? null
              : tripTracking.platformError;
          var discardedEmptyTrip = true;
          if (!retryStarted && startedNewTrip) {
            discardedEmptyTrip = await tripTracking.discardEmptyTrip();
          }
          if (!mounted) return;
          final retryMessage = retryStarted
              ? _gpsStartedMessage(tripTracking)
              : !discardedEmptyTrip
              ? (tripTracking.platformError ??
                    'GPS tracking stopped, but its empty local session still needs review.')
              : (retryFailureMessage ?? 'GPS tracking could not start.');
          _showGpsMessage(retryMessage);
          return;
        }
      }
    }
    final backgroundSettingsRequired =
        !started &&
        defaultTargetPlatform == TargetPlatform.android &&
        tripTracking.platformStatus == 'background_location_settings_required';
    var discardedEmptyTrip = true;
    if (!started && startedNewTrip) {
      discardedEmptyTrip = await tripTracking.discardEmptyTrip();
    }
    if (!mounted) return;
    if (!discardedEmptyTrip) {
      _showGpsMessage(
        tripTracking.platformError ??
            'GPS tracking stopped, but its empty local session still needs review.',
      );
      return;
    }
    if (backgroundSettingsRequired) {
      final openSettings = await showTripBackgroundLocationSettingsPrompt(
        context,
      );
      if (!mounted) return;
      if (openSettings) {
        final opened = await tripTracking.openBackgroundLocationSettings();
        if (!opened && mounted) {
          _showGpsMessage(
            'Android settings could not be opened. Manual mileage is still available.',
          );
        }
      }
      return;
    }
    _showGpsMessage(
      started
          ? _gpsStartedMessage(tripTracking)
          : (nativeStartFailureMessage ?? 'GPS tracking could not start.'),
    );
  }

  String _gpsStartedMessage(TripTrackingController controller) {
    final interval = controller.nativeSamplingIntervalSeconds;
    if (!controller.deviceAdjustedSampling || interval == null) {
      return 'GPS-assisted trip tracking started.';
    }
    return 'GPS-assisted trip tracking started with a device-safe '
        '$interval-second location interval.';
  }

  Future<void> _applySetupDashboardMode(TripTrackingProfile profile) async {
    final operationalContext = OperationalContextScope.maybeOf(context);
    if (operationalContext == null) return;
    final currentMode = operationalContext.context.dashboardMode;
    if (currentMode != OperationalDashboardMode.gigDriver &&
        currentMode != OperationalDashboardMode.soloContractor) {
      return;
    }
    final selectedMode = switch (profile) {
      TripTrackingProfile.contractorVehicle =>
        OperationalDashboardMode.soloContractor,
      TripTrackingProfile.deliveryVehicle ||
      TripTrackingProfile.rideshareVehicle =>
        OperationalDashboardMode.gigDriver,
      TripTrackingProfile.roadVehicle ||
      TripTrackingProfile.lowSpeedEquipment => null,
    };
    if (selectedMode != null && selectedMode != currentMode) {
      await operationalContext.setDashboardMode(selectedMode);
    }
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

  Future<void> _cancelGpsTrip() async {
    if (_gpsCancelInFlight || _gpsStartInFlight) return;
    final tripTracking = TripTrackingScope.maybeOf(context);
    if (tripTracking == null || !tripTracking.isTracking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        title: const Text(
          'Stop Location Tracking?',
          style: TextStyle(
            color: Color(0xFFF0F4F2),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Phone location will stop. The distance and possible stops already '
          'recorded will stay available for review. Your workday and odometer '
          'will not change.',
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
            child: const Text('Stop Location Tracking'),
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
                  'Location tracking could not be stopped safely.')
            : 'Location tracking stopped. Your workday remains active.',
      );
    } finally {
      if (mounted) {
        setState(() => _gpsCancelInFlight = false);
      } else {
        _gpsCancelInFlight = false;
      }
    }
  }

  Future<int?> _finishAndReviewGpsTrip(
    TripTrackingController tripTracking, {
    required String missingTripMessage,
  }) async {
    final review = await tripTracking.finishForReview();
    if (!mounted) return null;
    final confirmedEndingOdometer = review == null
        ? null
        : await openOdometerExactEntryResult(
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
          confirmedEndingOdometer: confirmedEndingOdometer.wholeReading,
          confirmedEndingOdometerTenths: confirmedEndingOdometer.readingTenths,
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
    return reviewConfirmed ? confirmedEndingOdometer.wholeReading : null;
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
    final confirmedEndingOdometer = await openOdometerExactEntryResult(
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
          confirmedEndingOdometer: confirmedEndingOdometer.wholeReading,
          confirmedEndingOdometerTenths: confirmedEndingOdometer.readingTenths,
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

  Future<void> _retryLatestTripLogProposal() async {
    final tripTracking = TripTrackingScope.maybeOf(context);
    final review = tripTracking?.latestPendingTripLogProposal;
    if (tripTracking == null || review == null) {
      _showGpsMessage('No pending local trip handoff is available.');
      return;
    }
    final submitted = await tripTracking.retryTripLogProposal(review.id);
    if (!mounted) return;
    _showGpsMessage(
      submitted
          ? 'Trip is ready for TripLog review.'
          : (tripTracking.tripLogProposalError ??
                'The trip remains saved locally and can be retried.'),
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
    final tripTracking = TripTrackingScope.maybeOf(context);
    return AnimatedBuilder(
      animation: tripTracking == null
          ? odometer
          : Listenable.merge([odometer, tripTracking]),
      builder: (context, _) {
        final display = odometer.liveDisplaySnapshot;
        final status = !display.isLive
            ? null
            : tripTracking?.nativeTracking == true
            ? display.deltaLabel
            : tripTracking?.lifecycleState ==
                  TripTrackingSessionLifecycleState.starting
            ? 'Location starting'
            : 'Location paused';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${display.label}: ${display.displayValue}',
              semanticsLabel: [
                display.label,
                display.displayValue,
                ?status,
                if (display.isLive)
                  'confirmed ${display.confirmedDisplayValue}',
              ].join(', '),
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 3),
              Text(
                '$status • confirmed ${display.confirmedDisplayValue}',
                style: TextStyle(
                  color: status == 'Location paused'
                      ? const Color(0xFFFFD166)
                      : status == 'Location starting'
                      ? const Color(0xFF9CC7E8)
                      : const Color(0xFF20F060),
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
    final tripTracking = TripTrackingScope.maybeOf(context);
    return AnimatedBuilder(
      animation: tripTracking == null
          ? odometer
          : Listenable.merge([odometer, tripTracking]),
      builder: (context, _) {
        final display = odometer.liveDisplaySnapshot;
        final status = !display.isLive
            ? null
            : tripTracking?.nativeTracking == true
            ? display.deltaLabel
            : tripTracking?.lifecycleState ==
                  TripTrackingSessionLifecycleState.starting
            ? 'Location starting'
            : 'Location paused';
        return Text(
          'Location estimate: ${display.displayValue} • Last confirmed: ${display.confirmedDisplayValue}${status == null ? '' : ' • $status'}',
          style: const TextStyle(
            color: Color(0xFF9CC7E8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          semanticsLabel: [
            display.label,
            display.displayValue,
            ?status,
            if (display.isLive) 'confirmed ${display.confirmedDisplayValue}',
          ].join(', '),
        );
      },
    );
  }
}

/// Retired dashboard panel retained temporarily while its detailed status
/// elements are migrated into configurable Quick Actions. It is never rendered.
@Deprecated('Use configurable workday Quick Actions instead.')
class GpsTripPanelRetired extends StatelessWidget {
  const GpsTripPanelRetired({
    super.key,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
    required this.onReviewLatest,
    required this.onRetryTripLogProposal,
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
  final Future<void> Function() onRetryTripLogProposal;
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
            profileId: activeWorkday.currentContextSegment.workProfileId,
          )
        : null;
    final tracking = controller?.isTracking == true;
    final nativeTracking = controller?.nativeTracking == true;
    final gpsEnabled = settings?.gpsAssistedTrackingEnabled == true;
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
    final showLiveTrackingWarning =
        liveTrackingWarning != null &&
        liveTrackingWarning !=
            'Location tracking stays paused until you tap Resume.';
    final signalAction = controller?.signalQualityAction();
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
                  'TRIP TRACKING',
                  style: TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nativeTracking
                      ? 'Phone location shows ${controller!.acceptedMiles.toStringAsFixed(2)} mi; your odometer stays official.'
                      : tracking
                      ? 'Location tracking is paused. Your workday and odometer record are saved.'
                      : !gpsEnabled
                      ? 'Set up phone location to help track this trip.'
                      : guidance?.enabled == true
                      ? guidance!.primaryStatus
                      : 'Ready when you start tracking.',
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
                if (showLiveTrackingWarning) ...[
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
                if (tracking && signalAction?.shouldShowBanner == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    _gpsSignalQualityMessage(
                      controller!.signalQualitySummary.quality,
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (gpsEnabled && capabilityGuidance != null) ...[
                  const SizedBox(height: 3),
                  _GpsTripBadge(
                    label: _plainCapabilityLabel(capabilityGuidance.readiness),
                    active:
                        capabilityGuidance.readiness !=
                        TripTrackingCapabilityReadiness.unavailable,
                  ),
                ],
                if (gpsEnabled && guidance != null && !tracking) ...[
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
                if (gpsEnabled &&
                    guidance?.shouldShowActivityRecognitionRecommendation ==
                        true) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Turn on stop suggestions if you want help noticing possible stops.',
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
                if (gpsEnabled &&
                    driverPattern?.dashboardSuggestion != null) ...[
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
                if (gpsEnabled && controller?.cloudMirrorError != null) ...[
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
                if (controller?.tripLogProposalError != null &&
                    controller?.latestPendingTripLogProposal != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    controller!.tripLogProposalError!,
                    style: const TextStyle(
                      color: Color(0xFFFF9F43),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onRetryTripLogProposal,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('RETRY TRIPLOG HANDOFF'),
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
                      child: const Text('VIEW TRIP DETAILS'),
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
                        cancelInFlight
                            ? 'STOPPING LOCATION'
                            : 'STOP LOCATION TRACKING',
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
                    child: const Text('PHONE LOCATION SETTINGS'),
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
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFFD8E0E3),
              minimumSize: const Size(94, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
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
                  : gpsEnabled
                  ? 'START'
                  : 'SET UP',
            ),
          ),
        ],
      ),
    );
  }
}

String _gpsSignalQualityMessage(
  TripTrackingSignalQuality quality,
) => switch (quality) {
  TripTrackingSignalQuality.reduced =>
    'GPS signal is reduced. Accepted distance remains advisory.',
  TripTrackingSignalQuality.poor =>
    'GPS signal is weak. Keep the trip and review its distance against the odometer.',
  TripTrackingSignalQuality.interrupted =>
    'GPS was interrupted. The gap is preserved for review rather than counted as a precise route.',
  TripTrackingSignalQuality.unsafe =>
    'GPS samples were rejected for safety. Confirmed odometer mileage remains official.',
  TripTrackingSignalQuality.noSamples =>
    'Waiting for a safe GPS location sample.',
  TripTrackingSignalQuality.healthy => 'GPS signal is healthy.',
};

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
