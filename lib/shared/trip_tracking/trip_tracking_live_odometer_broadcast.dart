import '../odometer/live_odometer_display.dart';

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
  }) {
    final reasons = <String>[];
    if (!_safeTripId(expectedTripId)) reasons.add('unsafe_expected_trip_id');
    if (activeTripId != null && !_safeTripId(activeTripId)) {
      reasons.add('unsafe_active_trip_id');
    }
    if (snapshot.confirmedReading < 0) {
      reasons.add('negative_confirmed_reading');
    }
    if (snapshot.displayReading < snapshot.confirmedReading) {
      reasons.add('display_below_confirmed_reading');
    }
    if (snapshot.projectionRevision < 0) {
      reasons.add('negative_projection_revision');
    }
    if (snapshot.isLive && activeTripId != expectedTripId) {
      reasons.add('live_trip_id_mismatch');
    }
    if (snapshot.isLive && snapshot.liveUpdatedAt == null) {
      reasons.add('missing_live_update_time');
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
    'globalOdometerScopeMustNotifyListeners': true,
    'dashboardActiveVehicleBlockUsesLiveProjection': true,
    'contractorDashboardUsesLiveProjection': true,
    'crossDashboardLiveOdometerReady': true,
    'advisoryOnly': true,
    'displayOnlyMileageSource': status.name == 'inactive'
        ? 'confirmed_odometer'
        : 'gps_assisted_projection',
    'confirmedOdometerRemainsCanonical': true,
    'manualConfirmationRequired': status.name != 'inactive',
    'writesConfirmedOdometer': false,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'firestoreCanOverrideLiveDisplay': false,
    'remoteDisplayCanOverrideLocalTrip': false,
    'staleProjectionCanCommitMileage': false,
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
    RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value);
