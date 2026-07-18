import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_status_rollup_policy.dart';

void main() {
  const normal = TripDashboardStatusRollupDecision(
    severity: TripDashboardStatusRollupSeverity.normal,
    primaryReasonCode: 'trip_dashboard_normal',
    startButtonEnabled: true,
    liveTimerVisible: true,
    liveOdometerProjectionVisible: true,
    stopReviewVisible: false,
    odometerReviewVisible: false,
    backupStatusVisible: false,
    routeStorageWarningVisible: false,
  );

  test('safe dashboard rollup summary validates as renderable', () {
    final validation = TripDashboardStatusRollupSummaryValidation.fromSummary(
      normal.toSafeDashboardMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.severity, TripDashboardStatusRollupSeverity.normal);
    expect(validation.reasons, isEmpty);
  });

  test('dashboard rollup cannot mutate trip truth or local data', () {
    final validation = TripDashboardStatusRollupSummaryValidation.fromSummary(
      normal.toSafeDashboardMap()..addAll({
        'dashboardRollupCanCreateOfficialStop': true,
        'dashboardRollupCanConfirmOdometer': true,
        'dashboardRollupCanDeleteLocalData': true,
        'dashboardRollupCanEndTripAutomatically': true,
        'dashboardRollupCanPurgeLocalDataAfterBackup': true,
        'dashboardRollupCanImportWithoutValidation': true,
        'remoteRollupCanOverrideLocalTrip': true,
        'firestoreMirrorOnly': false,
        'hiveRemainsOperationalSourceOfTruth': false,
        'odometerIsGlobalTruth': false,
        'odometerRemainsOfficialMileageTruth': false,
        'calibrationRequiresTrustedGpsWindow': false,
        'poorGpsDaysExcludedFromCalibration': false,
        'dashboardRollupCanApplyCalibration': true,
        'dashboardRollupCanCreateOfficialMileage': true,
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('rollup_can_mutate_trip_truth'));
    expect(validation.reasons, contains('rollup_truth_boundary_missing'));
  });

  test('dashboard rollup rejects maps-required and sensitive payloads', () {
    final validation = TripDashboardStatusRollupSummaryValidation.fromSummary(
      normal.toSafeDashboardMap()..addAll({
        'dashboardCanRunWithoutMaps': false,
        'mapsRequiredForTripDashboard': true,
        'dashboardWidgetsUserCustomizable': false,
        'activeVehicleGearControlsPageSettings': false,
        'rawTripRecordsIncluded': true,
        'preciseLocationIncluded': true,
        'routeGeometryIncluded': true,
        'tokensIncluded': true,
        'debug': 'sk.secret 35.123456,-80.123456',
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('dashboard_requires_maps'));
    expect(
      validation.reasons,
      contains('dashboard_customization_boundary_missing'),
    );
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_trip_material'),
    );
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });

  test('malformed dashboard rollup shape fails closed', () {
    final validation = TripDashboardStatusRollupSummaryValidation.fromSummary({
      'schemaVersion': 2,
      'severity': 'godMode',
      'primaryReasonCode': 'private_reason',
      'startButtonEnabled': 'yes',
      'liveTimerVisible': 1,
      'liveOdometerProjectionVisible': null,
      'stopReviewVisible': 'no',
      'odometerReviewVisible': 'no',
      'backupStatusVisible': 'no',
      'routeStorageWarningVisible': 'no',
    });

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('unsupported_schema_version'));
    expect(validation.reasons, contains('invalid_rollup_severity'));
    expect(validation.reasons, contains('startButtonEnabled_not_bool'));
    expect(validation.reasons, contains('liveTimerVisible_not_bool'));
  });
}
