import '../odometer/live_odometer_display.dart';
import 'trip_tracking_live_odometer_broadcast.dart';

enum TripLiveOdometerRenderStatus {
  confirmedOnly,
  liveRenderable,
  staleReviewOnly,
  blocked,
}

enum TripLiveOdometerRenderSurface {
  dashboard,
  activeVehicleBlock,
  vehicleProfile,
  contractorDashboard,
  fleetDashboard,
  calendarDayReview,
}

class TripLiveOdometerRenderDecision {
  const TripLiveOdometerRenderDecision({
    required this.status,
    required this.broadcast,
    required this.surfaces,
    required this.displayValue,
    required this.confirmedDisplayValue,
    required this.reasonCodes,
  });

  final TripLiveOdometerRenderStatus status;
  final TripTrackingLiveOdometerBroadcast broadcast;
  final Set<TripLiveOdometerRenderSurface> surfaces;
  final String? displayValue;
  final String? confirmedDisplayValue;
  final List<String> reasonCodes;

  bool get shouldRender =>
      status == TripLiveOdometerRenderStatus.confirmedOnly ||
      status == TripLiveOdometerRenderStatus.liveRenderable ||
      status == TripLiveOdometerRenderStatus.staleReviewOnly;

  bool get shouldNotifyListeners => shouldRender && surfaces.isNotEmpty;

  bool get reviewRequired =>
      status == TripLiveOdometerRenderStatus.staleReviewOnly;

  Map<String, Object?> toSafeUiMap() {
    return {
      'schemaVersion': 1,
      'status': status.name,
      'displayValue': displayValue,
      'confirmedDisplayValue': confirmedDisplayValue,
      'surfaces': surfaces.map((surface) => surface.name).toList()..sort(),
      'reasonCodes': reasonCodes,
      'shouldRender': shouldRender,
      'shouldNotifyListeners': shouldNotifyListeners,
      'reviewRequired': reviewRequired,
      'liveUiMustRefreshOnProjectionChange': true,
      'allDashboardSurfacesUseSameSnapshot': true,
      'activeVehicleBlockUsesLiveProjection': true,
      'vehicleProfileUsesLiveProjection': true,
      'contractorDashboardUsesLiveProjection': true,
      'fleetDashboardUsesLiveProjection': true,
      'calendarReviewUsesConfirmedTruth': true,
      'advisoryOnly': true,
      'confirmedOdometerRemainsCanonical': true,
      'manualConfirmationRequired':
          status != TripLiveOdometerRenderStatus.confirmedOnly,
      'writesConfirmedOdometer': false,
      'gpsCanReplaceOdometer': false,
      'mapboxCanReplaceOdometer': false,
      'firestoreCanOverrideLiveDisplay': false,
      'remoteDisplayCanOverrideLocalTrip': false,
      'rawGpsIncluded': false,
      'preciseLocationIncluded': false,
      'routeGeometryIncluded': false,
      'tokensIncluded': false,
    };
  }
}

class TripLiveOdometerRenderPolicy {
  const TripLiveOdometerRenderPolicy._();

  static TripLiveOdometerRenderDecision evaluate({
    required LiveOdometerDisplaySnapshot snapshot,
    required DateTime now,
    required String? activeTripId,
    required String expectedTripId,
    required Iterable<TripLiveOdometerRenderSurface> subscribedSurfaces,
  }) {
    final broadcast = TripTrackingLiveOdometerBroadcast.fromSnapshot(
      snapshot,
      now: now,
      activeTripId: activeTripId,
      expectedTripId: expectedTripId,
    );
    final surfaces = _safeSurfaces(subscribedSurfaces);
    final status = _statusFor(broadcast);
    final renderable = status != TripLiveOdometerRenderStatus.blocked;
    return TripLiveOdometerRenderDecision(
      status: status,
      broadcast: broadcast,
      surfaces: renderable ? surfaces : const {},
      displayValue: renderable ? broadcast.displayValue : null,
      confirmedDisplayValue: renderable
          ? broadcast.confirmedDisplayValue
          : null,
      reasonCodes: List.unmodifiable([
        ...broadcast.reasonCodes,
        if (surfaces.isEmpty) 'no_dashboard_surface_subscribed',
        if (status == TripLiveOdometerRenderStatus.blocked)
          'live_odometer_render_blocked',
      ]),
    );
  }

  static TripLiveOdometerRenderStatus _statusFor(
    TripTrackingLiveOdometerBroadcast broadcast,
  ) {
    return switch (broadcast.status) {
      TripTrackingLiveOdometerBroadcastStatus.inactive =>
        TripLiveOdometerRenderStatus.confirmedOnly,
      TripTrackingLiveOdometerBroadcastStatus.renderable =>
        TripLiveOdometerRenderStatus.liveRenderable,
      TripTrackingLiveOdometerBroadcastStatus.staleReviewOnly =>
        TripLiveOdometerRenderStatus.staleReviewOnly,
      TripTrackingLiveOdometerBroadcastStatus.rejected =>
        TripLiveOdometerRenderStatus.blocked,
    };
  }
}

Set<TripLiveOdometerRenderSurface> _safeSurfaces(
  Iterable<TripLiveOdometerRenderSurface> surfaces,
) {
  return surfaces
      .where(
        (surface) =>
            surface == TripLiveOdometerRenderSurface.dashboard ||
            surface == TripLiveOdometerRenderSurface.activeVehicleBlock ||
            surface == TripLiveOdometerRenderSurface.vehicleProfile ||
            surface == TripLiveOdometerRenderSurface.contractorDashboard ||
            surface == TripLiveOdometerRenderSurface.fleetDashboard ||
            surface == TripLiveOdometerRenderSurface.calendarDayReview,
      )
      .toSet();
}
