part of 'expense_receipt_privacy_event_store.dart';

class PrivacySafeReceiptEventRecord {
  const PrivacySafeReceiptEventRecord({
    required this.id,
    required this.queuedAtUtc,
    required this.payload,
    this.uploadedAtUtc,
  });

  factory PrivacySafeReceiptEventRecord.fromStored(Object? value) {
    if (value is! Map) return PrivacySafeReceiptEventRecord.empty;
    try {
      final payload = value['payload'];
      return PrivacySafeReceiptEventRecord(
        id: _stringValue(value['id']),
        queuedAtUtc:
            DateTime.tryParse(_stringValue(value['queuedAtUtc'])) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        uploadedAtUtc: DateTime.tryParse(_stringValue(value['uploadedAtUtc'])),
        payload: payload is Map
            ? ReceiptPrivacyEventPolicy.sanitizeMap(
                Map<String, Object?>.from(payload),
              )
            : const {},
      );
    } catch (_) {
      return PrivacySafeReceiptEventRecord.empty;
    }
  }

  static final empty = PrivacySafeReceiptEventRecord(
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
      'payload': ReceiptPrivacyEventPolicy.sanitizeMap(payload),
    };
  }
}
