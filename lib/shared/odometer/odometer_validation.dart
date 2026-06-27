import 'odometer_mileage_review.dart';
import 'odometer_correction_review.dart';

enum OdometerValidationSeverity { accepted, needsConfirmation, blocked }

class OdometerReadingEvent {
  const OdometerReadingEvent({
    this.id = '',
    required this.reading,
    required this.recordedAt,
    this.mileageReview,
    this.correctionReview,
    this.affectsCurrentReading = true,
    this.previousReading,
    this.workProfileId,
    this.sourceType,
    this.sourceId,
  });

  final String id;
  final int reading;
  final DateTime recordedAt;
  final OdometerMileageReview? mileageReview;
  final OdometerCorrectionReview? correctionReview;
  final bool affectsCurrentReading;
  final int? previousReading;
  final String? workProfileId;
  final String? sourceType;
  final String? sourceId;

  factory OdometerReadingEvent.fromMap(Map<dynamic, dynamic> map) {
    final mileageReviewValue = map['mileageReview'];
    final correctionReviewValue = map['correctionReview'];
    return OdometerReadingEvent(
      id: '${map['id'] ?? ''}',
      reading: map['reading'] is int
          ? map['reading'] as int
          : int.tryParse('${map['reading'] ?? ''}') ?? 0,
      recordedAt:
          DateTime.tryParse('${map['recordedAt'] ?? ''}') ?? DateTime.now(),
      mileageReview: mileageReviewValue is Map
          ? OdometerMileageReview.fromMap(mileageReviewValue)
          : null,
      correctionReview: correctionReviewValue is Map
          ? OdometerCorrectionReview.fromMap(correctionReviewValue)
          : null,
      affectsCurrentReading: map['affectsCurrentReading'] != false,
      previousReading: map['previousReading'] is int
          ? map['previousReading'] as int
          : int.tryParse('${map['previousReading'] ?? ''}'),
      workProfileId: map['workProfileId'] as String?,
      sourceType: map['sourceType'] as String?,
      sourceId: map['sourceId'] as String?,
    );
  }

  OdometerReadingEvent copyWith({
    String? id,
    int? reading,
    DateTime? recordedAt,
    OdometerMileageReview? mileageReview,
    OdometerCorrectionReview? correctionReview,
    bool? affectsCurrentReading,
    int? previousReading,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
  }) {
    return OdometerReadingEvent(
      id: id ?? this.id,
      reading: reading ?? this.reading,
      recordedAt: recordedAt ?? this.recordedAt,
      mileageReview: mileageReview ?? this.mileageReview,
      correctionReview: correctionReview ?? this.correctionReview,
      affectsCurrentReading:
          affectsCurrentReading ?? this.affectsCurrentReading,
      previousReading: previousReading ?? this.previousReading,
      workProfileId: workProfileId ?? this.workProfileId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'reading': reading,
      'recordedAt': recordedAt.toIso8601String(),
      'mileageReview': mileageReview?.toMap(),
      'correctionReview': correctionReview?.toMap(),
      'affectsCurrentReading': affectsCurrentReading,
      'previousReading': previousReading,
      'workProfileId': workProfileId,
      'sourceType': sourceType,
      'sourceId': sourceId,
    };
  }
}

class OdometerValidationResult {
  const OdometerValidationResult._({
    required this.severity,
    required this.message,
    this.averageDailyMiles,
    this.expectedMiles,
  });

  const OdometerValidationResult.accepted({
    String message = 'Odometer reading accepted.',
    double? averageDailyMiles,
    double? expectedMiles,
  }) : this._(
         severity: OdometerValidationSeverity.accepted,
         message: message,
         averageDailyMiles: averageDailyMiles,
         expectedMiles: expectedMiles,
       );

  const OdometerValidationResult.needsConfirmation({
    required String message,
    double? averageDailyMiles,
    double? expectedMiles,
  }) : this._(
         severity: OdometerValidationSeverity.needsConfirmation,
         message: message,
         averageDailyMiles: averageDailyMiles,
         expectedMiles: expectedMiles,
       );

  const OdometerValidationResult.blocked(String message)
    : this._(severity: OdometerValidationSeverity.blocked, message: message);

