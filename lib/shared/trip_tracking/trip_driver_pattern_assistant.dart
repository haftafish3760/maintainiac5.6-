// odometerIsGlobalTruth: true. Learned GPS patterns remain advisory-only.

import 'dart:math' as math;

enum TripDriverPatternConfidence { insufficient, low, medium, high }

enum TripDriverPatternSuggestion {
  regularStartReminder,
  multiStopWorkflow,
  extendedStopReviewTiming,
}

class TripDriverPatternObservation {
  const TripDriverPatternObservation({
    required this.sessionId,
    required this.vehicleId,
    required this.profileId,
    required this.startedAtUtc,
    required this.endedAtUtc,
    required this.confirmedOdometerDistanceMiles,
    required this.confirmedStopCount,
    required this.longestConfirmedStop,
    required this.userReviewed,
    required this.odometerConfirmed,
  });

  final String sessionId;
  final String vehicleId;
  final String profileId;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final double confirmedOdometerDistanceMiles;
  final int confirmedStopCount;
  final Duration longestConfirmedStop;
  final bool userReviewed;
  final bool odometerConfirmed;
}

class TripDriverPatternDecision {
  const TripDriverPatternDecision({
    required this.confidence,
    required this.suggestions,
    required this.reviewedTripCount,
    required this.ignoredObservationCount,
    required this.typicalStartMinuteUtc,
    required this.typicalOdometerDistanceMiles,
    required this.typicalConfirmedStopCount,
    required this.suggestedStopReviewAfter,
    required this.reasonCode,
  });

  final TripDriverPatternConfidence confidence;
  final List<TripDriverPatternSuggestion> suggestions;
  final int reviewedTripCount;
  final int ignoredObservationCount;
  final int? typicalStartMinuteUtc;
  final double? typicalOdometerDistanceMiles;
  final int? typicalConfirmedStopCount;
  final Duration? suggestedStopReviewAfter;
  final String reasonCode;

  bool get hasSuggestion => suggestions.isNotEmpty;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'confidence': confidence.name,
    'suggestions': suggestions.map((value) => value.name).toList(),
    'reviewedTripCount': reviewedTripCount,
    'ignoredObservationCount': ignoredObservationCount,
    'typicalStartMinuteUtc': typicalStartMinuteUtc,
    'typicalOdometerDistanceMiles': typicalOdometerDistanceMiles,
    'typicalConfirmedStopCount': typicalConfirmedStopCount,
    'suggestedStopReviewAfterMinutes': suggestedStopReviewAfter?.inMinutes,
    'reasonCode': reasonCode,
    'advisoryOnly': true,
    'userConfirmationRequired': true,
    'odometerRemainsCanonical': true,
    'canChangeOdometer': false,
    'canChangeConfirmedMileage': false,
    'canClassifyBusinessUse': false,
    'canFinalizeTrip': false,
    'canSwitchVehicle': false,
    'canSwitchProfile': false,
    'rawTripsIncluded': false,
    'rawLocationsIncluded': false,
    'sessionIdsIncluded': false,
    'vehicleIdIncluded': false,
    'profileIdIncluded': false,
  };
}

class TripDriverPatternAssistant {
  const TripDriverPatternAssistant._();

