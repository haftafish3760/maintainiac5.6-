part of 'expense_screen_telemetry.dart';

class ExpenseTelemetryRecord {
  const ExpenseTelemetryRecord({
    required this.id,
    required this.queuedAtUtc,
    required this.payload,
    this.uploadedAtUtc,
  });

  factory ExpenseTelemetryRecord.fromStored(Object? value) {
    if (value is! Map) return ExpenseTelemetryRecord.empty;
    try {
      final payload = value['payload'];
      return ExpenseTelemetryRecord(
        id: _stringValue(value['id']),
        queuedAtUtc:
            DateTime.tryParse(_stringValue(value['queuedAtUtc'])) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        uploadedAtUtc: DateTime.tryParse(_stringValue(value['uploadedAtUtc'])),
        payload: payload is Map
            ? ExpenseTelemetryPolicy.sanitizeMap(
                Map<String, Object?>.from(payload),
              )
            : const {},
      );
    } catch (_) {
      return ExpenseTelemetryRecord.empty;
    }
  }

  static final empty = ExpenseTelemetryRecord(
    id: '',
    queuedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    payload: const {},
  );

  final String id;
  final DateTime queuedAtUtc;
  final DateTime? uploadedAtUtc;
  final Map<String, Object?> payload;

  bool get isEmpty => id.isEmpty;
  bool get isPendingUpload => !isEmpty && uploadedAtUtc == null;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'queuedAtUtc': queuedAtUtc.toUtc().toIso8601String(),
      if (uploadedAtUtc != null)
        'uploadedAtUtc': uploadedAtUtc!.toUtc().toIso8601String(),
      'payload': ExpenseTelemetryPolicy.sanitizeMap(payload),
    };
  }
}
