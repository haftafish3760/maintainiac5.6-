import 'trip_active_day_timer_policy.dart';
import 'trip_live_checkpoint_durability_policy.dart';
import 'trip_odometer_end_review_policy.dart';
import 'trip_sample_window_quality_policy.dart';
import 'trip_stop_debounce_policy.dart';

enum TripDashboardStatusRollupSeverity { normal, attention, blocked }

class TripDashboardStatusRollupDecision {
  const TripDashboardStatusRollupDecision({
    required this.severity,
    required this.primaryReasonCode,
    required this.startButtonEnabled,
    required this.liveTimerVisible,
    required this.liveOdometerProjectionVisible,
    required this.stopReviewVisible,
    required this.odometerReviewVisible,
    required this.backupStatusVisible,
    required this.routeStorageWarningVisible,
  });

  final TripDashboardStatusRollupSeverity severity;
  final String primaryReasonCode;
  final bool startButtonEnabled;
  final bool liveTimerVisible;
  final bool liveOdometerProjectionVisible;
  final bool stopReviewVisible;
  final bool odometerReviewVisible;
  final bool backupStatusVisible;
  final bool routeStorageWarningVisible;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'severity': severity.name,
    'primaryReasonCode': _safeReason(primaryReasonCode),
    'startButtonEnabled': startButtonEnabled,
    'liveTimerVisible': liveTimerVisible,
    'liveOdometerProjectionVisible': liveOdometerProjectionVisible,
    'stopReviewVisible': stopReviewVisible,
    'odometerReviewVisible': odometerReviewVisible,
    'backupStatusVisible': backupStatusVisible,
    'routeStorageWarningVisible': routeStorageWarningVisible,
    'dashboardCanRunWithoutMaps': true,
    'mapsRequiredForTripDashboard': false,
    'dashboardRollupCanCreateOfficialStop': false,
    'dashboardRollupCanConfirmOdometer': false,
    'dashboardRollupCanSetGlobalTruth': false,
    'dashboardRollupCanChangeOfficialMileage': false,
    'dashboardRollupCanDeleteLocalData': false,
    'dashboardRollupCanEndTripAutomatically': false,
    'dashboardRollupCanPurgeLocalDataAfterBackup': false,
    'dashboardRollupCanImportWithoutValidation': false,
    'dashboardRollupRequiresLocalTripLog': true,
    'dashboardRollupRequiresOwnershipValidation': true,
    'authenticationAloneAuthorizesRollupAccess': false,
    'importedRollupCanOpenSensitiveReview': false,
    'dashboardWidgetsUserCustomizable': true,
    'activeVehicleGearControlsPageSettings': true,
    'remoteRollupCanOverrideLocalTrip': false,
    'firestoreMirrorOnly': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'dashboardRollupCanApplyCalibration': false,
    'dashboardRollupCanCreateOfficialMileage': false,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripDashboardStatusRollupSummaryValidation {
  const TripDashboardStatusRollupSummaryValidation._({
    required this.isRenderable,
    required this.severity,
    required this.reasons,
  });

  factory TripDashboardStatusRollupSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final severity = _safeSeverity(summary['severity']);
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (severity == null) reasons.add('invalid_rollup_severity');
    if (_safeReasonObject(summary['primaryReasonCode']) == null) {
      reasons.add('invalid_rollup_reason');
    }
    for (final key in const [
      'startButtonEnabled',
      'liveTimerVisible',
      'liveOdometerProjectionVisible',
      'stopReviewVisible',
      'odometerReviewVisible',
      'backupStatusVisible',
      'routeStorageWarningVisible',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['dashboardCanRunWithoutMaps'] != true ||
        summary['mapsRequiredForTripDashboard'] != false) {
      reasons.add('dashboard_requires_maps');
    }
    if (summary['dashboardRollupCanCreateOfficialStop'] != false ||
        summary['dashboardRollupCanConfirmOdometer'] != false ||
        summary['dashboardRollupCanSetGlobalTruth'] != false ||
        summary['dashboardRollupCanChangeOfficialMileage'] != false ||
        summary['dashboardRollupCanDeleteLocalData'] != false ||
        summary['dashboardRollupCanEndTripAutomatically'] != false ||
        summary['dashboardRollupCanPurgeLocalDataAfterBackup'] != false ||
        summary['dashboardRollupCanImportWithoutValidation'] != false ||
        summary['importedRollupCanOpenSensitiveReview'] != false) {
      reasons.add('rollup_can_mutate_trip_truth');
    }
    if (summary['dashboardRollupRequiresLocalTripLog'] != true ||
        summary['dashboardRollupRequiresOwnershipValidation'] != true ||
        summary['authenticationAloneAuthorizesRollupAccess'] != false) {
      reasons.add('rollup_authorization_boundary_missing');
    }
    if (summary['remoteRollupCanOverrideLocalTrip'] != false ||
        summary['firestoreMirrorOnly'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['dashboardRollupCanApplyCalibration'] != false ||
        summary['dashboardRollupCanCreateOfficialMileage'] != false ||
        summary['dashboardRollupCanSetGlobalTruth'] != false ||
        summary['dashboardRollupCanChangeOfficialMileage'] != false) {
      reasons.add('rollup_truth_boundary_missing');
    }
    if (summary['dashboardWidgetsUserCustomizable'] != true ||
        summary['activeVehicleGearControlsPageSettings'] != true) {
      reasons.add('dashboard_customization_boundary_missing');
    }
    if (summary['rawTripRecordsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_trip_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripDashboardStatusRollupSummaryValidation._(
      isRenderable: reasons.isEmpty,
      severity: reasons.isEmpty ? severity : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripDashboardStatusRollupSeverity? severity;
  final List<String> reasons;
}

class TripDashboardStatusRollupPolicy {
  const TripDashboardStatusRollupPolicy._();

  static TripDashboardStatusRollupDecision evaluate({
    required TripActiveDayTimerDecision timer,
    required TripStopDebounceDecision stopDebounce,
    required TripOdometerEndReviewDecision odometerReview,
    required TripLiveCheckpointDurabilityDecision checkpoint,
    required TripSampleWindowQualityDecision sampleWindow,
    required bool gpsAssistedTrackingEnabled,
  }) {
    if (!gpsAssistedTrackingEnabled) {
      return _rollup(
        severity: TripDashboardStatusRollupSeverity.normal,
        primaryReasonCode: 'gps_assist_disabled',
        startButtonEnabled: true,
        liveTimerVisible: false,
        liveOdometerProjectionVisible: false,
        stopReviewVisible: false,
        odometerReviewVisible: false,
        backupStatusVisible: false,
        routeStorageWarningVisible: false,
      );
    }

    if (odometerReview.status ==
            TripOdometerEndReviewStatus.blockedInvalidEntry ||
        checkpoint.status ==
            TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint ||
        sampleWindow.status == TripSampleWindowQualityStatus.unsafeRejected ||
        timer.status == TripActiveDayTimerStatus.invalidClock) {
      return _rollup(
        severity: TripDashboardStatusRollupSeverity.blocked,
        primaryReasonCode: _blockedReason(
          timer,
          odometerReview,
          checkpoint,
          sampleWindow,
        ),
        startButtonEnabled: false,
        liveTimerVisible: timer.status != TripActiveDayTimerStatus.notStarted,
        liveOdometerProjectionVisible: false,
        stopReviewVisible: false,
        odometerReviewVisible: true,
        backupStatusVisible: true,
        routeStorageWarningVisible:
            sampleWindow.status == TripSampleWindowQualityStatus.unsafeRejected,
      );
    }

    final needsAttention =
        timer.requiresUserReview ||
        stopDebounce.canOpenReview ||
        odometerReview.shouldShowReviewBeforeConfirm ||
        checkpoint.status ==
            TripLiveCheckpointDurabilityStatus.backupDeferred ||
        sampleWindow.status ==
            TripSampleWindowQualityStatus.routeStoragePaused ||
        sampleWindow.status ==
            TripSampleWindowQualityStatus.degradedTrackingOnly;

    return _rollup(
      severity: needsAttention
          ? TripDashboardStatusRollupSeverity.attention
          : TripDashboardStatusRollupSeverity.normal,
      primaryReasonCode: needsAttention
          ? _attentionReason(
              timer,
              stopDebounce,
              odometerReview,
              checkpoint,
              sampleWindow,
            )
          : 'trip_dashboard_normal',
      startButtonEnabled: true,
      liveTimerVisible:
          timer.shouldTickLive ||
          timer.status == TripActiveDayTimerStatus.paused,
      liveOdometerProjectionVisible: sampleWindow.canFeedLiveOdometerProjection,
      stopReviewVisible: stopDebounce.canOpenReview,
      odometerReviewVisible: odometerReview.shouldShowReviewBeforeConfirm,
      backupStatusVisible:
          checkpoint.status != TripLiveCheckpointDurabilityStatus.backupReady,
      routeStorageWarningVisible:
          sampleWindow.status ==
          TripSampleWindowQualityStatus.routeStoragePaused,
    );
  }
}

TripDashboardStatusRollupDecision _rollup({
  required TripDashboardStatusRollupSeverity severity,
  required String primaryReasonCode,
  required bool startButtonEnabled,
  required bool liveTimerVisible,
  required bool liveOdometerProjectionVisible,
  required bool stopReviewVisible,
  required bool odometerReviewVisible,
  required bool backupStatusVisible,
  required bool routeStorageWarningVisible,
}) {
  return TripDashboardStatusRollupDecision(
    severity: severity,
    primaryReasonCode: _safeReason(primaryReasonCode),
    startButtonEnabled: startButtonEnabled,
    liveTimerVisible: liveTimerVisible,
    liveOdometerProjectionVisible: liveOdometerProjectionVisible,
    stopReviewVisible: stopReviewVisible,
    odometerReviewVisible: odometerReviewVisible,
    backupStatusVisible: backupStatusVisible,
    routeStorageWarningVisible: routeStorageWarningVisible,
  );
}

String _blockedReason(
  TripActiveDayTimerDecision timer,
  TripOdometerEndReviewDecision odometer,
  TripLiveCheckpointDurabilityDecision checkpoint,
  TripSampleWindowQualityDecision sampleWindow,
) {
  if (timer.status == TripActiveDayTimerStatus.invalidClock) {
    return 'timer_clock_invalid';
  }
  if (odometer.status == TripOdometerEndReviewStatus.blockedInvalidEntry) {
    return 'odometer_review_blocked';
  }
  if (checkpoint.status ==
      TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint) {
    return 'checkpoint_blocked';
  }
  if (sampleWindow.status == TripSampleWindowQualityStatus.unsafeRejected) {
    return 'sample_window_blocked';
  }
  return 'trip_dashboard_blocked';
}

String _attentionReason(
  TripActiveDayTimerDecision timer,
  TripStopDebounceDecision stopDebounce,
  TripOdometerEndReviewDecision odometer,
  TripLiveCheckpointDurabilityDecision checkpoint,
  TripSampleWindowQualityDecision sampleWindow,
) {
  if (stopDebounce.canOpenReview) return 'stop_review_available';
  if (odometer.shouldShowReviewBeforeConfirm) return 'odometer_review_needed';
  if (timer.requiresUserReview) return 'timer_review_needed';
  if (checkpoint.status == TripLiveCheckpointDurabilityStatus.backupDeferred) {
    return 'backup_deferred';
  }
  if (sampleWindow.status == TripSampleWindowQualityStatus.routeStoragePaused) {
    return 'route_storage_paused';
  }
  if (sampleWindow.status ==
      TripSampleWindowQualityStatus.degradedTrackingOnly) {
    return 'sample_window_degraded';
  }
  return 'trip_dashboard_normal';
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'gps_assist_disabled' => 'gps_assist_disabled',
    'timer_clock_invalid' => 'timer_clock_invalid',
    'odometer_review_blocked' => 'odometer_review_blocked',
    'checkpoint_blocked' => 'checkpoint_blocked',
    'sample_window_blocked' => 'sample_window_blocked',
    'trip_dashboard_blocked' => 'trip_dashboard_blocked',
    'stop_review_available' => 'stop_review_available',
    'odometer_review_needed' => 'odometer_review_needed',
    'timer_review_needed' => 'timer_review_needed',
    'backup_deferred' => 'backup_deferred',
    'route_storage_paused' => 'route_storage_paused',
    'sample_window_degraded' => 'sample_window_degraded',
    'trip_dashboard_normal' => 'trip_dashboard_normal',
    _ => 'trip_dashboard_blocked',
  };
}

TripDashboardStatusRollupSeverity? _safeSeverity(Object? value) {
  if (value is! String) return null;
  for (final severity in TripDashboardStatusRollupSeverity.values) {
    if (severity.name == value) return severity;
  }
  return null;
}

String? _safeReasonObject(Object? value) {
  if (value is! String) return null;
  return _safeReason(value);
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
