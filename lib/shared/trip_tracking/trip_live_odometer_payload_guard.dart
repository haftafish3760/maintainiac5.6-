enum TripLiveOdometerPayloadGuardStatus {
  passed,
  blockedRemoteAuthority,
  blockedOdometerAuthority,
  blockedSensitivePayload,
  blockedMalformedPayload,
}

class TripLiveOdometerPayloadGuardDecision {
  const TripLiveOdometerPayloadGuardDecision({
    required this.status,
    required this.reasonCodes,
  });

  final TripLiveOdometerPayloadGuardStatus status;
  final List<String> reasonCodes;

  bool get canRenderAdvisoryLiveOdometer =>
      status == TripLiveOdometerPayloadGuardStatus.passed;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCodes': reasonCodes,
    'canRenderAdvisoryLiveOdometer': canRenderAdvisoryLiveOdometer,
    'liveUiMayRefresh': canRenderAdvisoryLiveOdometer,
    'liveUiMayCommitMileage': false,
    'confirmedOdometerRemainsCanonical': true,
    'manualConfirmationRequiredBeforeOfficialMileage': true,
    'activeTripMatchRequired': true,
    'localTripLogRequired': true,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'authenticationDoesNotGrantDisplayAuthority': true,
    'remotePayloadCanOverrideLocalTrip': false,
    'remotePayloadCanConfirmOdometer': false,
    'remotePayloadCanEndTrip': false,
    'dashboardCacheCanOverrideLocalTrip': false,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanRenderWithoutLocalTrip': false,
    'cloudFunctionCanConfirmOdometer': false,
    'firestoreCanOverrideLiveDisplay': false,
    'staleProjectionCanCommitMileage': false,
    'futureProjectionCanRender': false,
    'impossibleProjectionCanRender': false,
    'activeTripIdIncluded': false,
    'ownerUserIdIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripLiveOdometerPayloadGuard {
  const TripLiveOdometerPayloadGuard._();

  static TripLiveOdometerPayloadGuardDecision evaluate(
    Map<String, Object?> payload,
  ) {
    final reasons = <String>[];
    if (payload['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (payload['advisoryOnly'] != true ||
        payload['confirmedOdometerRemainsCanonical'] != true ||
        payload['displayOnlyMileageSource'] is! String) {
      reasons.add('missing_advisory_display_contract');
    }
    if (payload['writesConfirmedOdometer'] != false ||
        payload['gpsCanReplaceOdometer'] != false ||
        payload['mapboxCanReplaceOdometer'] != false ||
        payload['staleProjectionCanCommitMileage'] != false) {
      reasons.add('payload_claims_odometer_authority');
    }
    if (payload['firestoreCanOverrideLiveDisplay'] != false ||
        payload['firestoreCanOverrideLiveProjection'] == true ||
        payload['remoteDisplayCanOverrideLocalTrip'] != false ||
        payload['remoteProjectionCanOverrideLocalTrip'] == true ||
        payload['dashboardCacheCanOverrideLocalTrip'] != false ||
        payload['importedDisplayCanOverrideLocalTrip'] != false ||
        payload['mapboxCanChangeProjection'] == true ||
        payload['mapboxCanOverrideLiveProjection'] == true) {
      reasons.add('payload_claims_remote_display_authority');
    }
    if (payload['authenticationDoesNotGrantDisplayAuthority'] != true ||
        payload['matchingActiveTripRequired'] != true ||
        payload['localTripLogProtected'] != true) {
      reasons.add('missing_local_trip_authorization_contract');
    }
    if (payload['futureProjectionCanRender'] != false ||
        payload['impossibleProjectionCanRender'] != false) {
      reasons.add('unsafe_projection_can_render');
    }
    if (payload['activeTripIdIncluded'] != false ||
        payload['ownerUserIdIncluded'] != false ||
        payload['rawGpsIncluded'] != false ||
        payload['preciseLocationIncluded'] != false ||
        payload['routeGeometryIncluded'] != false ||
        payload['tokensIncluded'] != false ||
        _containsSensitivePayload(payload)) {
      reasons.add('payload_contains_sensitive_trip_material');
    }
    if (reasons.isEmpty) {
      return const TripLiveOdometerPayloadGuardDecision(
        status: TripLiveOdometerPayloadGuardStatus.passed,
        reasonCodes: ['live_odometer_payload_guard_passed'],
      );
    }
    return TripLiveOdometerPayloadGuardDecision(
      status: _statusFor(reasons),
      reasonCodes: List.unmodifiable(reasons.map(_safeReason)),
    );
  }
}

TripLiveOdometerPayloadGuardStatus _statusFor(List<String> reasons) {
  if (reasons.contains('payload_contains_sensitive_trip_material')) {
    return TripLiveOdometerPayloadGuardStatus.blockedSensitivePayload;
  }
  if (reasons.contains('payload_claims_odometer_authority')) {
    return TripLiveOdometerPayloadGuardStatus.blockedOdometerAuthority;
  }
  if (reasons.contains('payload_claims_remote_display_authority')) {
    return TripLiveOdometerPayloadGuardStatus.blockedRemoteAuthority;
  }
  return TripLiveOdometerPayloadGuardStatus.blockedMalformedPayload;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'live_odometer_payload_guard_passed' =>
      'live_odometer_payload_guard_passed',
    'unsupported_schema_version' => 'unsupported_schema_version',
    'missing_advisory_display_contract' => 'missing_advisory_display_contract',
    'payload_claims_odometer_authority' => 'payload_claims_odometer_authority',
    'payload_claims_remote_display_authority' =>
      'payload_claims_remote_display_authority',
    'missing_local_trip_authorization_contract' =>
      'missing_local_trip_authorization_contract',
    'unsafe_projection_can_render' => 'unsafe_projection_can_render',
    'payload_contains_sensitive_trip_material' =>
      'payload_contains_sensitive_trip_material',
    _ => 'missing_advisory_display_contract',
  };
}

bool _containsSensitivePayload(Object? value) {
  if (value is String) {
    return value.startsWith('pk.') ||
        value.startsWith('sk.') ||
        RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(value);
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (_containsSensitivePayload(entry.key) ||
          _containsSensitivePayload(entry.value)) {
        return true;
      }
    }
  }
  if (value is Iterable) {
    for (final item in value) {
      if (_containsSensitivePayload(item)) return true;
    }
  }
  return false;
}
