import '../odometer/live_odometer_display.dart';
import 'trip_live_odometer_payload_guard.dart';

enum TripTrackingLiveOdometerBroadcastStatus {
  inactive,
  renderable,
  staleReviewOnly,
  rejected,
}

class TripTrackingLiveOdometerBroadcast {
  const TripTrackingLiveOdometerBroadcast._({
    required this.status,
    required this.displayValue,
    required this.confirmedDisplayValue,
    required this.projectionRevision,
    required this.reasonCodes,
  });

  factory TripTrackingLiveOdometerBroadcast.fromSnapshot(
    LiveOdometerDisplaySnapshot snapshot, {
    required DateTime now,
    required String? activeTripId,
    required String expectedTripId,
    Duration maximumFutureSkew = const Duration(minutes: 2),
    int maximumLiveDeltaMiles = 2000,
    int maximumRenderableOdometer = 9999999,
    int? lastRenderedProjectionRevision,
  }) {
    final reasons = <String>[];
    final safeFutureSkew = _safeFutureSkew(maximumFutureSkew);
    final safeMaximumDelta = _safeMaximumDelta(maximumLiveDeltaMiles);
    final safeMaximumOdometer = _safeMaximumOdometer(maximumRenderableOdometer);
    if (!_safeTripId(expectedTripId)) reasons.add('unsafe_expected_trip_id');
    if (activeTripId != null && !_safeTripId(activeTripId)) {
      reasons.add('unsafe_active_trip_id');
    }
    if (snapshot.confirmedReading < 0) {
      reasons.add('negative_confirmed_reading');
    }
    if (snapshot.confirmedReading > safeMaximumOdometer ||
        snapshot.displayReading > safeMaximumOdometer) {
      reasons.add('odometer_display_out_of_range');
    }
    if (snapshot.displayReading < snapshot.confirmedReading) {
      reasons.add('display_below_confirmed_reading');
    }
    if (snapshot.projectionRevision < 0) {
      reasons.add('negative_projection_revision');
    }
    if (snapshot.isLive &&
        lastRenderedProjectionRevision != null &&
        lastRenderedProjectionRevision >= 0 &&
        snapshot.projectionRevision <= lastRenderedProjectionRevision) {
      reasons.add('projection_revision_not_newer');
    }
    if (snapshot.isLive && activeTripId != expectedTripId) {
      reasons.add('live_trip_id_mismatch');
    }
    if (snapshot.isLive && snapshot.liveUpdatedAt == null) {
      reasons.add('missing_live_update_time');
    }
    if (snapshot.isLive &&
        snapshot.liveUpdatedAt != null &&
        snapshot.liveUpdatedAt!.toUtc().isAfter(
          now.toUtc().add(safeFutureSkew),
        )) {
      reasons.add('live_update_time_in_future');
    }
    if (snapshot.isLive && snapshot.deltaMiles > safeMaximumDelta) {
      reasons.add('live_projection_delta_too_large');
    }
    if (reasons.isNotEmpty) {
      return TripTrackingLiveOdometerBroadcast._(
        status: TripTrackingLiveOdometerBroadcastStatus.rejected,
        displayValue: null,
        confirmedDisplayValue: null,
        projectionRevision: null,
        reasonCodes: List.unmodifiable(reasons),
      );
    }
    if (!snapshot.isLive) {
      return TripTrackingLiveOdometerBroadcast._(
        status: TripTrackingLiveOdometerBroadcastStatus.inactive,
        displayValue: snapshot.displayValue,
        confirmedDisplayValue: snapshot.confirmedDisplayValue,
        projectionRevision: snapshot.projectionRevision,
        reasonCodes: const ['confirmed_odometer_display'],
      );
    }
    return TripTrackingLiveOdometerBroadcast._(
      status: snapshot.isStaleAt(now)
          ? TripTrackingLiveOdometerBroadcastStatus.staleReviewOnly
          : TripTrackingLiveOdometerBroadcastStatus.renderable,
      displayValue: snapshot.displayValue,
      confirmedDisplayValue: snapshot.confirmedDisplayValue,
      projectionRevision: snapshot.projectionRevision,
      reasonCodes: [
        snapshot.isStaleAt(now)
            ? 'live_projection_stale_review_only'
            : 'live_projection_renderable',
      ],
    );
  }

