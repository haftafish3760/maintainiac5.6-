import 'trip_tracking_models.dart';

class TripTrackingCancelledSessionRecord {
  const TripTrackingCancelledSessionRecord({
    required this.sessionId,
    required this.vehicleId,
    required this.profileId,
    this.vehicleConfigurationRevision = 0,
    required this.startedAt,
    required this.cancelledAt,
    required this.startingOdometer,
    required this.profile,
    required this.engineSnapshot,
    required this.lifecycleBeforeCancellation,
    required this.reasonCode,
    required this.userConfirmed,
    this.schemaVersion = 2,
  });

  final String sessionId;
  final String vehicleId;
  final String profileId;
  final int vehicleConfigurationRevision;
  final DateTime startedAt;
  final DateTime cancelledAt;
  final int startingOdometer;
  final TripTrackingProfile profile;
  final TripTrackingEngineSnapshot engineSnapshot;
  final TripTrackingSessionLifecycleState lifecycleBeforeCancellation;
  final String reasonCode;
  final bool userConfirmed;
  final int schemaVersion;

  /// Cancellation preserves evidence but never changes odometer authority.
  static const bool odometerIsGlobalTruth = true;

  bool get hasMeaningfulEvidence =>
      engineSnapshot.totalAcceptedMeters > 0 ||
      engineSnapshot.lastObservedAt != null ||
      engineSnapshot.diagnostics.receivedSamples > 0;

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'sessionId': sessionId,
    'vehicleId': vehicleId,
    'profileId': profileId,
    'vehicleConfigurationRevision': vehicleConfigurationRevision,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'cancelledAt': cancelledAt.toUtc().toIso8601String(),
    'startingOdometer': startingOdometer,
    'profile': profile.name,
    'engineSnapshot': engineSnapshot.toMap(),
    'lifecycleBeforeCancellation': lifecycleBeforeCancellation.name,
    'reasonCode': reasonCode,
    'userConfirmed': userConfirmed,
  };

  static TripTrackingCancelledSessionRecord? tryFromMap(
    Map<dynamic, dynamic> map,
  ) {
    final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}');
    final cancelledAt = DateTime.tryParse('${map['cancelledAt'] ?? ''}');
    final profile = _profileNamed(map['profile']);
    final lifecycle = _lifecycleNamed(map['lifecycleBeforeCancellation']);
    final snapshot = map['engineSnapshot'];
    final schemaVersion = map['schemaVersion'];
    final hasValidVehicleConfigurationRevision =
        schemaVersion == 1 ||
        (map['vehicleConfigurationRevision'] is int &&
            (map['vehicleConfigurationRevision'] as int) >= 0);
    final vehicleConfigurationRevision = schemaVersion == 1
        ? 0
        : map['vehicleConfigurationRevision'] as int? ?? 0;
    if ((schemaVersion != 1 && schemaVersion != 2) ||
        !hasValidVehicleConfigurationRevision ||
        !_safeId(map['sessionId']) ||
        !_safeId(map['vehicleId']) ||
        !_safeId(map['profileId']) ||
        startedAt == null ||
        cancelledAt == null ||
        cancelledAt.isBefore(startedAt) ||
        map['startingOdometer'] is! int ||
        (map['startingOdometer'] as int) < 0 ||
        profile == null ||
        lifecycle == null ||
        snapshot is! Map ||
        !_safeId(map['reasonCode']) ||
        map['userConfirmed'] is! bool) {
      return null;
    }
    return TripTrackingCancelledSessionRecord(
      sessionId: map['sessionId'] as String,
      vehicleId: map['vehicleId'] as String,
      profileId: map['profileId'] as String,
      vehicleConfigurationRevision: vehicleConfigurationRevision,
      startedAt: startedAt.toUtc(),
      cancelledAt: cancelledAt.toUtc(),
      startingOdometer: map['startingOdometer'] as int,
      profile: profile,
      engineSnapshot: TripTrackingEngineSnapshot.fromMap(snapshot),
      lifecycleBeforeCancellation: lifecycle,
      reasonCode: map['reasonCode'] as String,
      userConfirmed: map['userConfirmed'] as bool,
      schemaVersion: 2,
    );
  }
}

bool _safeId(Object? value) =>
    value is String &&
    value.isNotEmpty &&
    value.trim() == value &&
    value.length <= 160;

TripTrackingProfile? _profileNamed(Object? value) {
  for (final profile in TripTrackingProfile.values) {
    if (profile.name == value) return profile;
  }
  return null;
}

TripTrackingSessionLifecycleState? _lifecycleNamed(Object? value) {
  for (final lifecycle in TripTrackingSessionLifecycleState.values) {
    if (lifecycle.name == value) return lifecycle;
  }
  return null;
}