  static TripDriverPatternDecision evaluate({
    required Iterable<TripDriverPatternObservation> observations,
    required String vehicleId,
    required String profileId,
    DateTime? nowUtc,
    int minimumReviewedTrips = 5,
    int maximumObservationCount = 64,
    Duration maximumObservationAge = const Duration(days: 90),
  }) {
    final cleanVehicleId = vehicleId.trim();
    final cleanProfileId = profileId.trim();
    final trustedNowUtc = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final safeMinimum = minimumReviewedTrips.clamp(3, 20);
    final safeMaximum = maximumObservationCount.clamp(safeMinimum, 256);
    final safeAge = maximumObservationAge > Duration.zero
        ? maximumObservationAge
        : const Duration(days: 90);
    if (cleanVehicleId.isEmpty || cleanProfileId.isEmpty) {
      return _emptyDecision(
        ignoredObservationCount: observations.length,
        reasonCode: 'missing_vehicle_or_profile_scope',
      );
    }

    final ordered = observations.toList(growable: false)
      ..sort((left, right) => right.startedAtUtc.compareTo(left.startedAtUtc));
    final accepted = <TripDriverPatternObservation>[];
    final sessionIds = <String>{};
    var ignored = 0;
    for (final observation in ordered) {
      if (accepted.length >= safeMaximum) break;
      if (!_isValidObservation(
        observation,
        vehicleId: cleanVehicleId,
        profileId: cleanProfileId,
        nowUtc: trustedNowUtc,
        maximumAge: safeAge,
      )) {
        ignored += 1;
        continue;
      }
      final sessionId = observation.sessionId.trim();
      if (!sessionIds.add(sessionId)) {
        ignored += 1;
        continue;
      }
      accepted.add(observation);
    }

    if (accepted.length < safeMinimum) {
      return TripDriverPatternDecision(
        confidence: TripDriverPatternConfidence.insufficient,
        suggestions: const [],
        reviewedTripCount: accepted.length,
        ignoredObservationCount: ignored,
        typicalStartMinuteUtc: null,
        typicalOdometerDistanceMiles: null,
        typicalConfirmedStopCount: null,
        suggestedStopReviewAfter: null,
        reasonCode: 'insufficient_confirmed_driver_history',
      );
    }

    final startMinutes = accepted
        .map((value) => value.startedAtUtc.toUtc())
        .map((value) => (value.hour * 60) + value.minute)
        .toList(growable: false);
    final typicalStart = _circularMeanMinute(startMinutes);
    final stableStartCount = startMinutes
        .where((value) => _circularMinuteDistance(value, typicalStart) <= 90)
        .length;
    final stopCounts = accepted
        .map((value) => value.confirmedStopCount)
        .toList(growable: false);
    final longestStopMinutes = accepted
        .map((value) => value.longestConfirmedStop.inMinutes)
        .toList(growable: false);
    final distances = accepted
        .map((value) => value.confirmedOdometerDistanceMiles)
        .toList(growable: false);
    final typicalStops = _medianInt(stopCounts);
    final typicalLongestStop = _medianInt(longestStopMinutes);
    final multiStopCount = stopCounts.where((value) => value >= 2).length;
    final extendedStopCount = longestStopMinutes
        .where((value) => value >= 15)
        .length;
    final suggestions = <TripDriverPatternSuggestion>[];
    if (stableStartCount / accepted.length >= 0.75) {
      suggestions.add(TripDriverPatternSuggestion.regularStartReminder);
    }
    if (typicalStops >= 2 && multiStopCount / accepted.length >= 0.65) {
      suggestions.add(TripDriverPatternSuggestion.multiStopWorkflow);
    }
    if (typicalLongestStop >= 15 &&
        extendedStopCount / accepted.length >= 0.65) {
      suggestions.add(TripDriverPatternSuggestion.extendedStopReviewTiming);
    }

    final confidence = switch (accepted.length) {
      >= 12 => TripDriverPatternConfidence.high,
      >= 8 => TripDriverPatternConfidence.medium,
      _ => TripDriverPatternConfidence.low,
    };
    return TripDriverPatternDecision(
      confidence: confidence,
      suggestions: List.unmodifiable(suggestions),
      reviewedTripCount: accepted.length,
      ignoredObservationCount: ignored,
      typicalStartMinuteUtc: typicalStart,
      typicalOdometerDistanceMiles: _rounded(_medianDouble(distances)),
      typicalConfirmedStopCount: typicalStops,
      suggestedStopReviewAfter:
          suggestions.contains(
            TripDriverPatternSuggestion.extendedStopReviewTiming,
          )
          ? Duration(minutes: typicalLongestStop.clamp(15, 180))
          : null,
      reasonCode: suggestions.isEmpty
          ? 'no_stable_driver_pattern'
          : 'confirmed_driver_pattern_available_for_review',
    );
  }
}

bool _isValidObservation(
  TripDriverPatternObservation observation, {
  required String vehicleId,
  required String profileId,
  required DateTime nowUtc,
  required Duration maximumAge,
}) {
  final startedAtUtc = observation.startedAtUtc.toUtc();
  final endedAtUtc = observation.endedAtUtc.toUtc();
  final age = nowUtc.difference(startedAtUtc);
  return observation.userReviewed &&
      observation.odometerConfirmed &&
      observation.sessionId.trim().isNotEmpty &&
      observation.vehicleId.trim() == vehicleId &&
      observation.profileId.trim() == profileId &&
      !startedAtUtc.isAfter(nowUtc) &&
      !endedAtUtc.isAfter(nowUtc) &&
      endedAtUtc.isAfter(startedAtUtc) &&
      endedAtUtc.difference(startedAtUtc) <= const Duration(days: 7) &&
      !age.isNegative &&
      age <= maximumAge &&
      observation.confirmedOdometerDistanceMiles.isFinite &&
      observation.confirmedOdometerDistanceMiles >= 0 &&
      observation.confirmedOdometerDistanceMiles <= 5000 &&
      observation.confirmedStopCount >= 0 &&
      observation.confirmedStopCount <= 1000 &&
      !observation.longestConfirmedStop.isNegative &&
      observation.longestConfirmedStop <= const Duration(days: 7);
}

TripDriverPatternDecision _emptyDecision({
  required int ignoredObservationCount,
  required String reasonCode,
}) => TripDriverPatternDecision(
  confidence: TripDriverPatternConfidence.insufficient,
  suggestions: const [],
  reviewedTripCount: 0,
  ignoredObservationCount: ignoredObservationCount,
  typicalStartMinuteUtc: null,
  typicalOdometerDistanceMiles: null,
  typicalConfirmedStopCount: null,
  suggestedStopReviewAfter: null,
  reasonCode: reasonCode,
);

int _circularMeanMinute(List<int> values) {
  var sine = 0.0;
  var cosine = 0.0;
  for (final value in values) {
    final angle = (value / 1440) * math.pi * 2;
    sine += math.sin(angle);
    cosine += math.cos(angle);
  }
  var angle = math.atan2(sine, cosine);
  if (angle < 0) angle += math.pi * 2;
  return ((angle / (math.pi * 2)) * 1440).round() % 1440;
}

int _circularMinuteDistance(int left, int right) {
  final direct = (left - right).abs();
  return math.min(direct, 1440 - direct);
}

int _medianInt(List<int> values) {
  final ordered = values.toList(growable: false)..sort();
  final middle = ordered.length ~/ 2;
  if (ordered.length.isOdd) return ordered[middle];
  return ((ordered[middle - 1] + ordered[middle]) / 2).round();
}

double _medianDouble(List<double> values) {
  final ordered = values.toList(growable: false)..sort();
  final middle = ordered.length ~/ 2;
  if (ordered.length.isOdd) return ordered[middle];
  return (ordered[middle - 1] + ordered[middle]) / 2;
}

double _rounded(double value) => double.parse(value.toStringAsFixed(1));
