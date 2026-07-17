enum OdometerMileageUse {
  business('Business'),
  personal('Personal'),
  split('Business and personal'),
  calibration('Calibration / correction'),
  unresolved('Not sure yet');

  const OdometerMileageUse(this.label);

  final String label;
}

class OdometerMileageReview {
  const OdometerMileageReview({
    required this.use,
    this.businessMiles,
    this.note,
  });

  final OdometerMileageUse use;
  final int? businessMiles;
  final String? note;

  factory OdometerMileageReview.fromMap(Map<dynamic, dynamic> map) {
    return OdometerMileageReview(
      use: OdometerMileageUse.values.firstWhere(
        (value) => value.name == map['use'],
        orElse: () => OdometerMileageUse.unresolved,
      ),
      businessMiles: _optionalSafeMiles(map['businessMiles']),
      note: map['note'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'use': use.name,
      'businessMiles': _optionalSafeMiles(businessMiles),
      'note': note,
    };
  }

  bool get isResolvedForReports =>
      use == OdometerMileageUse.business ||
      use == OdometerMileageUse.personal ||
      use == OdometerMileageUse.split;

  int businessMilesForDelta(int deltaMiles) {
    switch (use) {
      case OdometerMileageUse.business:
        return deltaMiles;
      case OdometerMileageUse.personal:
      case OdometerMileageUse.calibration:
      case OdometerMileageUse.unresolved:
        return 0;
      case OdometerMileageUse.split:
        return businessMiles?.clamp(0, deltaMiles) ?? 0;
    }
  }

  int personalMilesForDelta(int deltaMiles) {
    switch (use) {
      case OdometerMileageUse.business:
      case OdometerMileageUse.calibration:
      case OdometerMileageUse.unresolved:
        return 0;
      case OdometerMileageUse.personal:
        return deltaMiles;
      case OdometerMileageUse.split:
        return deltaMiles - businessMilesForDelta(deltaMiles);
    }
  }
}

int? _optionalSafeMiles(Object? value) {
  if (value == null) return null;
  final parsed = value is int ? value : int.tryParse('$value');
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

String? validateOdometerMileageReview({
  required int deltaMiles,
  required OdometerMileageReview review,
}) {
  if (deltaMiles < 0) {
    return 'Mileage review cannot be applied to a lower odometer reading.';
  }
  if (review.use == OdometerMileageUse.split) {
    final businessMiles = review.businessMiles;
    if (businessMiles == null) {
      return 'Enter the business miles for this split.';
    }
    if (businessMiles < 0) {
      return 'Business miles cannot be negative.';
    }
    if (businessMiles > deltaMiles) {
      return 'Business miles cannot be more than the ${_comma(deltaMiles)} miles added.';
    }
  }
  return null;
}

String odometerMileageReviewPrompt(int deltaMiles) {
  return 'You added ${_comma(deltaMiles)} miles. Were these miles business, personal, both, a correction, or not sure yet?';
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
