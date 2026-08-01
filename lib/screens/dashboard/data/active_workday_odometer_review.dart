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
    this.startingOdometerTenths,
    required this.enteredOdometer,
    this.enteredOdometerTenths,
    required this.reason,
  });

  final String id;
  final DateTime createdAt;
  final int startingOdometer;
  final int? startingOdometerTenths;
  final int enteredOdometer;
  final int? enteredOdometerTenths;
  final OdometerCorrectionReason reason;

  int get differenceMiles => startingOdometer - enteredOdometer;
  int get effectiveStartingOdometerTenths =>
      startingOdometerTenths ?? startingOdometer * 10;
  int get effectiveEnteredOdometerTenths =>
      enteredOdometerTenths ?? enteredOdometer * 10;
  int get differenceTenths =>
      effectiveStartingOdometerTenths - effectiveEnteredOdometerTenths;

  Map<String, Object?> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'startingOdometer': startingOdometer,
    if (startingOdometerTenths != null)
      'startingOdometerTenths': startingOdometerTenths,
    'enteredOdometer': enteredOdometer,
    if (enteredOdometerTenths != null)
      'enteredOdometerTenths': enteredOdometerTenths,
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
      startingOdometerTenths: _safeReviewOdometerTenths(
        map['startingOdometerTenths'],
      ),
      enteredOdometer: _safeReviewOdometer(map['enteredOdometer']),
      enteredOdometerTenths: _safeReviewOdometerTenths(
        map['enteredOdometerTenths'],
      ),
      reason: OdometerCorrectionReason.values.firstWhere(
        (value) => value.name == rawReason,
        orElse: () => OdometerCorrectionReason.unresolved,
      ),
    );
  }
}

int? _safeReviewOdometerTenths(Object? value) {
  if (value == null) return null;
  final parsed = value is int ? value : int.tryParse('$value');
  return parsed == null || parsed < 0 || parsed > 99999999 ? null : parsed;
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
