import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_schema.dart';

part 'maintainiac_firestore_upload_policy.dart';
part 'maintainiac_firestore_upload_store.dart';

enum MaintainiacFirestoreUploadStatus {
  disabled,
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

class MaintainiacFirestoreQueuedDocument {
  const MaintainiacFirestoreQueuedDocument({
    required this.id,
    required this.path,
    required this.data,
    required this.queuedAtUtc,
    this.attemptCount = 0,
    this.lastAttemptAtUtc,
    this.lastError,
    this.uploadedAtUtc,
  });

  factory MaintainiacFirestoreQueuedDocument.fromStored(Object? value) {
    if (value is! Map) return MaintainiacFirestoreQueuedDocument.empty;
    final data = value['data'];
    return MaintainiacFirestoreQueuedDocument(
      id: value['id']?.toString() ?? '',
      path: value['path']?.toString() ?? '',
      data: data is Map ? Map<String, Object?>.from(data) : const {},
      queuedAtUtc:
          DateTime.tryParse(value['queuedAtUtc']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      attemptCount: _intValue(value['attemptCount']),
      lastAttemptAtUtc: DateTime.tryParse(
        value['lastAttemptAtUtc']?.toString() ?? '',
      ),
      lastError: value['lastError']?.toString(),
      uploadedAtUtc: DateTime.tryParse(
        value['uploadedAtUtc']?.toString() ?? '',
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
  final String? lastError;
  final DateTime? uploadedAtUtc;

  bool get isEmpty => id.isEmpty || path.isEmpty;
  bool get isPendingUpload => !isEmpty && uploadedAtUtc == null;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'path': path,
      'data': data,
      'queuedAtUtc': queuedAtUtc.toUtc().toIso8601String(),
      'attemptCount': attemptCount,
      if (lastAttemptAtUtc != null)
        'lastAttemptAtUtc': lastAttemptAtUtc!.toUtc().toIso8601String(),
      if (lastError != null && lastError!.trim().isNotEmpty)
        'lastError': _safeError(lastError!),
      if (uploadedAtUtc != null)
        'uploadedAtUtc': uploadedAtUtc!.toUtc().toIso8601String(),
    };
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _safeError(String value) {
  return value
      .replaceAll(RegExp(r'[^A-Za-z0-9_ .:/-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
