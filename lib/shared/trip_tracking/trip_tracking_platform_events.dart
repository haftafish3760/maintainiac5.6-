part of 'trip_tracking_platform.dart';

enum TripTrackingAuthorizationState {
  notDetermined,
  whileInUse,
  always,
  denied,
  restricted,
}

class TripTrackingAuthorization {
  const TripTrackingAuthorization({
    required this.state,
    required this.preciseLocation,
  });

  final TripTrackingAuthorizationState state;
  final bool preciseLocation;

  bool get canTrack =>
      state == TripTrackingAuthorizationState.whileInUse ||
      state == TripTrackingAuthorizationState.always;

  bool get canTrackPrecisely => canTrack && preciseLocation;

  bool get canTrackInBackground =>
      state == TripTrackingAuthorizationState.always;

  Map<String, Object> toSafeLogMap() => {
    'schemaVersion': 1,
    'externalNativeInput': true,
    'payloadPassedSchemaValidation': true,
    'state': state.name,
    'preciseLocation': preciseLocation,
    'canTrack': canTrack,
    'canTrackInBackground': canTrackInBackground,
    'authorizationDoesNotImplyOwnership': true,
    'authorizationCanReadOtherUsersData': false,
    'authorizationCanConfirmMileage': false,
    'backgroundTrackingRequiresOptIn': true,
    'rawAuthorizationPayloadIncluded': false,
  };

  factory TripTrackingAuthorization.fromMap(Map<dynamic, dynamic> map) {
    if (!_schemaVersionAllowed(map['schemaVersion'])) {
      return const TripTrackingAuthorization(
        state: TripTrackingAuthorizationState.notDetermined,
        preciseLocation: false,
      );
    }
    final state = TripTrackingAuthorizationState.values.firstWhere(
      (value) => value.name == map['state'],
      orElse: () => TripTrackingAuthorizationState.notDetermined,
    );
    return TripTrackingAuthorization(
      state: state,
      preciseLocation:
          state != TripTrackingAuthorizationState.notDetermined &&
          map['preciseLocation'] == true,
    );
  }
}

enum TripTrackingPlatformEventType {
  location,
  activity,
  authorization,
  status,
  error,
}

class TripTrackingPlatformEvent {
  const TripTrackingPlatformEvent._({
    required this.type,
    this.location,
    this.activity,
    this.authorization,
    this.status,
    this.errorCode,
    this.errorMessage,
  });

  final TripTrackingPlatformEventType type;
  final TripLocationSample? location;
  final TripActivityObservation? activity;
  final TripTrackingAuthorization? authorization;
  final String? status;
  final String? errorCode;
  final String? errorMessage;

  /// Boundary-safe diagnostics for native/Mapbox/GPS event handling.
  Map<String, Object?> toSafeLogMap() {
    final payloadPassedSchemaValidation =
        type != TripTrackingPlatformEventType.error;
    final result = <String, Object?>{
      'schemaVersion': 1,
      'type': type.name,
      'payloadPassedSchemaValidation': payloadPassedSchemaValidation,
      'hasLocation': location != null,
      'hasActivity': activity != null,
      'hasAuthorization': authorization != null,
      'externalNativeInput': true,
      'externalPlatformPayloadTrustedAfterValidationOnly': true,
      'authenticationDoesNotImplyAuthorization': true,
      'platformEventCanAuthorizeUserDataAccess': false,
      'platformEventCanOverrideLocalTripLog': false,
      'platformEventCanConfirmOdometer': false,
      'odometerIsGlobalTruth': true,
      'platformEventCanCreateCalibration': false,
      'platformEventCanApplyCalibration': false,
      'calibrationRequiresTrustedGpsWindow': true,
      'poorGpsDaysExcludedFromCalibration': true,
      'mapboxEventCanOverrideTripLog': false,
      'mapboxEventCanConfirmOdometer': false,
      'firestoreEventCanOverridePlatformState': false,
      'rawNativePayloadIncluded': false,
      'preciseLocationIncluded': false,
      'rawSensorPayloadIncluded': false,
      'tokensIncluded': false,
    };
    final sample = location;
    if (sample != null) {
      final summary = sample.toEvidenceBoundarySummary();
      result.addAll({
        'locationAccuracyBucket': summary['accuracyBucket'],
        'locationSpeedBucket': summary['speedBucket'],
        'mockedLocationReported': summary['mockedLocationReported'],
        'hasSpeed': sample.speedMetersPerSecond != null,
        'hasSpeedAccuracy': summary['hasSpeedAccuracy'],
        'hasBearing': summary['hasBearing'],
        'hasMonotonicElapsedTime': summary['hasMonotonicElapsedTime'],
        'rawLatitudeIncluded': summary['rawLatitudeIncluded'],
        'rawLongitudeIncluded': summary['rawLongitudeIncluded'],
        'rawTimestampIncluded': summary['rawTimestampIncluded'],
      });
    }
    final observation = activity;
    if (observation != null) {
      final summary = observation.toEvidenceBoundarySummary();
      result.addAll({
        'activity': summary['activity'],
        'activityConfidenceBucket': summary['confidenceBucket'],
        'activityCanSupportStopReview': summary['canSupportStopReview'],
        'rawSensorPayloadIncluded': summary['rawSensorPayloadIncluded'],
        'preciseTimestampIncluded': summary['preciseTimestampIncluded'],
      });
    }
    final permission = authorization;
    if (permission != null) {
      result['authorization'] = permission.toSafeLogMap();
    }
    if (status != null) result['status'] = status;
    if (errorCode != null) result['errorCode'] = errorCode;
    if (errorMessage != null) result['errorMessage'] = errorMessage;
    return result;
  }

