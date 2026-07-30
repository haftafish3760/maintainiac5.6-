import '../../../shared/odometer/odometer_correction_review.dart';

/// Durable lower-odometer review records for an active workday.
///
/// Owns the evidence that an End Day reading needs human review. Does not
/// change the confirmed vehicle odometer, close a workday, or create a trip.
/// Consumed by ActiveWorkdayController and the End Day recovery flow.
class ActiveWorkdayOdometerReview {
  const ActiveWorkdayOdometerReview({
    required this.id,
    required this.createdAt,
    required this.startingOdometer,
    required this.enteredOdometer,
    required this.reason,
  });

  final String id;
  final DateTime createdAt;
  final int startingOdometer;
  final int enteredOdometer;
  final OdometerCorrectionReason reason;

  int get differenceMiles => startingOdometer - enteredOdometer;

  Map<String, Object?> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'startingOdometer': startingOdometer,
    'enteredOdometer': enteredOdometer,
    'reason': reason.name,
  };

  factory ActiveWorkdayOdometerReview.fromMap(Map<dynamic, dynamic> map) {
    final rawReason = map['reason']?.toString();
    return ActiveWorkdayOdometerReview(
      id: _safeOdometerReviewId(map['id']),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      startingOdometer: _safeReviewOdometer(map['startingOdometer']),
      enteredOdometer: _safeReviewOdometer(map['enteredOdometer']),
      reason: OdometerCorrectionReason.values.firstWhere(
        (value) => value.name == rawReason,
        orElse: () => OdometerCorrectionReason.unresolved,
      ),
    );
  }
}

int _safeReviewOdometer(Object? value) {
  final parsed = value is int ? value : int.tryParse('$value');
  return parsed == null || parsed < 0 ? 0 : parsed;
}

String _safeOdometerReviewId(Object? value) {
  final raw = value?.toString().trim() ?? '';
  return RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(raw)
      ? raw
      : 'invalid-review';
}
