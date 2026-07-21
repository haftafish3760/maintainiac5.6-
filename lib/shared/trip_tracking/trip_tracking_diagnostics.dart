part of 'trip_tracking_models.dart';

class TripTrackingDiagnostics {
  const TripTrackingDiagnostics({
    this.receivedSamples = 0,
    this.acceptedSamples = 0,
    this.dispositionCounts = const {},
  });

  final int receivedSamples;
  final int acceptedSamples;
  final Map<TripSampleDisposition, int> dispositionCounts;

  int get rejectedSamples {
    final received = _safeNonNegativeInt(receivedSamples);
    final accepted = _safeAcceptedDiagnosticsCount(acceptedSamples, received);
    return received - accepted;
  }

  TripTrackingDiagnostics record(TripSampleDisposition disposition) {
    final counts = Map<TripSampleDisposition, int>.from(dispositionCounts);
    counts.update(disposition, (count) => count + 1, ifAbsent: () => 1);
    final accepted =
        disposition == TripSampleDisposition.acceptedAnchor ||
        disposition == TripSampleDisposition.acceptedDistance;
    return TripTrackingDiagnostics(
      receivedSamples: receivedSamples + 1,
      acceptedSamples: accepted ? acceptedSamples + 1 : acceptedSamples,
      dispositionCounts: Map.unmodifiable(counts),
    );
  }

  Map<String, Object?> toMap() {
    final received = _safeNonNegativeInt(receivedSamples);
    return {
      'receivedSamples': received,
      'acceptedSamples': _safeAcceptedDiagnosticsCount(
        acceptedSamples,
        received,
      ),
      'dispositionCounts': _safeSerializedDispositionCounts(
        dispositionCounts,
        received,
      ),
    };
  }

  factory TripTrackingDiagnostics.fromMap(Map<dynamic, dynamic> map) {
    final rawCounts = map['dispositionCounts'];
    final rawDispositionCounts = <TripSampleDisposition, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final disposition = TripSampleDisposition.values.where(
          (value) => value.name == key,
        );
        if (disposition.isEmpty) continue;
        final count = _safeNonNegativeInt(entry.value);
        if (count > 0) rawDispositionCounts[disposition.single] = count;
      }
    }
    final received = _safeNonNegativeInt(map['receivedSamples']);
    final accepted = _safeNonNegativeInt(map['acceptedSamples']);
    final safeCounts = _safeDispositionCounts(rawDispositionCounts, received);
    return TripTrackingDiagnostics(
      receivedSamples: received,
      acceptedSamples: _safeRestoredAcceptedDiagnosticsCount(
        accepted,
        received,
        safeCounts,
      ),
      dispositionCounts: Map.unmodifiable(safeCounts),
    );
  }
}

Map<String, Object?> _safeSerializedDispositionCounts(
  Map<TripSampleDisposition, int> counts,
  int receivedSamples,
) => {
  for (final entry in _safeDispositionCounts(counts, receivedSamples).entries)
    entry.key.name: entry.value,
};

Map<TripSampleDisposition, int> _safeDispositionCounts(
  Map<TripSampleDisposition, int> counts,
  int receivedSamples,
) {
  final received = _safeNonNegativeInt(receivedSamples);
  if (received == 0) return const {};
  var total = 0;
  final safe = <TripSampleDisposition, int>{};
  for (final entry in counts.entries) {
    final count = _safeNonNegativeInt(entry.value);
    if (count == 0 || total + count > received) continue;
    total += count;
    safe[entry.key] = count;
  }
  return Map.unmodifiable(safe);
}

int _safeAcceptedDiagnosticsCount(int acceptedSamples, int receivedSamples) {
  final received = _safeNonNegativeInt(receivedSamples);
  final accepted = _safeNonNegativeInt(acceptedSamples);
  return accepted > received ? 0 : accepted;
}

