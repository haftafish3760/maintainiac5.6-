import 'trip_tracking_profile_strategy.dart';

class TripWalkingEvidenceRecencyDecision {
  const TripWalkingEvidenceRecencyDecision({
    required this.usable,
    required this.reasonCode,
    required this.walkingEvidenceCount,
    required this.walkingEvidenceSpan,
    required this.latestEvidenceAge,
    required this.maximumEvidenceAge,
  });

  final bool usable;
  final String reasonCode;
  final int walkingEvidenceCount;
  final Duration walkingEvidenceSpan;
  final Duration? latestEvidenceAge;
  final Duration maximumEvidenceAge;

  bool get rejected => !usable;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'usable': usable,
    'reasonCode': reasonCode,
    'walkingEvidenceCount': walkingEvidenceCount,
    'walkingEvidenceSpanSeconds': walkingEvidenceSpan.inSeconds,
    'latestEvidenceAgeSeconds': latestEvidenceAge?.inSeconds,
    'maximumEvidenceAgeSeconds': maximumEvidenceAge.inSeconds,
    'futureEvidenceRejected': reasonCode == 'future_walking_evidence_rejected',
    'staleEvidenceRejected': reasonCode == 'stale_walking_evidence_rejected',
    'undatedEvidenceRejected':
        reasonCode == 'undated_walking_evidence_rejected',
    'malformedWalkingEvidenceFailsClosed': true,
    'negativeWalkingSpanSanitized': true,
    'walkingEvidenceCanOnlySuggestReview': true,
    'activityRecognitionCanCreateOfficialStop': false,
    'mapboxCanRefreshWalkingEvidence': false,
    'firestoreCanRefreshWalkingEvidence': false,
    'cloudFunctionCanRefreshWalkingEvidence': false,
    'remoteWalkingEvidenceCanOverrideLocalTrip': false,
    'rawSensorPayloadIncluded': false,
    'coordinatesIncluded': false,
    'tokensIncluded': false,
  };
}

class TripWalkingEvidenceRecencyGuard {
  const TripWalkingEvidenceRecencyGuard._();

  static TripWalkingEvidenceRecencyDecision evaluate({
    required TripTrackingProfileStrategy strategy,
    required int walkingEvidenceCount,
    required Duration walkingEvidenceSpan,
    required DateTime? observedAt,
    required DateTime? latestWalkingEvidenceAt,
  }) {
    final count = _safeCount(walkingEvidenceCount);
    final span = _safeDuration(walkingEvidenceSpan);
    final maximumAge = _maximumEvidenceAgeFor(strategy);
    if (count == 0) {
      return TripWalkingEvidenceRecencyDecision(
        usable: true,
        reasonCode: 'no_walking_evidence',
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        latestEvidenceAge: null,
        maximumEvidenceAge: maximumAge,
      );
    }

    final observed = observedAt;
    final latest = latestWalkingEvidenceAt;
    if (observed == null || latest == null) {
      return TripWalkingEvidenceRecencyDecision(
        usable: false,
        reasonCode: 'undated_walking_evidence_rejected',
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        latestEvidenceAge: null,
        maximumEvidenceAge: maximumAge,
      );
    }
    if (latest.isAfter(observed)) {
      return TripWalkingEvidenceRecencyDecision(
        usable: false,
        reasonCode: 'future_walking_evidence_rejected',
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        latestEvidenceAge: null,
        maximumEvidenceAge: maximumAge,
      );
    }

    final age = observed.difference(latest);
    if (age > maximumAge) {
      return TripWalkingEvidenceRecencyDecision(
        usable: false,
        reasonCode: 'stale_walking_evidence_rejected',
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        latestEvidenceAge: age,
        maximumEvidenceAge: maximumAge,
      );
    }

    return TripWalkingEvidenceRecencyDecision(
      usable: true,
      reasonCode: 'walking_evidence_current',
      walkingEvidenceCount: count,
      walkingEvidenceSpan: span,
      latestEvidenceAge: age,
      maximumEvidenceAge: maximumAge,
    );
  }
}

Duration _maximumEvidenceAgeFor(TripTrackingProfileStrategy strategy) {
  final confirmation = strategy.walkingStopConfirmationDuration;
  final scaled = Duration(seconds: confirmation.inSeconds * 3);
  if (scaled < const Duration(minutes: 2)) return const Duration(minutes: 2);
  if (scaled > const Duration(minutes: 8)) return const Duration(minutes: 8);
  return scaled;
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

Duration _safeDuration(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value > const Duration(hours: 24) ? const Duration(hours: 24) : value;
}
