import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_active_day_timer_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_status_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_checkpoint_durability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_calibration_prompt_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_end_review_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sample_window_quality_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_evidence_digest.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_walking_evidence_recency_guard.dart';

void main() {
  const timer = TripActiveDayTimerDecision(
    status: TripActiveDayTimerStatus.running,
    elapsed: Duration(hours: 2),
    reasonCode: 'timer_running_from_local_checkpoint',
    shouldTickLive: true,
    requiresUserReview: false,
  );
  const evidenceDigest = TripStopDebounceEvidenceDigest(
    profile: TripTrackingProfile.deliveryVehicle,
    acceptedDistanceCount: 3,
    rejectedDriftCount: 0,
    rejectedUnsafeCount: 0,
    walkingEvidenceCount: 0,
    stationaryDuration: Duration.zero,
    walkingEvidenceSpan: Duration.zero,
    minimumStationary: Duration(minutes: 2),
    minimumWalkingEvidenceSpacing: Duration(seconds: 20),
    acceptedVehicleMovementObserved: true,
    providerValuesUsable: true,
    walkingBurstProtected: false,
    walkingEvidenceCurrent: true,
    walkingEvidenceRecency: TripWalkingEvidenceRecencyDecision(
      usable: true,
      reasonCode: 'no_walking_evidence',
      walkingEvidenceCount: 0,
      walkingEvidenceSpan: Duration.zero,
      latestEvidenceAge: null,
      maximumEvidenceAge: Duration(minutes: 10),
    ),
  );
  const stop = TripStopDebounceDecision(
    status: TripStopDebounceStatus.keepTracking,
    profile: TripTrackingProfile.deliveryVehicle,
    classification: TripStopClassification(
      signal: TripStopSignal.noStop,
      reviewConfidence: TripStopReviewConfidence.none,
      reasonCode: 'no_stop_review_needed',
      requiresUserReview: false,
      canSuggestStop: false,
      shouldSurfaceManualStopFallback: false,
      actionToken: 'keep_tracking',
      dashboardMessage: 'No stop review is needed right now.',
    ),
    reasonCode: 'stop_debounce_keep_tracking',
    evidenceDigest: evidenceDigest,
    needsWalkingReview: false,
    protectedTrafficControl: false,
    shouldContinueSampling: true,
    canOpenReview: false,
  );
  const odometer = TripOdometerEndReviewDecision(
    status: TripOdometerEndReviewStatus.readyToConfirm,
    reasonCode: 'odometer_ready_to_confirm',
    entryValidation: TripOdometerEntryValidation(
      status: TripOdometerEntryValidationStatus.valid,
      startingOdometer: 1000,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1000,
      deltaMiles: 120,
      reasonCode: 'odometer_entry_validated',
    ),
    reconciliation: TripOdometerReconciliation(
      status: TripOdometerReconciliationStatus.aligned,
      confirmedOdometerDeltaMiles: 120,
      filteredGpsMiles: 118,
      absoluteDifferenceMiles: 2,
      differencePercent: 1.7,
    ),
    calibrationPrompt: TripOdometerCalibrationPromptDecision(
      surface: TripOdometerCalibrationPromptSurface.hidden,
      reason: TripOdometerCalibrationPromptReason.noPromptNeeded,
      shouldShow: false,
      canApplyAutomatically: false,
      canSnooze: false,
      canDisable: true,
      messageToken: 'calibration_stable',
    ),
    canConfirmOdometer: true,
    shouldShowReviewBeforeConfirm: false,
  );
  const checkpoint = TripLiveCheckpointDurabilityDecision(
    status: TripLiveCheckpointDurabilityStatus.backupReady,
    reasonCode: 'local_checkpoint_written_backup_ready',
    shouldWriteLocalCheckpointNow: false,
    mayUploadBackupMirror: true,
    shouldRetryBackupLater: false,
    minimumNextLocalWriteSeconds: 0,
  );
  const samples = TripSampleWindowQualityDecision(
    status: TripSampleWindowQualityStatus.usableForTracking,
    reasonCode: 'sample_window_usable',
    validSampleCount: 3,
    rejectedSampleCount: 0,
    acceptedSegmentCount: 2,
    rejectedGapSegmentCount: 0,
    rejectedJumpSegmentCount: 0,
    rejectedSpeedSegmentCount: 0,
    maximumConsecutiveRejectedSegments: 0,
    acceptedDistanceMeters: 120,
    maximumGapSeconds: 15,
    canFeedLiveOdometerProjection: true,
    canPersistCompactRoutePoint: true,
  );

  test('normal rollup shows live timer and odometer projection', () {
    final decision = TripDashboardStatusRollupPolicy.evaluate(
      timer: timer,
      stopDebounce: stop,
      odometerReview: odometer,
      checkpoint: checkpoint,
      sampleWindow: samples,
      gpsAssistedTrackingEnabled: true,
    );

    expect(decision.severity, TripDashboardStatusRollupSeverity.normal);
    expect(decision.liveTimerVisible, isTrue);
    expect(decision.liveOdometerProjectionVisible, isTrue);
    expect(decision.stopReviewVisible, isFalse);
  });

  test('GPS disabled keeps start button available without map dependency', () {
    final safe = TripDashboardStatusRollupPolicy.evaluate(
      timer: timer,
      stopDebounce: stop,
      odometerReview: odometer,
      checkpoint: checkpoint,
      sampleWindow: samples,
      gpsAssistedTrackingEnabled: false,
    ).toSafeDashboardMap();

    expect(safe['startButtonEnabled'], isTrue);
    expect(safe['liveTimerVisible'], isFalse);
    expect(safe['mapsRequiredForTripDashboard'], isFalse);
    expect(safe['dashboardRollupRequiresLocalTripLog'], isTrue);
    expect(safe['dashboardRollupRequiresOwnershipValidation'], isTrue);
    expect(safe['authenticationAloneAuthorizesRollupAccess'], isFalse);
  });

  test('stop review gets attention without creating official stop', () {
    const reviewStop = TripStopDebounceDecision(
      status: TripStopDebounceStatus.readyForReview,
      profile: TripTrackingProfile.deliveryVehicle,
      classification: TripStopClassification(
        signal: TripStopSignal.reviewOnlyStop,
        reviewConfidence: TripStopReviewConfidence.high,
        reasonCode: 'delivery_stop_walk_review',
        requiresUserReview: true,
        canSuggestStop: true,
        shouldSurfaceManualStopFallback: true,
        actionToken: 'review_delivery_stop',
        dashboardMessage:
            'Walking evidence suggests a pickup or dropoff stop. Review it before it becomes official.',
      ),
      reasonCode: 'walking_stop_debounce_ready',
      evidenceDigest: TripStopDebounceEvidenceDigest(
        profile: TripTrackingProfile.deliveryVehicle,
        acceptedDistanceCount: 2,
        rejectedDriftCount: 0,
        rejectedUnsafeCount: 0,
        walkingEvidenceCount: 3,
        stationaryDuration: Duration(minutes: 3),
        walkingEvidenceSpan: Duration(minutes: 1),
        minimumStationary: Duration(minutes: 2),
        minimumWalkingEvidenceSpacing: Duration(seconds: 20),
        acceptedVehicleMovementObserved: true,
        providerValuesUsable: true,
        walkingBurstProtected: false,
        walkingEvidenceCurrent: true,
        walkingEvidenceRecency: TripWalkingEvidenceRecencyDecision(
          usable: true,
          reasonCode: 'walking_evidence_current',
          walkingEvidenceCount: 3,
          walkingEvidenceSpan: Duration(minutes: 1),
          latestEvidenceAge: Duration(seconds: 20),
          maximumEvidenceAge: Duration(minutes: 10),
        ),
      ),
      needsWalkingReview: true,
      protectedTrafficControl: false,
      shouldContinueSampling: false,
      canOpenReview: true,
    );
    final safe = TripDashboardStatusRollupPolicy.evaluate(
      timer: timer,
      stopDebounce: reviewStop,
      odometerReview: odometer,
      checkpoint: checkpoint,
      sampleWindow: samples,
      gpsAssistedTrackingEnabled: true,
    ).toSafeDashboardMap();

    expect(safe['severity'], TripDashboardStatusRollupSeverity.attention.name);
    expect(safe['primaryReasonCode'], 'stop_review_available');
    expect(safe['dashboardRollupCanCreateOfficialStop'], isFalse);
  });

  test('blocked odometer hides live projection and disables start action', () {
    const blockedOdometer = TripOdometerEndReviewDecision(
      status: TripOdometerEndReviewStatus.blockedInvalidEntry,
      reasonCode: 'ending_odometer_below_starting_odometer',
      entryValidation: TripOdometerEntryValidation(
        status: TripOdometerEntryValidationStatus.invalid,
        startingOdometer: 1120,
        endingOdometer: 1110,
        previousConfirmedEndingOdometer: 1000,
        deltaMiles: 0,
        reasonCode: 'ending_odometer_below_starting_odometer',
      ),
      reconciliation: TripOdometerReconciliation(
        status: TripOdometerReconciliationStatus.aligned,
        confirmedOdometerDeltaMiles: 0,
        filteredGpsMiles: 0,
        absoluteDifferenceMiles: 0,
        differencePercent: 0,
      ),
      calibrationPrompt: TripOdometerCalibrationPromptDecision(
        surface: TripOdometerCalibrationPromptSurface.hidden,
        reason: TripOdometerCalibrationPromptReason.noPromptNeeded,
        shouldShow: false,
        canApplyAutomatically: false,
        canSnooze: false,
        canDisable: true,
        messageToken: 'calibration_stable',
      ),
      canConfirmOdometer: false,
      shouldShowReviewBeforeConfirm: true,
    );
    final decision = TripDashboardStatusRollupPolicy.evaluate(
      timer: timer,
      stopDebounce: stop,
      odometerReview: blockedOdometer,
      checkpoint: checkpoint,
      sampleWindow: samples,
      gpsAssistedTrackingEnabled: true,
    );

    expect(decision.severity, TripDashboardStatusRollupSeverity.blocked);
    expect(decision.startButtonEnabled, isFalse);
    expect(decision.liveOdometerProjectionVisible, isFalse);
    expect(decision.odometerReviewVisible, isTrue);
  });

  test('backup deferral and route storage pause surface attention only', () {
    const backupDeferred = TripLiveCheckpointDurabilityDecision(
      status: TripLiveCheckpointDurabilityStatus.backupDeferred,
      reasonCode: 'sync_attempt_not_ready',
      shouldWriteLocalCheckpointNow: false,
      mayUploadBackupMirror: false,
      shouldRetryBackupLater: false,
      minimumNextLocalWriteSeconds: 0,
    );
    const pausedSamples = TripSampleWindowQualityDecision(
      status: TripSampleWindowQualityStatus.routeStoragePaused,
      reasonCode: 'route_storage_budget_paused',
      validSampleCount: 3,
      rejectedSampleCount: 0,
      acceptedSegmentCount: 2,
      rejectedGapSegmentCount: 0,
      rejectedJumpSegmentCount: 0,
      rejectedSpeedSegmentCount: 0,
      maximumConsecutiveRejectedSegments: 0,
      acceptedDistanceMeters: 120,
      maximumGapSeconds: 15,
      canFeedLiveOdometerProjection: true,
      canPersistCompactRoutePoint: false,
    );
    final decision = TripDashboardStatusRollupPolicy.evaluate(
      timer: timer,
      stopDebounce: stop,
      odometerReview: odometer,
      checkpoint: backupDeferred,
      sampleWindow: pausedSamples,
      gpsAssistedTrackingEnabled: true,
    );

    expect(decision.severity, TripDashboardStatusRollupSeverity.attention);
    expect(decision.backupStatusVisible, isTrue);
    expect(decision.routeStorageWarningVisible, isTrue);
    expect(decision.liveOdometerProjectionVisible, isTrue);
  });

  test(
    'safe rollup never exposes raw trip, location, route, or token data',
    () {
      final safe = TripDashboardStatusRollupPolicy.evaluate(
        timer: timer,
        stopDebounce: stop,
        odometerReview: odometer,
        checkpoint: checkpoint,
        sampleWindow: samples,
        gpsAssistedTrackingEnabled: true,
      ).toSafeDashboardMap();

      expect(safe['dashboardRollupCanConfirmOdometer'], isFalse);
      expect(safe['importedRollupCanOpenSensitiveReview'], isFalse);
      expect(safe['dashboardRollupRequiresLocalTripLog'], isTrue);
      expect(safe['dashboardRollupRequiresOwnershipValidation'], isTrue);
      expect(safe['authenticationAloneAuthorizesRollupAccess'], isFalse);
      expect(safe['remoteRollupCanOverrideLocalTrip'], isFalse);
      expect(safe['rawTripRecordsIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['routeGeometryIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );

  test(
    'rollup validation rejects missing local trip and ownership boundary',
    () {
      final summary =
          TripDashboardStatusRollupPolicy.evaluate(
            timer: timer,
            stopDebounce: stop,
            odometerReview: odometer,
            checkpoint: checkpoint,
            sampleWindow: samples,
            gpsAssistedTrackingEnabled: true,
          ).toSafeDashboardMap()..addAll({
            'dashboardRollupRequiresLocalTripLog': false,
            'dashboardRollupRequiresOwnershipValidation': false,
            'authenticationAloneAuthorizesRollupAccess': true,
          });

      final validation = TripDashboardStatusRollupSummaryValidation.fromSummary(
        summary,
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('rollup_authorization_boundary_missing'),
      );
    },
  );

  test('rollup validation rejects imported review or mutation authority', () {
    final summary =
        TripDashboardStatusRollupPolicy.evaluate(
          timer: timer,
          stopDebounce: stop,
          odometerReview: odometer,
          checkpoint: checkpoint,
          sampleWindow: samples,
          gpsAssistedTrackingEnabled: true,
        ).toSafeDashboardMap()..addAll({
          'importedRollupCanOpenSensitiveReview': true,
          'dashboardRollupCanCreateOfficialStop': true,
        });

    final validation = TripDashboardStatusRollupSummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('rollup_can_mutate_trip_truth'));
  });
}