  final OdometerValidationSeverity severity;
  final String message;
  final double? averageDailyMiles;
  final double? expectedMiles;

  bool get isAccepted => severity == OdometerValidationSeverity.accepted;
  bool get needsConfirmation =>
      severity == OdometerValidationSeverity.needsConfirmation;
  bool get isBlocked => severity == OdometerValidationSeverity.blocked;
}

class OdometerValidationPolicy {
  const OdometerValidationPolicy({
    this.maxSupportedReading = 9999999,
    this.defaultReviewMiles = 500,
    this.minimumReviewBufferMiles = 100,
    this.extremeJumpMiles = 2500,
    this.drivingPatternReviewEnabled = true,
  });

  final int maxSupportedReading;
  final int defaultReviewMiles;
  final int minimumReviewBufferMiles;
  final int extremeJumpMiles;
  final bool drivingPatternReviewEnabled;

  OdometerValidationResult validate({
    required int currentReading,
    required int candidateReading,
    required List<OdometerReadingEvent> history,
    required DateTime enteredAt,
  }) {
    if (candidateReading < 0) {
      return const OdometerValidationResult.blocked(
        'Odometer readings cannot be negative.',
      );
    }
    if (candidateReading > maxSupportedReading) {
      return OdometerValidationResult.blocked(
        'This layout supports readings up to ${_comma(maxSupportedReading)} miles.',
      );
    }
    if (candidateReading < currentReading) {
      return OdometerValidationResult.blocked(
        'That reading is lower than the current odometer ${_comma(currentReading)}. Use a correction flow before rolling mileage backward.',
      );
    }
    if (candidateReading == currentReading) {
      return const OdometerValidationResult.accepted(
        message: 'Odometer reading is unchanged.',
      );
    }

    final delta = candidateReading - currentReading;
    if (!drivingPatternReviewEnabled) {
      return const OdometerValidationResult.accepted();
    }

    final trend = OdometerTrend.fromHistory(
      history,
      currentReading: currentReading,
      enteredAt: enteredAt,
    );
    final expectedMiles = trend.expectedMilesUntil(enteredAt);
    final expectedDailyMiles =
        trend.expectedDailyMilesFor(enteredAt) ?? trend.averageDailyMiles ?? 0;
    final reviewThreshold = trend.hasEnoughHistory
        ? expectedMiles + trend.reviewBufferMiles(minimumReviewBufferMiles)
        : defaultReviewMiles.toDouble();

    if (delta >= extremeJumpMiles || delta > reviewThreshold) {
      final average = trend.averageDailyMiles;
      final averageText = average == null
          ? 'No daily mileage average is available yet.'
          : 'Average daily miles: ${average.toStringAsFixed(1)}. Typical miles for this day: ${expectedDailyMiles.toStringAsFixed(1)}.';
      return OdometerValidationResult.needsConfirmation(
        message:
            'This odometer jump is ${_comma(delta)} miles, which is outside the expected range. $averageText Confirm the vehicle reading before saving.',
        averageDailyMiles: average,
        expectedMiles: expectedMiles,
      );
    }

    if (trend.hasEnoughHistory &&
        expectedMiles >= minimumReviewBufferMiles &&
        delta <
            expectedMiles - trend.reviewBufferMiles(minimumReviewBufferMiles)) {
      final average = trend.averageDailyMiles;
      return OdometerValidationResult.needsConfirmation(
        message:
            'This reading only adds ${_comma(delta)} miles, which is lower than the vehicle usually records for this time range. Average daily miles: ${average?.toStringAsFixed(1) ?? 'not available'}. Typical miles for this day: ${expectedDailyMiles.toStringAsFixed(1)}. Confirm the vehicle reading before saving.',
        averageDailyMiles: average,
        expectedMiles: expectedMiles,
      );
    }

    return OdometerValidationResult.accepted(
      averageDailyMiles: trend.averageDailyMiles,
      expectedMiles: expectedMiles,
    );
  }
}

class OdometerTrend {
  const OdometerTrend({
    required this.samples,
    required this.weekdaySamples,
    required this.lastReadingAt,
  });