  factory TripTrackingPlatformEvent.fromNativePayload(Object? payload) {
    if (payload is Map) return TripTrackingPlatformEvent.fromMap(payload);
    return const TripTrackingPlatformEvent._(
      type: TripTrackingPlatformEventType.error,
      errorCode: 'invalidNativeEventPayload',
      errorMessage: 'Ignored malformed native trip tracking event.',
    );
  }

  factory TripTrackingPlatformEvent.fromMap(Map<dynamic, dynamic> map) {
    if (!_schemaVersionAllowed(map['schemaVersion'])) {
      return const TripTrackingPlatformEvent._(
        type: TripTrackingPlatformEventType.error,
        errorCode: 'invalidSchemaVersion',
        errorMessage: 'Ignored unsupported native trip tracking event schema.',
      );
    }
    final declaredType = TripTrackingPlatformEventType.values.firstWhere(
      (value) => value.name == map['type'],
      orElse: () => TripTrackingPlatformEventType.error,
    );
    final location =
        declaredType == TripTrackingPlatformEventType.location &&
            !_hasInvalidNativeReportedSpeed(map)
        ? TripLocationSample.tryFromMap(map)
        : null;
    final activity = declaredType == TripTrackingPlatformEventType.activity
        ? TripActivityObservation.tryFromMap(map)
        : null;
    final authorization =
        declaredType == TripTrackingPlatformEventType.authorization
        ? _tryAuthorizationEvent(map)
        : null;
    final status = declaredType == TripTrackingPlatformEventType.status
        ? _safePlatformStatus(map['status'])
        : null;
    final type =
        declaredType == TripTrackingPlatformEventType.location &&
            location == null
        ? TripTrackingPlatformEventType.error
        : declaredType == TripTrackingPlatformEventType.activity &&
              activity == null
        ? TripTrackingPlatformEventType.error
        : declaredType == TripTrackingPlatformEventType.authorization &&
              authorization == null
        ? TripTrackingPlatformEventType.error
        : declaredType == TripTrackingPlatformEventType.status && status == null
        ? TripTrackingPlatformEventType.error
        : declaredType;
    return TripTrackingPlatformEvent._(
      type: type,
      location: location,
      activity: activity,
      authorization: type == TripTrackingPlatformEventType.authorization
          ? authorization
          : null,
      status: type == TripTrackingPlatformEventType.status ? status : null,
      errorCode:
          type == TripTrackingPlatformEventType.error &&
              declaredType == TripTrackingPlatformEventType.location
          ? 'invalidLocationPayload'
          : type == TripTrackingPlatformEventType.error &&
                declaredType == TripTrackingPlatformEventType.activity
          ? 'invalidActivityPayload'
          : type == TripTrackingPlatformEventType.error &&
                declaredType == TripTrackingPlatformEventType.authorization
          ? 'invalidAuthorizationPayload'
          : type == TripTrackingPlatformEventType.error &&
                declaredType == TripTrackingPlatformEventType.status
          ? 'invalidStatusPayload'
          : type == TripTrackingPlatformEventType.error
          ? _safePlatformToken(map['errorCode']) ?? 'unknownNativeEvent'
          : null,
      errorMessage:
          type == TripTrackingPlatformEventType.error &&
              declaredType == TripTrackingPlatformEventType.location
          ? 'Ignored malformed location payload.'
          : type == TripTrackingPlatformEventType.error &&
                declaredType == TripTrackingPlatformEventType.activity
          ? 'Ignored malformed activity payload.'
          : type == TripTrackingPlatformEventType.error &&
                declaredType == TripTrackingPlatformEventType.authorization
          ? 'Ignored malformed authorization payload.'
          : type == TripTrackingPlatformEventType.error &&
                declaredType == TripTrackingPlatformEventType.status
          ? 'Ignored malformed status payload.'
          : type == TripTrackingPlatformEventType.error
          ? _safePlatformMessage(map['errorMessage']) ??
                'Ignored unknown native trip tracking event.'
          : null,
    );
  }
}

