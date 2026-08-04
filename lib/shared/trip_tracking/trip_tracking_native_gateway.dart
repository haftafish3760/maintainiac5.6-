part of 'trip_tracking_platform.dart';

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

/// Optional platform contract for opt-in App Assistant evidence observation.
///
/// Owns native collection lifecycle for possible-drive evidence only. It does
/// not create trip sessions, report route distance, or confirm any record.
/// Consumed by [TripAutomaticEvidenceRuntimeController] through the shared
/// validated platform event stream.
abstract interface class TripAutomaticEvidenceNativeGateway {
  Stream<TripTrackingPlatformEvent> get events;

  Future<bool> startAutomaticEvidenceObservation({
    required bool activityRecognitionEnabled,
  });
  Future<void> stopAutomaticEvidenceObservation();
  Future<bool> get isAutomaticEvidenceObservationRunning;
}

/// Optional native evidence retained when a platform-side driver action occurs
/// while Dart is suspended. Reading consumes the marker so stale intent cannot
/// affect a later trip.
abstract interface class TripTrackingNativeRecoveryGateway {
  Future<String?> consumeRecoveryStatus();
}

/// Optional user-directed navigation used on Android 11+, where background
/// location can only be granted from the app's system settings page.
abstract interface class TripTrackingNativeSettingsGateway {
  Future<bool> openBackgroundLocationSettings();
}

class TripTrackingPlatform
    implements
        TripTrackingNativeGateway,
        TripAutomaticEvidenceNativeGateway,
        TripTrackingNativeRecoveryGateway,
        TripTrackingNativeSettingsGateway {
  TripTrackingPlatform({MethodChannel? commands, EventChannel? events})
    : _commands = commands ?? const MethodChannel(_commandChannelName),
      _events = events ?? const EventChannel(_eventChannelName);

  static const _commandChannelName = 'maintainiac/trip_tracking/commands';
  static const _eventChannelName = 'maintainiac/trip_tracking/events';

  final MethodChannel _commands;
  final EventChannel _events;

  late final Stream<TripTrackingPlatformEvent> _eventStream = _events
      .receiveBroadcastStream()
      .map(TripTrackingPlatformEvent.fromNativePayload)
      .asBroadcastStream();

  @override
  Stream<TripTrackingPlatformEvent> get events => _eventStream;

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
  Future<bool> startAutomaticEvidenceObservation({
    required bool activityRecognitionEnabled,
  }) async =>
      await _commands.invokeMethod<Object?>('startAutomaticEvidence', {
        'activityRecognitionEnabled': activityRecognitionEnabled,
      }) ==
      true;

  @override
  Future<void> stopAutomaticEvidenceObservation() =>
      _commands.invokeMethod<void>('stopAutomaticEvidence');

  @override
  Future<bool> get isAutomaticEvidenceObservationRunning async =>
      await _commands.invokeMethod<Object?>('isAutomaticEvidenceRunning') ==
      true;

  @override
  Future<bool> get isTracking async =>
      await _commands.invokeMethod<Object?>('isTracking') == true;

  @override
  Future<String?> consumeRecoveryStatus() async {
    final status = await _commands.invokeMethod<Object?>(
      'consumeRecoveryStatus',
    );
    return status is String && status.isNotEmpty ? status : null;
  }

  @override
  Future<bool> openBackgroundLocationSettings() async =>
      await _commands.invokeMethod<Object?>('openBackgroundLocationSettings') ==
      true;
}
