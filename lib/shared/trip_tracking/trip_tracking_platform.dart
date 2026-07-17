import 'dart:async';

import 'package:flutter/services.dart';

import 'trip_tracking_models.dart';

/// Native location bridge. It deliberately contains no trip policy: native
/// code reports measurements and lifecycle state while [TripTrackingEngine]
/// remains the single place that decides whether distance is credible.
abstract interface class TripTrackingNativeGateway {
  Stream<TripTrackingPlatformEvent> get events;

  Future<TripTrackingPlatformCapabilities> readCapabilities();
  Future<TripTrackingBatterySnapshot> readBatterySnapshot();
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  });
  Future<bool> start(TripTrackingNativeRequest request);
  Future<bool> update(TripTrackingNativeRequest request);
  Future<void> stop();
  Future<bool> get isTracking;
}

class TripTrackingPlatform implements TripTrackingNativeGateway {
  TripTrackingPlatform({MethodChannel? commands, EventChannel? events})
    : _commands = commands ?? const MethodChannel(_commandChannelName),
      _events = events ?? const EventChannel(_eventChannelName);

  static const _commandChannelName = 'maintainiac/trip_tracking/commands';
  static const _eventChannelName = 'maintainiac/trip_tracking/events';

  final MethodChannel _commands;
  final EventChannel _events;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => TripTrackingPlatformEvent.fromMap(event as Map));

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async {
    final raw = await _commands.invokeMethod<Object?>('readCapabilities');
    return TripTrackingPlatformCapabilities.fromMap(
      raw is Map ? raw : const {},
    );
  }

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async {
    final raw = await _commands.invokeMethod<Object?>('readBatterySnapshot');
    return TripTrackingBatterySnapshot.fromMap(raw is Map ? raw : const {});
  }

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async {
    final raw = await _commands.invokeMethod<Object?>('requestAuthorization', {
      'allowBackground': allowBackground,
      'activityRecognitionEnabled': activityRecognitionEnabled,
    });
    return TripTrackingAuthorization.fromMap(raw is Map ? raw : const {});
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    final started = await _commands.invokeMethod<Object?>(
      'start',
      request.toMap(),
    );
    return started == true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async {
    final updated = await _commands.invokeMethod<Object?>(
      'update',
      request.toMap(),
    );
    return updated == true;
  }

  @override
  Future<void> stop() => _commands.invokeMethod<void>('stop');

  @override
  Future<bool> get isTracking async =>
      await _commands.invokeMethod<Object?>('isTracking') == true;
}

class TripTrackingNativeRequest {
  const TripTrackingNativeRequest({
    required this.profile,
    required this.sampling,
    this.activityRecognitionEnabled = false,
  });

  final TripTrackingProfile profile;
  final TripSamplingRecommendation sampling;
  final bool activityRecognitionEnabled;

  Map<String, Object> toMap() => {
    'profile': profile.name,
    'intervalMillis': _safeSamplingIntervalMillis(sampling.interval),
    'minimumDisplacementMeters': _safeMinimumDisplacementMeters(
      sampling.minimumDisplacementMeters,
    ),
    'activityRecognitionEnabled': activityRecognitionEnabled,
  };
}

int _safeSamplingIntervalMillis(Duration interval) {
  final millis = interval.inMilliseconds;
  return millis.clamp(1000, 120000).toInt();
}

double _safeMinimumDisplacementMeters(double meters) {
  if (!meters.isFinite || meters <= 0) return 1;
  return meters > 1000 ? 1000 : meters;
}

class TripTrackingPlatformCapabilities {
  const TripTrackingPlatformCapabilities({
    required this.locationAvailable,
    required this.backgroundTrackingAvailable,
    required this.activityRecognitionAvailable,
    this.batteryStateAvailable = false,
    this.lowPowerModeAvailable = false,
  });

  final bool locationAvailable;
  final bool backgroundTrackingAvailable;
  final bool activityRecognitionAvailable;
  final bool batteryStateAvailable;
  final bool lowPowerModeAvailable;

  TripTrackingDeviceCapabilityTier get deviceTier {
    if (!locationAvailable) return TripTrackingDeviceCapabilityTier.unavailable;
    if (activityRecognitionAvailable && batteryStateAvailable) {
      return TripTrackingDeviceCapabilityTier.motionAndBatteryAssist;
    }
    if (activityRecognitionAvailable) {
      return TripTrackingDeviceCapabilityTier.motionAssist;
    }
    return TripTrackingDeviceCapabilityTier.locationOnly;
  }

  factory TripTrackingPlatformCapabilities.fromMap(Map<dynamic, dynamic> map) {
    final locationAvailable = map['locationAvailable'] == true;
    final batteryStateAvailable =
        locationAvailable && map['batteryStateAvailable'] == true;
    return TripTrackingPlatformCapabilities(
      locationAvailable: locationAvailable,
      backgroundTrackingAvailable:
          locationAvailable && map['backgroundTrackingAvailable'] == true,
      activityRecognitionAvailable:
          locationAvailable && map['activityRecognitionAvailable'] == true,
      batteryStateAvailable: batteryStateAvailable,
      lowPowerModeAvailable:
          batteryStateAvailable && map['lowPowerModeAvailable'] == true,
    );
  }
}

enum TripTrackingDeviceCapabilityTier {
  unavailable,
  locationOnly,
  motionAssist,
  motionAndBatteryAssist,
}

class TripTrackingBatterySnapshot {
  const TripTrackingBatterySnapshot({
    required this.batteryPercent,
    required this.isCharging,
    required this.lowPowerModeEnabled,
  });

  final int? batteryPercent;
  final bool isCharging;
  final bool lowPowerModeEnabled;

  factory TripTrackingBatterySnapshot.fromMap(Map<dynamic, dynamic> map) {
    final rawPercent = map['batteryPercent'];
    final percent = rawPercent is num && rawPercent.isFinite
        ? rawPercent.floor()
        : null;
    return TripTrackingBatterySnapshot(
      batteryPercent: percent != null && percent >= 0 && percent <= 100
          ? percent
          : null,
      isCharging: map['isCharging'] == true,
      lowPowerModeEnabled: map['lowPowerModeEnabled'] == true,
    );
  }
}

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

  factory TripTrackingAuthorization.fromMap(Map<dynamic, dynamic> map) {
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

  factory TripTrackingPlatformEvent.fromMap(Map<dynamic, dynamic> map) {
    final declaredType = TripTrackingPlatformEventType.values.firstWhere(
      (value) => value.name == map['type'],
      orElse: () => TripTrackingPlatformEventType.error,
    );
    final location = declaredType == TripTrackingPlatformEventType.location
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
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean) ? clean : null;
}

String? _safePlatformStatus(Object? value) {
  final clean = _safePlatformToken(value);
  return switch (clean) {
    'idle' || 'tracking' || 'stopped' => clean,
    _ => null,
  };
}

String? _safePlatformMessage(Object? value) {
  if (value is! String) return null;
  final clean = value
      .replaceAll(RegExp(r'\b[ps]k\.[A-Za-z0-9._-]+'), '[redacted_token]')
      .replaceAll(
        RegExp(r'\btoken\s*=\s*[^,\s;]+', caseSensitive: false),
        'token=[redacted]',
      )
      .replaceAll(
        RegExp(
          r'\b(lat|latitude|lon|lng|longitude)\s*[:=]\s*-?\d+(\.\d+)?',
          caseSensitive: false,
        ),
        r'$1=[redacted]',
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
