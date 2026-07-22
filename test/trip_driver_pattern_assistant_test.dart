import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_driver_pattern_assistant.dart';

void main() {
  test('stable reviewed history produces advisory suggestions only', () {
    final decision = TripDriverPatternAssistant.evaluate(
      observations: _history(count: 12),
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      nowUtc: _now,
    );

    expect(decision.confidence, TripDriverPatternConfidence.high);
    expect(
      decision.suggestions,
      contains(TripDriverPatternSuggestion.regularStartReminder),
    );
    expect(
      decision.suggestions,
      contains(TripDriverPatternSuggestion.multiStopWorkflow),
    );
    expect(
      decision.suggestions,
      contains(TripDriverPatternSuggestion.extendedStopReviewTiming),
    );
    expect(decision.typicalOdometerDistanceMiles, 42);
    expect(decision.typicalConfirmedStopCount, 3);
    expect(decision.suggestedStopReviewAfter, const Duration(minutes: 25));
    expect(decision.toSafeSummary(), containsPair('canChangeOdometer', false));
    expect(
      decision.toSafeSummary(),
      containsPair('canChangeConfirmedMileage', false),
    );
    expect(decision.toSafeSummary(), containsPair('canFinalizeTrip', false));
    expect(
      decision.toSafeSummary(),
      containsPair('canClassifyBusinessUse', false),
    );
  });

  test('midnight start pattern uses circular time instead of midday', () {
    final observations = [
      for (var index = 0; index < 8; index += 1)
        _observation(
          index,
          startHour: index.isEven ? 23 : 0,
          startMinute: index.isEven ? 50 : 10,
        ),
    ];

    final decision = TripDriverPatternAssistant.evaluate(
      observations: observations,
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      nowUtc: _now,
    );

    expect(decision.confidence, TripDriverPatternConfidence.medium);
    expect(
      decision.suggestions,
      contains(TripDriverPatternSuggestion.regularStartReminder),
    );
    final typicalStart = decision.typicalStartMinuteUtc!;
    final distanceFromMidnight = typicalStart <= 720
        ? typicalStart
        : 1440 - typicalStart;
    expect(distanceFromMidnight, lessThanOrEqualTo(10));
  });

  test('history remains strictly scoped to vehicle and profile', () {
    final observations = [
      ..._history(count: 4),
      ..._history(count: 8, vehicleId: 'vehicle_2'),
      ..._history(count: 8, profileId: 'profile_2'),
    ];

    final decision = TripDriverPatternAssistant.evaluate(
      observations: observations,
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      nowUtc: _now,
    );

    expect(decision.confidence, TripDriverPatternConfidence.insufficient);
    expect(decision.reviewedTripCount, 4);
    expect(decision.ignoredObservationCount, 16);
    expect(decision.suggestions, isEmpty);
  });

  test('unreviewed GPS evidence cannot create a driver pattern', () {
    final observations = [
      for (var index = 0; index < 12; index += 1)
        _observation(index, userReviewed: false, odometerConfirmed: false),
    ];

    final decision = TripDriverPatternAssistant.evaluate(
      observations: observations,
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      nowUtc: _now,
    );

    expect(decision.confidence, TripDriverPatternConfidence.insufficient);
    expect(decision.reviewedTripCount, 0);
    expect(decision.ignoredObservationCount, 12);
    expect(decision.hasSuggestion, isFalse);
  });

  test(
    'duplicate sessions and future evidence are ignored deterministically',
    () {
      final valid = _history(count: 5);
      final observations = [
        ...valid,
        valid.first,
        _observation(99, startedAt: _now.add(const Duration(days: 1))),
      ];

      final decision = TripDriverPatternAssistant.evaluate(
        observations: observations,
        vehicleId: 'vehicle_1',
        profileId: 'profile_1',
        nowUtc: _now,
      );

      expect(decision.reviewedTripCount, 5);
      expect(decision.ignoredObservationCount, 2);
      expect(decision.confidence, TripDriverPatternConfidence.low);
    },
  );

  test('trip ending in the future is excluded from learned patterns', () {
    final valid = _history(count: 5);
    final futureEnding = TripDriverPatternObservation(
      sessionId: 'future_ending',
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      startedAtUtc: _now.subtract(const Duration(hours: 1)),
      endedAtUtc: _now.add(const Duration(hours: 1)),
      confirmedOdometerDistanceMiles: 20,
      confirmedStopCount: 1,
      longestConfirmedStop: const Duration(minutes: 5),
      userReviewed: true,
      odometerConfirmed: true,
    );

    final decision = TripDriverPatternAssistant.evaluate(
      observations: [...valid, futureEnding],
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      nowUtc: _now,
    );

    expect(decision.reviewedTripCount, 5);
    expect(decision.ignoredObservationCount, 1);
  });

  test('safe summary contains no identity route or raw evidence', () {
    final decision = TripDriverPatternAssistant.evaluate(
      observations: _history(count: 8),
      vehicleId: 'vehicle_secret',
      profileId: 'profile_secret',
      nowUtc: _now,
    );
    final summary = decision.toSafeSummary();

    expect(summary.values, isNot(contains('vehicle_secret')));
    expect(summary.values, isNot(contains('profile_secret')));
    expect(summary, containsPair('rawTripsIncluded', false));
    expect(summary, containsPair('rawLocationsIncluded', false));
    expect(summary, containsPair('sessionIdsIncluded', false));
    expect(summary, containsPair('odometerRemainsCanonical', true));
    expect(summary, containsPair('userConfirmationRequired', true));
  });

  test('invalid scope fails neutral without consuming raw evidence', () {
    final decision = TripDriverPatternAssistant.evaluate(
      observations: _history(count: 8),
      vehicleId: ' ',
      profileId: 'profile_1',
      nowUtc: _now,
    );

    expect(decision.confidence, TripDriverPatternConfidence.insufficient);
    expect(decision.reasonCode, 'missing_vehicle_or_profile_scope');
    expect(decision.suggestions, isEmpty);
  });
}

final _now = DateTime.utc(2026, 7, 22, 12);

List<TripDriverPatternObservation> _history({
  required int count,
  String vehicleId = 'vehicle_1',
  String profileId = 'profile_1',
}) => [
  for (var index = 0; index < count; index += 1)
    _observation(index, vehicleId: vehicleId, profileId: profileId),
];

TripDriverPatternObservation _observation(
  int index, {
  String vehicleId = 'vehicle_1',
  String profileId = 'profile_1',
  int startHour = 8,
  int startMinute = 15,
  bool userReviewed = true,
  bool odometerConfirmed = true,
  DateTime? startedAt,
}) {
  final start =
      startedAt ??
      DateTime.utc(2026, 7, 21 - index, startHour, startMinute + (index % 3));
  return TripDriverPatternObservation(
    sessionId: 'session_$index',
    vehicleId: vehicleId,
    profileId: profileId,
    startedAtUtc: start,
    endedAtUtc: start.add(const Duration(hours: 8)),
    confirmedOdometerDistanceMiles: 42,
    confirmedStopCount: 3,
    longestConfirmedStop: const Duration(minutes: 25),
    userReviewed: userReviewed,
    odometerConfirmed: odometerConfirmed,
  );
}