bool _schemaVersionAllowed(Object? value) =>
    value == null || (value is int && value == 1);

TripTrackingAuthorization? _tryAuthorizationEvent(Map<dynamic, dynamic> map) {
  final rawState = map['state'];
  if (rawState is! String) return null;
  final state = TripTrackingAuthorizationState.values.firstWhere(
    (value) => value.name == rawState,
    orElse: () => TripTrackingAuthorizationState.notDetermined,
  );
  if (state == TripTrackingAuthorizationState.notDetermined &&
      rawState != TripTrackingAuthorizationState.notDetermined.name) {
    return null;
  }
  final rawPreciseLocation = map['preciseLocation'];
  if (rawPreciseLocation is! bool) return null;
  return TripTrackingAuthorization(
    state: state,
    preciseLocation:
        state != TripTrackingAuthorizationState.notDetermined &&
        rawPreciseLocation,
  );
}

String? _safePlatformToken(Object? value) {
  if (value is! String) return null;
  final clean = value.trim();
  if (clean.isEmpty || clean.length > 80) return null;
  if (RegExp(r'\b[ps]k\.', caseSensitive: false).hasMatch(clean) ||
      RegExp(r'-?\d+\.\d+').hasMatch(clean)) {
    return null;
  }
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean) ? clean : null;
}

String? _safePlatformStatus(Object? value) {
  final clean = _safePlatformToken(value);
  return switch (clean) {
    'idle' ||
    'starting' ||
    'tracking' ||
    'paused' ||
    'recovering' ||
    'degraded' ||
    'backgroundRestricted' ||
    'permissionRequired' ||
    'providerUnavailable' ||
    'stopped' => clean,
    _ => null,
  };
}

bool _hasInvalidNativeReportedSpeed(Map<dynamic, dynamic> map) {
  if (!map.containsKey('speedMetersPerSecond') ||
      map['speedMetersPerSecond'] == null) {
    return false;
  }
  final speed = map['speedMetersPerSecond'];
  return speed is! num || !speed.isFinite || speed < 0 || speed > 70;
}

String? _safePlatformMessage(Object? value) {
  if (value is! String) return null;
  final clean = value
      .replaceAll(RegExp(r'\b[ps]k\.[A-Za-z0-9._-]+'), '[redacted_token]')
      .replaceAll(
        RegExp(r'\btoken\s*=\s*[^,\s;]+', caseSensitive: false),
        'token=[redacted]',
      )
      .replaceAllMapped(
        RegExp(
          r'\b(lat|latitude|lon|lng|longitude)\s*[:=]\s*-?\d+(\.\d+)?',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}=[redacted]',
      )
      .replaceAll(
        RegExp(r'\b-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}\b'),
        '[redacted_coordinates]',
      )
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return null;
  return clean.length <= 160 ? clean : clean.substring(0, 160);
}

String _batteryBucket(int? percent) {
  if (percent == null) return 'unknown';
  if (percent < 0 || percent > 100) return 'unknown';
  if (percent < 20) return 'critical';
  if (percent < 40) return 'low';
  if (percent < 80) return 'normal';
  return 'high';
}
