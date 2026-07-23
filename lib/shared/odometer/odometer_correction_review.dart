enum OdometerCorrectionReason {
  typedWrong('Correct the entered reading'),
  wrongVehicle('Choose a different vehicle'),
  backdatedEntry('This is a backdated receipt or trip'),
  previousEntryWrong('Review the previous odometer entry'),
  odometerReplaced('The odometer was repaired or replaced'),
  odometerRolledOver('The odometer completed a rollover'),
  unitsChanged('The distance unit setting changed'),
  unresolved('I’m not sure yet');

  const OdometerCorrectionReason(this.label);

  final String label;

  bool get requiresDedicatedCorrectionFlow =>
      this == OdometerCorrectionReason.previousEntryWrong ||
      this == OdometerCorrectionReason.odometerReplaced ||
      this == OdometerCorrectionReason.odometerRolledOver ||
      this == OdometerCorrectionReason.unitsChanged;
}

class OdometerCorrectionReview {
  const OdometerCorrectionReview({required this.reason, this.note});

  final OdometerCorrectionReason reason;
  final String? note;

  factory OdometerCorrectionReview.fromMap(Map<dynamic, dynamic> map) {
    return OdometerCorrectionReview(
      reason: OdometerCorrectionReason.values.firstWhere(
        (value) => value.name == map['reason'],
        orElse: () => OdometerCorrectionReason.unresolved,
      ),
      note: _optionalSafeNote(map['note']),
    );
  }

  Map<String, Object?> toMap() {
    return {'reason': reason.name, 'note': _optionalSafeNote(note)};
  }

  bool get canSaveHistoricalReading =>
      reason == OdometerCorrectionReason.backdatedEntry;

  bool get requiresDedicatedCorrectionFlow =>
      reason.requiresDedicatedCorrectionFlow;

  bool get shouldStopAndLetUserRetry =>
      reason == OdometerCorrectionReason.typedWrong ||
      reason == OdometerCorrectionReason.wrongVehicle;
}

String? validateOdometerCorrectionReview({
  required int currentReading,
  required int candidateReading,
  required OdometerCorrectionReview review,
}) {
  if (candidateReading >= currentReading) {
    return 'This review is only needed when the entered reading is lower than the saved odometer.';
  }
  if (review.reason == OdometerCorrectionReason.unresolved) {
    return null;
  }
  if (review.shouldStopAndLetUserRetry) {
    return 'Please verify the selected vehicle and odometer reading before continuing.';
  }
  if (review.requiresDedicatedCorrectionFlow) {
    return 'Please continue through the odometer correction review so the vehicle record remains accurate.';
  }
  return null;
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

String odometerCorrectionReviewPrompt({
  required int currentReading,
  required int candidateReading,
}) {
  final difference = currentReading - candidateReading;
  return 'This reading is ${_comma(difference)} miles below your previous entry of ${_comma(currentReading)} miles.';
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