int _safeRestoredAcceptedDiagnosticsCount(
  int acceptedSamples,
  int receivedSamples,
  Map<TripSampleDisposition, int> counts,
) {
  final safeAccepted = _safeAcceptedDiagnosticsCount(
    acceptedSamples,
    receivedSamples,
  );
  final countedAccepted =
      (counts[TripSampleDisposition.acceptedAnchor] ?? 0) +
      (counts[TripSampleDisposition.acceptedDistance] ?? 0);
  if (countedAccepted > safeAccepted) return 0;
  return safeAccepted;
}

int _safeNonNegativeInt(Object? value) {
  if (value is! num || !value.isFinite) return 0;
  final parsed = value.toInt();
  return parsed < 0 ? 0 : parsed;
}

double _safeAcceptedMeters(Object? value) {
  if (value is! num) return 0;
  final meters = value.toDouble();
  return meters.isFinite && meters >= 0 ? meters : 0;
}

int _safeSchemaVersion(Object? value) {
  if (value is! num || !value.isFinite) return 1;
  final version = value.toInt();
  return version < 1 ? 1 : version;
}

String _safeAlgorithmVersion(Object? value) {
  final version = value is String ? value.trim() : '';
  if (version.isEmpty) return 'gps-v1';
  final safe = version
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return 'gps-v1';
  return safe.length > 48 ? safe.substring(0, 48) : safe;
}

DateTime? _safeLastObservedAt(
  Object? value, {
  required TripLocationSample? lastAccepted,
}) {
  if (lastAccepted == null) return null;
  final parsed = _tripTimestampFrom(value);
  if (parsed == null) return lastAccepted.recordedAt;
  if (parsed.isBefore(lastAccepted.recordedAt)) {
    return lastAccepted.recordedAt;
  }
  if (parsed.difference(lastAccepted.recordedAt) >
      _maxPersistedObservationLead) {
    return lastAccepted.recordedAt;
  }
  return parsed;
}

DateTime? _safeLastContinuousAt(
  Object? value, {
  required TripLocationSample? lastAccepted,
  required DateTime? lastObservedAt,
}) {
  if (lastAccepted == null || lastObservedAt == null) return null;
  final parsed = _tripTimestampFrom(value) ?? lastAccepted.recordedAt;
  if (parsed.isBefore(lastAccepted.recordedAt)) return lastAccepted.recordedAt;
  if (parsed.isAfter(lastObservedAt)) return lastObservedAt;
  return parsed;
}

int? _safePersistedMonotonicElapsedNanos(
  Object? value, {
  int? floor,
  int? ceiling,
}) {
  final parsed = _tripMonotonicElapsedNanosFrom(value);
  if (parsed == null) return floor;
  if (floor != null && parsed < floor) return floor;
  if (ceiling != null && parsed > ceiling) return ceiling;
  return parsed;
}

DateTime? _safeStationaryStartedAt(
  Object? value, {
  required bool vehicleMovementObserved,
  required DateTime? lastObservedAt,
}) {
  if (!vehicleMovementObserved || lastObservedAt == null) return null;
  final parsed = _tripTimestampFrom(value);
  if (parsed == null || parsed.isAfter(lastObservedAt)) return null;
  if (lastObservedAt.difference(parsed) > const Duration(hours: 8)) {
    return null;
  }
  return parsed;
}

class TripSamplingRecommendation {
  const TripSamplingRecommendation({
    required this.mode,
    required this.interval,
    required this.minimumDisplacementMeters,
  });

  final TripSamplingMode mode;
  final Duration interval;
  final double minimumDisplacementMeters;
}

class TripSampleDecision {
  const TripSampleDecision({
    required this.disposition,
    required this.totalAcceptedMeters,
    this.addedMeters = 0,
    this.walkingReviewSuggested = false,
    this.motionState = TripMotionState.unknown,
  });

  final TripSampleDisposition disposition;
  final double totalAcceptedMeters;
  final double addedMeters;
  final bool walkingReviewSuggested;
  final TripMotionState motionState;

  bool get accepted =>
      disposition == TripSampleDisposition.acceptedAnchor ||
      disposition == TripSampleDisposition.acceptedDistance;
}
