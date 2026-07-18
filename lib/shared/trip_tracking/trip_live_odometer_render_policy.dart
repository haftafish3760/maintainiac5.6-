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
      'futureProjectionBlocked': reasonCodes.contains(
        'live_update_time_in_future',
      ),
      'impossibleProjectionDeltaBlocked': reasonCodes.contains(
        'live_projection_delta_too_large',
      ),
      'odometerDisplayOutOfRangeBlocked': reasonCodes.contains(
        'odometer_display_out_of_range',
      ),
      'displayValueValidated': _displayValueSafe(displayValue),
      'confirmedDisplayValueValidated': _displayValueSafe(
        confirmedDisplayValue,
      ),
      'liveUiMustRefreshOnProjectionChange': true,
      'singleLiveOdometerSnapshotRequired': true,
      'allDashboardSurfacesUseSameSnapshot': true,
      'allDashboardSurfacesUseSameProjectionRevision': true,
      'surfaceSpecificMileageCalculationAllowed': false,
      'activeVehicleBlockUsesLiveProjection': true,
      'activeVehicleBlockMustNotCacheProjection': true,
      'vehicleProfileUsesLiveProjection': true,
      'contractorDashboardUsesLiveProjection': true,
      'fleetDashboardUsesLiveProjection': true,
      'standardDashboardUsesLiveProjection': true,
      'calendarReviewUsesConfirmedTruth': true,
      'advisoryOnly': true,
      'confirmedOdometerRemainsCanonical': true,
      'odometerIsGlobalTruth': true,
      'physicalOdometerRequiredForOfficialMileage': true,
      'confirmedOdometerOverridesExternalMileage': true,
      'externalMileageCannotBecomeGlobalTruth': true,
      'gpsDistanceCanOnlyAdviseMileageReview': true,
      'mapMatchingCanOnlyAdviseMileageReview': true,
      'optimizationCannotChangeOfficialMileage': true,
      'manualConfirmationRequired':
          status != TripLiveOdometerRenderStatus.confirmedOnly,
      'writesConfirmedOdometer': false,
      'gpsCanReplaceOdometer': false,
      'mapboxCanReplaceOdometer': false,
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
      'singleSnapshotMustDriveEverySubscribedSurface': true,
      'surfaceSubscriptionRequiredForNotify': true,
      'blockedProjectionSuppressesNotify': true,
      'confirmedOnlyCanRenderWithoutActiveTrip': true,
      'liveProjectionCannotRenderWithoutMatchingTrip': true,
      'liveProjectionRequiresDeviceLocalSource': true,
      'liveProjectionRequiresOwnershipValidation': true,
      'projectionCannotOutliveActiveDay': true,
      'activeTripIdIncluded': false,
      'ownerUserIdIncluded': false,
      'surfaceSpecificTripIdsAllowed': false,
      'futureProjectionCanRender': false,
      'impossibleProjectionCanRender': false,
      'staleProjectionCanCommitMileage': false,
      'staleProjectionCanNotifyAsFresh': false,
      'remoteProjectionCanReviveEndedTrip': false,
      'calendarCanRewriteConfirmedTruth': false,
      'calibrationCanCommitWithoutReview': false,
      'calibrationCanDecreaseLiveProjection': false,
      'rawGpsIncluded': false,
      'preciseLocationIncluded': false,
      'routeGeometryIncluded': false,
      'tokensIncluded': false,
    };
  }
}

class TripLiveOdometerRenderSummaryValidation {
  const TripLiveOdometerRenderSummaryValidation._({
    required this.isRenderable,
    required this.shouldNotifyListeners,
    required this.reasons,
  });

  factory TripLiveOdometerRenderSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (!_allowedStatuses.contains(summary['status'])) {
      reasons.add('invalid_render_status');
    }
    final displayValue = summary['displayValue'];
    final confirmedDisplayValue = summary['confirmedDisplayValue'];
    if (displayValue != null && displayValue is! String) {
      reasons.add('display_value_not_string');
    } else if (!_displayValueSafe(displayValue as String?)) {
      reasons.add('invalid_display_value');
    }
    if (confirmedDisplayValue != null && confirmedDisplayValue is! String) {
      reasons.add('confirmed_display_value_not_string');
    } else if (!_displayValueSafe(confirmedDisplayValue as String?)) {
      reasons.add('invalid_confirmed_display_value');
    }
    final surfaces = summary['surfaces'];
    if (surfaces is! List ||
        surfaces.any((surface) => !_allowedSurfaces.contains(surface))) {
      reasons.add('invalid_render_surfaces');
    }
    final reasonCodes = summary['reasonCodes'];
    if (reasonCodes is! List ||
        reasonCodes.any((reason) => reason is! String || _sensitive(reason))) {
      reasons.add('invalid_render_reasons');
    }
    for (final key in const [
      'shouldRender',
      'shouldNotifyListeners',
      'reviewRequired',
      'futureProjectionBlocked',
      'impossibleProjectionDeltaBlocked',
      'odometerDisplayOutOfRangeBlocked',
      'displayValueValidated',
      'confirmedDisplayValueValidated',
      'liveUiMustRefreshOnProjectionChange',
      'singleLiveOdometerSnapshotRequired',
      'allDashboardSurfacesUseSameSnapshot',
      'allDashboardSurfacesUseSameProjectionRevision',
      'surfaceSpecificMileageCalculationAllowed',
      'activeVehicleBlockUsesLiveProjection',
      'activeVehicleBlockMustNotCacheProjection',
      'vehicleProfileUsesLiveProjection',
      'contractorDashboardUsesLiveProjection',
      'fleetDashboardUsesLiveProjection',
      'standardDashboardUsesLiveProjection',
      'calendarReviewUsesConfirmedTruth',
      'advisoryOnly',
      'confirmedOdometerRemainsCanonical',
      'odometerIsGlobalTruth',
      'physicalOdometerRequiredForOfficialMileage',
      'confirmedOdometerOverridesExternalMileage',
      'externalMileageCannotBecomeGlobalTruth',
      'gpsDistanceCanOnlyAdviseMileageReview',
      'mapMatchingCanOnlyAdviseMileageReview',
      'optimizationCannotChangeOfficialMileage',
      'manualConfirmationRequired',
      'writesConfirmedOdometer',
      'gpsCanReplaceOdometer',
      'mapboxCanReplaceOdometer',
      'mapboxCanIncreaseLiveMileage',
      'firestoreCanOverrideLiveDisplay',
      'remoteDisplayCanOverrideLocalTrip',
      'importedDisplayCanOverrideLocalTrip',
      'dashboardCacheCanOverrideLocalTrip',
      'authenticationDoesNotGrantDisplayAuthority',
      'matchingActiveTripRequired',
      'matchingVehicleProfileRequired',
      'projectionRevisionMustIncrease',
      'sameOrOlderProjectionRevisionCanNotify',
      'singleSnapshotMustDriveEverySubscribedSurface',
      'surfaceSubscriptionRequiredForNotify',
      'blockedProjectionSuppressesNotify',
      'confirmedOnlyCanRenderWithoutActiveTrip',
      'liveProjectionCannotRenderWithoutMatchingTrip',
      'liveProjectionRequiresDeviceLocalSource',
      'liveProjectionRequiresOwnershipValidation',
      'projectionCannotOutliveActiveDay',
      'activeTripIdIncluded',
      'ownerUserIdIncluded',
      'surfaceSpecificTripIdsAllowed',
      'futureProjectionCanRender',
      'impossibleProjectionCanRender',
      'staleProjectionCanCommitMileage',
      'staleProjectionCanNotifyAsFresh',
      'remoteProjectionCanReviveEndedTrip',
      'calendarCanRewriteConfirmedTruth',
      'calibrationCanCommitWithoutReview',
      'calibrationCanDecreaseLiveProjection',
      'rawGpsIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['displayValueValidated'] != true ||
        summary['confirmedDisplayValueValidated'] != true) {
      reasons.add('display_values_not_validated');
    }
    if (summary['singleLiveOdometerSnapshotRequired'] != true ||
        summary['allDashboardSurfacesUseSameSnapshot'] != true ||
        summary['allDashboardSurfacesUseSameProjectionRevision'] != true ||
        summary['singleSnapshotMustDriveEverySubscribedSurface'] != true ||
        summary['activeVehicleBlockMustNotCacheProjection'] != true ||
        summary['surfaceSpecificMileageCalculationAllowed'] != false ||
        summary['surfaceSpecificTripIdsAllowed'] != false) {
      reasons.add('single_snapshot_boundary_missing');
    }
    if (summary['writesConfirmedOdometer'] != false ||
        summary['gpsCanReplaceOdometer'] != false ||
        summary['mapboxCanReplaceOdometer'] != false ||
        summary['mapboxCanIncreaseLiveMileage'] != false ||
        summary['confirmedOdometerRemainsCanonical'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true ||
        summary['calendarCanRewriteConfirmedTruth'] != false ||
        summary['calibrationCanCommitWithoutReview'] != false ||
        summary['calibrationCanDecreaseLiveProjection'] != false ||
        summary['staleProjectionCanNotifyAsFresh'] != false) {
      reasons.add('odometer_truth_boundary_missing');
    }
    if (summary['firestoreCanOverrideLiveDisplay'] != false ||
        summary['remoteDisplayCanOverrideLocalTrip'] != false ||
        summary['importedDisplayCanOverrideLocalTrip'] != false ||
        summary['dashboardCacheCanOverrideLocalTrip'] != false ||
        summary['matchingVehicleProfileRequired'] != true ||
        summary['projectionRevisionMustIncrease'] != true ||
        summary['sameOrOlderProjectionRevisionCanNotify'] != false ||
        summary['authenticationDoesNotGrantDisplayAuthority'] != true) {
      reasons.add('remote_display_boundary_missing');
    }
    if (summary['activeTripIdIncluded'] != false ||
        summary['ownerUserIdIncluded'] != false ||
        summary['rawGpsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_sensitiveValue)) {
      reasons.add('summary_contains_sensitive_odometer_material');
    }
    return TripLiveOdometerRenderSummaryValidation._(
      isRenderable: reasons.isEmpty,
      shouldNotifyListeners:
          reasons.isEmpty && summary['shouldNotifyListeners'] == true,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final bool shouldNotifyListeners;
  final List<String> reasons;
}

bool _displayValueSafe(String? value) =>
    value == null || RegExp(r'^\d{7}$').hasMatch(value);

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

const _allowedStatuses = {
  'confirmedOnly',
  'liveRenderable',
  'staleReviewOnly',
  'blocked',
};

const _allowedSurfaces = {
  'dashboard',
  'activeVehicleBlock',
  'vehicleProfile',
  'contractorDashboard',
  'fleetDashboard',
  'calendarDayReview',
};

bool _sensitiveValue(Object? value) {
  if (value == null || value is bool || value is num) return false;
  if (value is Iterable) return value.any(_sensitiveValue);
  if (value is Map) return true;
  return _sensitive(value.toString());
}

bool _sensitive(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'tokensincluded' ||
      normalized == 'preciselocationincluded' ||
      normalized == 'routegeometryincluded') {
    return false;
  }
  return normalized.contains('pk.') ||
      normalized.contains('sk.') ||
      normalized.contains('token=') ||
      normalized.contains('latitude') ||
      normalized.contains('longitude') ||
      normalized.contains('geometry=') ||
      normalized.contains('polyline') ||
      normalized.contains('gps trace') ||
      RegExp(r'-?\d{2,3}\.\d{4,}\s*,\s*-?\d{2,3}\.\d{4,}').hasMatch(normalized);
}
