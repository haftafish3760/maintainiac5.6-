enum OdometerCorrectionReason {
  typedWrong('Typed the wrong number'),
  wrongVehicle('Wrong vehicle selected'),
  backdatedEntry('Backdated receipt or trip'),
  previousEntryWrong('Previous odometer entry was wrong'),
  odometerReplaced('Odometer repaired or replaced'),
  unresolved('Not sure yet');

  const OdometerCorrectionReason(this.label);

  final String label;
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
      reason == OdometerCorrectionReason.previousEntryWrong ||
      reason == OdometerCorrectionReason.odometerReplaced;

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
    return 'Correction review is only needed when the new reading is lower than the current odometer.';
  }
  if (review.reason == OdometerCorrectionReason.unresolved) {
    return null;
  }
  if (review.shouldStopAndLetUserRetry) {
    return 'Review the vehicle and odometer number before saving.';
  }
  if (review.requiresDedicatedCorrectionFlow) {
    return 'This needs the odometer correction flow so the app can keep the audit trail clean.';
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
  return 'This reading is ${_comma(difference)} miles lower than the current odometer ${_comma(currentReading)}. What happened?';
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
