class TripTrackingRecoveryDiagnostic {
  const TripTrackingRecoveryDiagnostic({
    required this.code,
    required this.recordedAtUtc,
    required this.expectedGeneration,
    required this.restoredGeneration,
  });

  final String code;
  final DateTime recordedAtUtc;
  final int expectedGeneration;
  final int restoredGeneration;

  Map<String, Object?> toMap() => {
    'code': code,
    'recordedAtUtc': recordedAtUtc.toUtc().toIso8601String(),
    'expectedGeneration': expectedGeneration,
    'restoredGeneration': restoredGeneration,
  };

  static TripTrackingRecoveryDiagnostic? tryFromMap(Map<dynamic, dynamic> map) {
    final code = map['code'];
    final recordedAt = DateTime.tryParse('${map['recordedAtUtc'] ?? ''}');
    final expected = map['expectedGeneration'];
    final restored = map['restoredGeneration'];
    if (code is! String ||
        code.isEmpty ||
        recordedAt == null ||
        expected is! int ||
        expected < 0 ||
        restored is! int ||
        restored < 0) {
      return null;
    }
    return TripTrackingRecoveryDiagnostic(
      code: code,
      recordedAtUtc: recordedAt.toUtc(),
      expectedGeneration: expected,
      restoredGeneration: restored,
    );
  }
}