  factory OdometerTrend.fromHistory(
    List<OdometerReadingEvent> history, {
    required int currentReading,
    required DateTime enteredAt,
  }) {
    final sorted = [...history]
      ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));
    final samples = <double>[];
    final weekdaySamples = <int, List<double>>{};
    for (var index = 1; index < sorted.length; index++) {
      final previous = sorted[index - 1];
      final current = sorted[index];
      final miles = current.reading - previous.reading;
      final hours = current.recordedAt.difference(previous.recordedAt).inHours;
      if (miles <= 0 || hours <= 0) continue;
      final days = hours / 24;
      if (days <= 0 || days > 45) continue;
      final dailyMiles = miles / days;
      samples.add(dailyMiles);
      final bucket = weekdaySamples.putIfAbsent(
        current.recordedAt.weekday,
        () => <double>[],
      );
      bucket.add(dailyMiles);
    }
    final lastAt = sorted.isEmpty ? enteredAt : sorted.last.recordedAt;
    final immutableWeekdaySamples = <int, List<double>>{};
    for (final entry in weekdaySamples.entries) {
      immutableWeekdaySamples[entry.key] = List<double>.unmodifiable(
        entry.value,
      );
    }
    return OdometerTrend(
      samples: samples,
      weekdaySamples: Map<int, List<double>>.unmodifiable(
        immutableWeekdaySamples,
      ),
      lastReadingAt: lastAt,
    );
  }

  final List<double> samples;
  final Map<int, List<double>> weekdaySamples;
  final DateTime lastReadingAt;

  bool get hasEnoughHistory => samples.length >= 2;

  double? get averageDailyMiles {
    if (samples.isEmpty) return null;
    return samples.reduce((sum, value) => sum + value) / samples.length;
  }

  double get _standardDeviation {
    final average = averageDailyMiles;
    if (average == null || samples.length < 2) return 0;
    final variance =
        samples
            .map((value) {
              final distance = value - average;
              return distance * distance;
            })
            .reduce((sum, value) => sum + value) /
        samples.length;
    return _sqrt(variance);
  }

  double expectedMilesUntil(DateTime enteredAt) {
    final average = expectedDailyMilesFor(enteredAt);
    if (average == null) return 0;
    final hours = enteredAt.difference(lastReadingAt).inHours;
    final days = hours <= 0 ? 1.0 : hours / 24;
    return average * days;
  }

  double? expectedDailyMilesFor(DateTime enteredAt) {
    final weekdayAverage = averageDailyMilesForWeekday(enteredAt.weekday);
    return weekdayAverage ?? averageDailyMiles;
  }

  double? averageDailyMilesForWeekday(int weekday) {
    final values = weekdaySamples[weekday];
    if (values == null || values.length < 2) return null;
    return values.reduce((sum, value) => sum + value) / values.length;
  }

  double reviewBufferMiles(int minimumBufferMiles) {
    final average = averageDailyMiles ?? 0;
    final variabilityBuffer = _standardDeviation * 2;
    final averageBuffer = average * .5;
    final buffer = [
      minimumBufferMiles.toDouble(),
      variabilityBuffer,
      averageBuffer,
    ].reduce((current, next) => current > next ? current : next);
    return buffer;
  }
}

String? parseOdometerInputError(String rawValue) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) return 'Enter an odometer reading.';
  final allowedSeparatorsRemoved = trimmed.replaceAll(RegExp(r'[,\s]'), '');
  if (!RegExp(r'^[0-9]+$').hasMatch(allowedSeparatorsRemoved)) {
    return 'Use numbers only for the odometer reading.';
  }
  return null;
}

int? parseOdometerInput(String rawValue) {
  final error = parseOdometerInputError(rawValue);
  if (error != null) return null;
  return int.tryParse(rawValue.replaceAll(RegExp(r'[,\s]'), ''));
}

String _comma(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final remaining = raw.length - index;
    buffer.write(raw[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

double _sqrt(double value) {
  if (value <= 0) return 0;
  var guess = value;
  for (var index = 0; index < 12; index++) {
    guess = .5 * (guess + value / guess);
  }
  return guess;
}