  final TripTrackingLiveOdometerBroadcastStatus status;
  final String? displayValue;
  final String? confirmedDisplayValue;
  final int? projectionRevision;
  final List<String> reasonCodes;

  bool get shouldNotifyDashboard =>
      status == TripTrackingLiveOdometerBroadcastStatus.renderable ||
      status == TripTrackingLiveOdometerBroadcastStatus.staleReviewOnly ||
      status == TripTrackingLiveOdometerBroadcastStatus.inactive;

  bool get reviewRequired =>
      status == TripTrackingLiveOdometerBroadcastStatus.staleReviewOnly;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'displayValue': displayValue,
    'confirmedDisplayValue': confirmedDisplayValue,
    'projectionRevision': projectionRevision,
    'reasonCodes': reasonCodes,
    'shouldNotifyDashboard': shouldNotifyDashboard,
    'reviewRequired': reviewRequired,
    'futureProjectionBlocked': reasonCodes.contains(
      'live_update_time_in_future',
    ),
    'impossibleProjectionDeltaBlocked': reasonCodes.contains(
      'live_projection_delta_too_large',
    ),
    'odometerDisplayOutOfRangeBlocked': reasonCodes.contains(
      'odometer_display_out_of_range',
    ),
    'staleProjectionRevisionBlocked': reasonCodes.contains(
      'projection_revision_not_newer',
    ),
    'displayValueValidated': _displayValueSafe(displayValue),
    'confirmedDisplayValueValidated': _displayValueSafe(confirmedDisplayValue),
    'payloadGuard': TripLiveOdometerPayloadGuard.evaluate({
      'schemaVersion': 1,
      'advisoryOnly': true,
      'displayOnlyMileageSource': status.name == 'inactive'
          ? 'confirmed_odometer'
          : 'gps_assisted_projection',
      'confirmedOdometerRemainsCanonical': true,
      'odometerIsGlobalTruth': true,
      'physicalOdometerRequiredForOfficialMileage': true,
      'confirmedOdometerOverridesExternalMileage': true,
      'externalMileageCannotBecomeGlobalTruth': true,
      'gpsDistanceCanOnlyAdviseMileageReview': true,
      'mapMatchingCanOnlyAdviseMileageReview': true,
      'optimizationCannotChangeOfficialMileage': true,
      'displayProjectionIsNotOfficialMileage': true,
      'liveProjectionCanSetGlobalTruth': false,
      'liveProjectionCanConfirmOfficialMileage': false,
      'writesConfirmedOdometer': false,
      'gpsCanReplaceOdometer': false,
      'gpsCanSetGlobalTruth': false,
      'gpsCanChangeOfficialMileage': false,
      'mapboxCanReplaceOdometer': false,
      'mapboxCanSetGlobalTruth': false,
      'mapboxCanChangeOfficialMileage': false,
      'mapboxCanIncreaseLiveMileage': false,
      'staleProjectionCanCommitMileage': false,
      'staleProjectionCanNotifyAsFresh': false,
      'firestoreCanOverrideLiveDisplay': false,
      'remoteDisplayCanOverrideLocalTrip': false,
      'dashboardCacheCanOverrideLocalTrip': false,
      'importedDisplayCanOverrideLocalTrip': false,
      'authenticationDoesNotGrantDisplayAuthority': true,
      'matchingActiveTripRequired': true,
      'matchingVehicleProfileRequired': true,
      'projectionRevisionMustIncrease': true,
      'sameOrOlderProjectionRevisionCanNotify': false,
      'liveProjectionRequiresOwnershipValidation': true,
      'liveProjectionRequiresDeviceLocalSource': true,
      'projectionCannotOutliveActiveDay': true,
      'localTripLogProtected': true,
      'remoteProjectionCanReviveEndedTrip': false,
      'futureProjectionCanRender': false,
      'impossibleProjectionCanRender': false,
      'activeTripIdIncluded': false,
      'ownerUserIdIncluded': false,
      'rawGpsIncluded': false,
      'preciseLocationIncluded': false,
      'routeGeometryIncluded': false,
      'tokensIncluded': false,
    }).toSafeDashboardMap(),
    'globalOdometerScopeMustNotifyListeners': true,
    'liveUiMustRefreshOnProjectionChange': true,
    'singleLiveOdometerSnapshotRequired': true,
    'allDashboardSurfacesUseSameSnapshot': true,
    'allDashboardSurfacesUseSameProjectionRevision': true,
    'surfaceSpecificMileageCalculationAllowed': false,
    'activeVehicleBlockMustNotCacheProjection': true,
    'dashboardActiveVehicleBlockUsesLiveProjection': true,
    'activeVehicleBlockUsesLiveProjection': true,
    'vehicleProfileUsesLiveProjection': true,
    'contractorDashboardUsesLiveProjection': true,
    'fleetDashboardUsesLiveProjection': true,
    'standardDashboardUsesLiveProjection': true,
    'calendarReviewUsesConfirmedTruth': true,
    'crossDashboardLiveOdometerReady': true,
    'advisoryOnly': true,
    'displayOnlyMileageSource': status.name == 'inactive'
        ? 'confirmed_odometer'
        : 'gps_assisted_projection',
    'confirmedOdometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'displayProjectionIsNotOfficialMileage': true,
    'liveProjectionCanSetGlobalTruth': false,
    'liveProjectionCanConfirmOfficialMileage': false,
    'manualConfirmationRequired': status.name != 'inactive',
    'writesConfirmedOdometer': false,
    'gpsCanReplaceOdometer': false,
    'gpsCanSetGlobalTruth': false,
    'gpsCanChangeOfficialMileage': false,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanSetGlobalTruth': false,
    'mapboxCanChangeOfficialMileage': false,
    'mapboxCanIncreaseLiveMileage': false,
    'firestoreCanOverrideLiveDisplay': false,
    'remoteDisplayCanOverrideLocalTrip': false,
    'importedDisplayCanOverrideLocalTrip': false,
    'dashboardCacheCanOverrideLocalTrip': false,
    'authenticationDoesNotGrantDisplayAuthority': true,
    'matchingActiveTripRequired': true,
    'matchingVehicleProfileRequired': true,
    'projectionRevisionMustIncrease': true,
    'sameOrOlderProjectionRevisionCanNotify': false,
    'liveProjectionRequiresOwnershipValidation': true,
    'liveProjectionRequiresDeviceLocalSource': true,
    'projectionCannotOutliveActiveDay': true,
    'activeTripIdIncluded': false,
    'ownerUserIdIncluded': false,
    'staleProjectionCanCommitMileage': false,
    'staleProjectionCanNotifyAsFresh': false,
    'remoteProjectionCanReviveEndedTrip': false,
    'calibrationCanCommitWithoutReview': false,
    'calibrationCanDecreaseLiveProjection': false,
    'futureProjectionCanRender': false,
    'impossibleProjectionCanRender': false,
    'localTripLogProtected': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

bool _safeTripId(String value) =>
    value.trim() == value &&
    value.isNotEmpty &&
    value.length <= 160 &&
    !value.startsWith('pk.') &&
    !value.startsWith('sk.') &&
    !value.toLowerCase().contains('token') &&
    RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value);

Duration _safeFutureSkew(Duration value) {
  if (value <= Duration.zero) return Duration.zero;
  return value > const Duration(minutes: 10)
      ? const Duration(minutes: 10)
      : value;
}

int _safeMaximumDelta(int value) {
  if (value <= 0) return 1;
  return value > 10000 ? 10000 : value;
}

int _safeMaximumOdometer(int value) {
  if (value <= 0) return 9999999;
  return value > 9999999 ? 9999999 : value;
}

bool _displayValueSafe(String? value) =>
    value == null || RegExp(r'^(0|[1-9]\d{0,6})$').hasMatch(value);
