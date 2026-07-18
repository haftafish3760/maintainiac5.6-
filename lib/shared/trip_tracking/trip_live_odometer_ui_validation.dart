import 'trip_live_odometer_render_policy.dart';
import 'trip_live_odometer_payload_guard.dart';
import 'trip_tracking_live_odometer_broadcast.dart';

/// Validates live-odometer UI payloads before widgets render them.
///
/// This is intentionally display-only. A live GPS-assisted projection can make
/// dashboard odometer text repaint, but it cannot commit official mileage,
/// bypass trip ownership, or carry raw location/history data.
class TripLiveOdometerUiValidation {
  const TripLiveOdometerUiValidation._({
    required this.isRenderable,
    required this.status,
    required this.displayValue,
    required this.reasons,
  });

  factory TripLiveOdometerUiValidation.fromBroadcastMap(
    Map<String, Object?> payload,
  ) {
    final reasons = <String>[];
    final status = _safeBroadcastStatus(payload['status']);
    reasons.addAll(
      _validateSharedPayload(
        payload,
        statusName: status?.name,
        requirePayloadGuard: true,
        acceptedStatusNames: TripTrackingLiveOdometerBroadcastStatus.values
            .map((status) => status.name)
            .toSet(),
      ),
    );
    if (status == null) reasons.add('invalid_live_broadcast_status');
    if (payload['shouldNotifyDashboard'] is! bool) {
      reasons.add('invalid_dashboard_notify_flag');
    }
    if (payload['reviewRequired'] is! bool) {
      reasons.add('invalid_review_required_flag');
    }

    return TripLiveOdometerUiValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status?.name : null,
      displayValue: reasons.isEmpty ? payload['displayValue'] as String? : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  factory TripLiveOdometerUiValidation.fromRenderMap(
    Map<String, Object?> payload,
  ) {
    final reasons = <String>[];
    final status = _safeRenderStatus(payload['status']);
    reasons.addAll(
      _validateSharedPayload(
        payload,
        statusName: status?.name,
        requirePayloadGuard: false,
        acceptedStatusNames: TripLiveOdometerRenderStatus.values
            .map((status) => status.name)
            .toSet(),
      ),
    );
    if (status == null) reasons.add('invalid_live_render_status');
    if (payload['shouldRender'] is! bool) reasons.add('invalid_render_flag');
    if (payload['shouldNotifyListeners'] is! bool) {
      reasons.add('invalid_listener_notify_flag');
    }
    final surfaces = payload['surfaces'];
    if (surfaces is! List ||
        surfaces.any((surface) => _safeRenderSurface(surface) == null)) {
      reasons.add('invalid_render_surfaces');
    }

    return TripLiveOdometerUiValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status?.name : null,
      displayValue: reasons.isEmpty ? payload['displayValue'] as String? : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final String? status;
  final String? displayValue;
  final List<String> reasons;
}

List<String> _validateSharedPayload(
  Map<String, Object?> payload, {
  required String? statusName,
  required bool requirePayloadGuard,
  required Set<String> acceptedStatusNames,
}) {
  final reasons = <String>[];
  final displayValue = payload['displayValue'];
  final confirmedDisplayValue = payload['confirmedDisplayValue'];
  final reasonCodes = payload['reasonCodes'];
  final payloadGuard = payload['payloadGuard'];

  if (payload['schemaVersion'] != 1) reasons.add('unsupported_schema_version');
  if (displayValue != null && !_displayValueSafe(displayValue)) {
    reasons.add('invalid_display_value');
  }
  if (confirmedDisplayValue != null &&
      !_displayValueSafe(confirmedDisplayValue)) {
    reasons.add('invalid_confirmed_display_value');
  }
  if (reasonCodes is! List ||
      reasonCodes.any((reason) => _safeReason(reason) == null)) {
    reasons.add('invalid_reason_codes');
  }
  if (payload['displayValueValidated'] != true &&
      displayValue != null &&
      _displayValueSafe(displayValue)) {
    reasons.add('display_value_not_marked_validated');
  }
  if (payload['confirmedDisplayValueValidated'] != true &&
      confirmedDisplayValue != null &&
      _displayValueSafe(confirmedDisplayValue)) {
    reasons.add('confirmed_display_value_not_marked_validated');
  }
  if (payload['advisoryOnly'] != true) {
    reasons.add('live_odometer_not_advisory_only');
  }
  if (payload['liveUiMustRefreshOnProjectionChange'] != true ||
      payload['singleLiveOdometerSnapshotRequired'] != true ||
      payload['allDashboardSurfacesUseSameSnapshot'] != true ||
      payload['surfaceSpecificMileageCalculationAllowed'] != false ||
      payload['activeVehicleBlockUsesLiveProjection'] != true ||
      payload['vehicleProfileUsesLiveProjection'] != true ||
      payload['contractorDashboardUsesLiveProjection'] != true ||
      payload['fleetDashboardUsesLiveProjection'] != true ||
      payload['standardDashboardUsesLiveProjection'] != true ||
      payload['calendarReviewUsesConfirmedTruth'] != true) {
    reasons.add('live_odometer_surface_contract_missing');
  }
  if (payload['confirmedOdometerRemainsCanonical'] != true) {
    reasons.add('confirmed_odometer_not_canonical');
  }
  if (payload['writesConfirmedOdometer'] != false ||
      payload['gpsCanReplaceOdometer'] != false ||
      payload['mapboxCanReplaceOdometer'] != false) {
    reasons.add('payload_can_replace_odometer');
  }
  if (payload['firestoreCanOverrideLiveDisplay'] != false ||
      payload['remoteDisplayCanOverrideLocalTrip'] != false ||
      payload['importedDisplayCanOverrideLocalTrip'] != false ||
      payload['dashboardCacheCanOverrideLocalTrip'] != false) {
    reasons.add('remote_display_can_override_local_trip');
  }
  if (payload['authenticationDoesNotGrantDisplayAuthority'] != true) {
    reasons.add('authentication_treated_as_display_authority');
  }
  if (payload['matchingActiveTripRequired'] != true) {
    reasons.add('matching_active_trip_not_required');
  }
  if (payload['activeTripIdIncluded'] != false ||
      payload['ownerUserIdIncluded'] != false) {
    reasons.add('payload_contains_trip_owner_identifiers');
  }
  if (payload['futureProjectionCanRender'] != false ||
      payload['impossibleProjectionCanRender'] != false) {
    reasons.add('unsafe_projection_can_render');
  }
  if (payload['rawGpsIncluded'] != false ||
      payload['preciseLocationIncluded'] != false ||
      payload['routeGeometryIncluded'] != false ||
      payload['tokensIncluded'] != false) {
    reasons.add('payload_contains_sensitive_trip_material');
  }
  if (payloadGuard is Map<String, Object?>) {
    final guardValidation = TripLiveOdometerPayloadGuard.evaluate(payload);
    if (!guardValidation.canRenderAdvisoryLiveOdometer) {
      reasons.add('payload_guard_rejected_live_odometer');
    }
    if (payloadGuard['canRenderAdvisoryLiveOdometer'] != true ||
        payloadGuard['liveUiMayCommitMileage'] != false ||
        payloadGuard['confirmedOdometerRemainsCanonical'] != true ||
        payloadGuard['remotePayloadCanConfirmOdometer'] != false ||
        payloadGuard['mapboxCanRenderWithoutLocalTrip'] != false ||
        payloadGuard['firestoreCanOverrideLiveDisplay'] != false) {
      reasons.add('payload_guard_boundary_missing');
    }
  } else if (requirePayloadGuard &&
      statusName != null &&
      statusName != 'blocked') {
    reasons.add('payload_guard_missing');
  }
  if (payload.values.any(_looksSensitive)) {
    reasons.add('payload_contains_sensitive_text');
  }
  if (statusName != null && !acceptedStatusNames.contains(statusName)) {
    reasons.add('unknown_status');
  }
  return reasons;
}

TripTrackingLiveOdometerBroadcastStatus? _safeBroadcastStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingLiveOdometerBroadcastStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripLiveOdometerRenderStatus? _safeRenderStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripLiveOdometerRenderStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripLiveOdometerRenderSurface? _safeRenderSurface(Object? value) {
  if (value is! String) return null;
  for (final surface in TripLiveOdometerRenderSurface.values) {
    if (surface.name == value) return surface;
  }
  return null;
}

String? _safeReason(Object? value) {
  if (value is! String) return null;
  return switch (value) {
    'confirmed_odometer_display' => value,
    'live_projection_renderable' => value,
    'live_projection_stale_review_only' => value,
    'unsafe_expected_trip_id' => value,
    'unsafe_active_trip_id' => value,
    'negative_confirmed_reading' => value,
    'odometer_display_out_of_range' => value,
    'display_below_confirmed_reading' => value,
    'negative_projection_revision' => value,
    'live_trip_id_mismatch' => value,
    'missing_live_update_time' => value,
    'live_update_time_in_future' => value,
    'live_projection_delta_too_large' => value,
    'live_odometer_payload_guard_passed' => value,
    'no_dashboard_surface_subscribed' => value,
    'live_odometer_render_blocked' => value,
    _ => null,
  };
}

bool _displayValueSafe(Object? value) {
  return value is String && RegExp(r'^\d{7}$').hasMatch(value);
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
