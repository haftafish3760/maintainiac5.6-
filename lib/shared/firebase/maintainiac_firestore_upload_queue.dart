import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_schema.dart';
import 'hosted_usage_limits.dart';
import '../trip_tracking/trip_tracking_firestore_contract.dart';
import '../storage/app_storage_guard.dart';

part 'maintainiac_firestore_upload_policy.dart';
part 'maintainiac_firestore_upload_store.dart';

enum MaintainiacFirestoreUploadStatus {
  disabled,
  quotaExceeded,
  networkUnavailable,
  empty,
  uploaded,
  partial,
  failed,
}

class MaintainiacFirestoreUploadResult {
  const MaintainiacFirestoreUploadResult({
    required this.status,
    required this.attemptedCount,
    required this.uploadedCount,
    required this.failedCount,
    this.reason,
  });

  final MaintainiacFirestoreUploadStatus status;
  final int attemptedCount;
  final int uploadedCount;
  final int failedCount;
  final String? reason;
}

typedef MaintainiacFirestoreQueueStorageCheck =
    Future<AppStorageCheck> Function();

/// Shared Firestore sink for module-specific backup coordinators. Keeping the
/// actual write primitive here prevents Expenses, Trips, and future modules
/// from inventing competing merge semantics.
class FirebaseFirestoreDocumentSink
    implements MaintainiacFirestoreDocumentSink {
  FirebaseFirestoreDocumentSink({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) {
    return _firestore.doc(path).set(data, SetOptions(merge: true));
  }
}

class MaintainiacFirestoreQueuedDocument {
  const MaintainiacFirestoreQueuedDocument({
    required this.id,
    required this.path,
    required this.data,
    required this.queuedAtUtc,
    this.attemptCount = 0,
    this.lastAttemptAtUtc,
    this.nextAttemptAtUtc,
    this.lastError,
    this.uploadedAtUtc,
  });

  factory MaintainiacFirestoreQueuedDocument.fromStored(Object? value) {
    if (value is! Map) return MaintainiacFirestoreQueuedDocument.empty;
    final data = value['data'];
    final queuedAt =
        DateTime.tryParse(value['queuedAtUtc']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final lastAttemptAt = _safeQueueTimestamp(
      value['lastAttemptAtUtc'],
      notBefore: queuedAt,
    );
    final nextAttemptAt = _safeQueueTimestamp(
      value['nextAttemptAtUtc'],
      notBefore: lastAttemptAt ?? queuedAt,
    );
    return MaintainiacFirestoreQueuedDocument(
      id: value['id']?.toString() ?? '',
      path: value['path']?.toString() ?? '',
      data: data is Map ? Map<String, Object?>.from(data) : const {},
      queuedAtUtc: queuedAt,
      attemptCount: _nonNegativeIntValue(value['attemptCount']),
      lastAttemptAtUtc: lastAttemptAt,
      nextAttemptAtUtc: nextAttemptAt,
      lastError: value['lastError'] == null
          ? null
          : _safeError(value['lastError'].toString()),
      uploadedAtUtc: _safeQueueTimestamp(
        value['uploadedAtUtc'],
        notBefore: queuedAt,
      ),
    );
  }

  static final empty = MaintainiacFirestoreQueuedDocument(
    id: '',
    path: '',
    data: const {},
    queuedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final String id;
  final String path;
  final Map<String, Object?> data;
  final DateTime queuedAtUtc;
  final int attemptCount;
  final DateTime? lastAttemptAtUtc;
  final DateTime? nextAttemptAtUtc;
  final String? lastError;
  final DateTime? uploadedAtUtc;

  bool get isEmpty => id.isEmpty || path.isEmpty;
  bool get isPendingUpload => !isEmpty && uploadedAtUtc == null;
  bool isReadyForAttemptAt(DateTime nowUtc) =>
      nextAttemptAtUtc == null || !nowUtc.isBefore(nextAttemptAtUtc!);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'path': path,
      'data': data,
      'queuedAtUtc': queuedAtUtc.toUtc().toIso8601String(),
      'attemptCount': attemptCount,
      if (lastAttemptAtUtc != null)
        'lastAttemptAtUtc': lastAttemptAtUtc!.toUtc().toIso8601String(),
      if (nextAttemptAtUtc != null)
        'nextAttemptAtUtc': nextAttemptAtUtc!.toUtc().toIso8601String(),
      if (lastError != null && lastError!.trim().isNotEmpty)
        'lastError': _safeError(lastError!),
      if (uploadedAtUtc != null)
        'uploadedAtUtc': uploadedAtUtc!.toUtc().toIso8601String(),
    };
  }
}

int _nonNegativeIntValue(Object? value) {
  final parsed = value is int
      ? value
      : value is num && value.isFinite
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
  return parsed < 0 ? 0 : parsed;
}

DateTime? _safeQueueTimestamp(Object? value, {required DateTime notBefore}) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed.isBefore(notBefore)) return null;
  return parsed.toUtc();
}

String _safeError(String value) {
  final redacted = value
      .replaceAll(RegExp(r'\b[ps]k\.[A-Za-z0-9._-]+'), '[redacted_token]')
      .replaceAll(
        RegExp(r'\btoken\s*=\s*[^,\s;]+', caseSensitive: false),
        'token=[redacted]',
      )
      .replaceAllMapped(
        RegExp(
          r'\b(lat|latitude|lon|lng|longitude)\s*[:=]\s*-?\d+(\.\d+)?',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)} redacted',
      );
  return redacted
      .replaceAll(RegExp(r'[^A-Za-z0-9_ .:/-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
