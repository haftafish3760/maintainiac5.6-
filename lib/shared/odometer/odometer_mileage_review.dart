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
    this.businessTenths,
    this.note,
  });

  final OdometerMileageUse use;
  final int? businessMiles;
  final int? businessTenths;
  final String? note;

  factory OdometerMileageReview.fromMap(Map<dynamic, dynamic> map) {
    return OdometerMileageReview(
      use: OdometerMileageUse.values.firstWhere(
        (value) => value.name == map['use'],
        orElse: () => OdometerMileageUse.unresolved,
      ),
      businessMiles: _optionalSafeMiles(map['businessMiles']),
      businessTenths: _optionalSafeTenths(map['businessTenths']),
      note: _optionalSafeNote(map['note']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'use': use.name,
      'businessMiles': _optionalSafeMiles(businessMiles),
      'businessTenths': effectiveBusinessTenths,
      'note': _optionalSafeNote(note),
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

  int businessTenthsForDelta(int deltaTenths) {
    switch (use) {
      case OdometerMileageUse.business:
        return deltaTenths;
      case OdometerMileageUse.personal:
      case OdometerMileageUse.calibration:
      case OdometerMileageUse.unresolved:
        return 0;
      case OdometerMileageUse.split:
        return (effectiveBusinessTenths ?? 0).clamp(0, deltaTenths);
    }
  }

  int? get effectiveBusinessTenths =>
      _optionalSafeTenths(businessTenths) ??
      (_optionalSafeMiles(businessMiles) == null ? null : businessMiles! * 10);

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

String? _optionalSafeNote(Object? value) {
  if (value == null) return null;
  final clean = '$value'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (clean.isEmpty) return null;
  return clean.length > 240 ? clean.substring(0, 240) : clean;
}

int? _optionalSafeMiles(Object? value) {
  if (value == null) return null;
  final parsed = value is int ? value : int.tryParse('$value');
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

int? _optionalSafeTenths(Object? value) {
  if (value == null) return null;
  final parsed = value is int ? value : int.tryParse('$value');
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

String? validateOdometerMileageReview({
  required int deltaMiles,
  int? deltaTenths,
  required OdometerMileageReview review,
}) {
  final exactDelta = deltaTenths ?? deltaMiles * 10;
  if (exactDelta < 0) {
    return 'Mileage review cannot be applied to a lower odometer reading.';
  }
  if (review.use == OdometerMileageUse.split) {
    final businessTenths = review.effectiveBusinessTenths;
    if (businessTenths == null) {
      return 'Enter the business miles for this split.';
    }
    if (businessTenths > exactDelta) {
      return 'Business miles cannot be more than the ${_formatTenths(exactDelta)} miles added.';
    }
  }
  return null;
}

String odometerMileageReviewPrompt(int deltaMiles) {
  return 'You added ${_comma(deltaMiles)} miles. Were these miles business, personal, both, a correction, or not sure yet?';
}

String odometerMileageReviewPromptTenths(int deltaTenths) {
  return 'You added ${_formatTenths(deltaTenths)} miles. Were these miles business, personal, both, a correction, or not sure yet?';
}

String _formatTenths(int tenths) {
  final whole = _comma(tenths ~/ 10);
  final fraction = tenths % 10;
  return fraction == 0 ? whole : '$whole.$fraction';
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
