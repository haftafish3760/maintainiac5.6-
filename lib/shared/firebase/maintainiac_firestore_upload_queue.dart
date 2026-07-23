import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'maintainiac_firestore_documents.dart';
import 'maintainiac_cloud_identity.dart';
import 'maintainiac_firestore_revision_policy.dart';
import 'maintainiac_firestore_scope_policy.dart';
import 'maintainiac_firestore_schema.dart';
import 'hosted_usage_limits.dart';
import 'maintainiac_hosted_plan_client.dart';
import '../trip_tracking/trip_tracking_firestore_contract.dart';
import '../storage/app_storage_guard.dart';

part 'maintainiac_firestore_upload_policy.dart';
part 'maintainiac_firestore_upload_store.dart';
part 'maintainiac_firestore_upload_coordinator.dart';

enum MaintainiacFirestoreUploadStatus {
  disabled,
  quotaExceeded,
  networkUnavailable,
  empty,
  uploaded,
  partial,
  failed,
  conflict,
}

class MaintainiacFirestoreUploadResult {
  const MaintainiacFirestoreUploadResult({
    required this.status,
    required this.attemptedCount,
    required this.uploadedCount,
    required this.failedCount,
    this.conflictedCount = 0,
    this.reason,
    this.reservationId,
  });

  final MaintainiacFirestoreUploadStatus status;
  final int attemptedCount;
  final int uploadedCount;
  final int failedCount;
  final int conflictedCount;
  final String? reason;
  final String? reservationId;
}

typedef MaintainiacFirestoreQueueStorageCheck =
    Future<AppStorageCheck> Function();
typedef MaintainiacFirestoreFreeSyncAttemptRecorder =
    Future<void> Function(DateTime nowUtc);
typedef MaintainiacHostedSyncReservationProvider =
    Future<MaintainiacHostedSyncReservation> Function();

/// Shared Firestore sink for module-specific backup coordinators. Keeping the
/// actual write primitive here prevents Expenses, Trips, and future modules
/// from inventing competing merge semantics.
class FirebaseFirestoreDocumentSink
    implements
        MaintainiacFirestoreDocumentSink,
        MaintainiacFirestoreBatchDocumentSink {
  FirebaseFirestoreDocumentSink({
    FirebaseFirestore? firestore,
    MaintainiacCloudIdentityProvider? identityProvider,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _identityProvider =
           identityProvider ?? FirebaseMaintainiacCloudIdentityProvider();

  final FirebaseFirestore _firestore;
  final MaintainiacCloudIdentityProvider _identityProvider;

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    MaintainiacFirestoreScopePolicy.validateWrite(
      path: path,
      data: data,
      authenticatedUid: _identityProvider.currentUid,
    );
    // Module builders emit complete backup documents. Replacing the document
    // prevents removed fields from surviving as stale cloud state and lets
    // Firestore rules compare exact idempotent retries safely.
    final reference = _firestore.doc(path);
    if (!MaintainiacFirestoreRevisionPolicy.isRevisioned(data)) {
      await reference.set(data, SetOptions(merge: false));
      return;
    }
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(reference);
      final decision = MaintainiacFirestoreRevisionPolicy.decide(
        incoming: data,
        existing: snapshot.data(),
      );
      if (decision.action == MaintainiacFirestoreRevisionAction.noOp) return;
      if (decision.action == MaintainiacFirestoreRevisionAction.conflict) {
        throw MaintainiacFirestoreRevisionConflict(
          path: path,
          localRevision: decision.localRevision,
          remoteRevision: decision.remoteRevision,
        );
      }
      transaction.set(reference, data, SetOptions(merge: false));
    });
  }

  @override
  Future<void> writeDocuments(
    List<MaintainiacFirestoreDocumentDraft> documents,
  ) async {
    if (documents.isEmpty) return;
    if (documents.length > MaintainiacFirestoreUploadPolicy.maxBatchSize) {
      throw ArgumentError('Firestore batch exceeds the approved limit.');
    }
    for (final document in documents) {
      MaintainiacFirestoreUploadPolicy.validateDraft(document);
      MaintainiacFirestoreScopePolicy.validateWrite(
        path: document.path,
        data: document.data,
        authenticatedUid: _identityProvider.currentUid,
      );
    }
    await _firestore.runTransaction<void>((transaction) async {
      final writes =
          <(DocumentReference<Map<String, dynamic>>, Map<String, Object?>)>[];
      for (final document in documents) {
        final reference = _firestore.doc(document.path);
        if (!MaintainiacFirestoreRevisionPolicy.isRevisioned(document.data)) {
          writes.add((reference, document.data));
          continue;
        }
        final snapshot = await transaction.get(reference);
        final decision = MaintainiacFirestoreRevisionPolicy.decide(
          incoming: document.data,
          existing: snapshot.data(),
        );
        if (decision.action == MaintainiacFirestoreRevisionAction.conflict) {
          throw MaintainiacFirestoreRevisionConflict(
            path: document.path,
            localRevision: decision.localRevision,
            remoteRevision: decision.remoteRevision,
          );
        }
        if (decision.action != MaintainiacFirestoreRevisionAction.noOp) {
          writes.add((reference, document.data));
        }
      }
      for (final write in writes) {
        transaction.set(write.$1, write.$2, SetOptions(merge: false));
      }
    });
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
    this.conflictedAtUtc,
  });

  factory MaintainiacFirestoreQueuedDocument.fromStored(Object? value) {
    if (value is! Map) return MaintainiacFirestoreQueuedDocument.empty;
    final data = _safeQueuedDocumentData(value['data']);
    final queuedAt =
        DateTime.tryParse(value['queuedAtUtc']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final attemptCount = _nonNegativeIntValue(value['attemptCount']);
    final lastAttemptAt = attemptCount == 0
        ? null
        : _safeQueueTimestamp(
            value['lastAttemptAtUtc'],
            notBefore: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          );
    final nextAttemptAt = lastAttemptAt == null
        ? null
        : _safeQueueTimestamp(
            value['nextAttemptAtUtc'],
            notBefore: lastAttemptAt,
          );
    return MaintainiacFirestoreQueuedDocument(
      id: value['id']?.toString() ?? '',
      path: value['path']?.toString() ?? '',
      data: data,
      queuedAtUtc: queuedAt,
      attemptCount: attemptCount,
      lastAttemptAtUtc: lastAttemptAt,
      nextAttemptAtUtc: nextAttemptAt,
      lastError: value['lastError'] == null
          ? null
          : _safeError(value['lastError'].toString()),
      uploadedAtUtc: _safeQueueTimestamp(
        value['uploadedAtUtc'],
        notBefore: queuedAt,
      ),
      conflictedAtUtc: _safeQueueTimestamp(
        value['conflictedAtUtc'],
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
  final DateTime? conflictedAtUtc;

  bool get isEmpty => id.isEmpty || path.isEmpty;
  bool get isPendingUpload =>
      !isEmpty && uploadedAtUtc == null && conflictedAtUtc == null;
  bool get requiresConflictReview => conflictedAtUtc != null;
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
      if (conflictedAtUtc != null)
        'conflictedAtUtc': conflictedAtUtc!.toUtc().toIso8601String(),
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
      )
      .replaceAll(
        RegExp(r'\b-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}\b'),
        'coordinates=[redacted]',
      );
  return redacted
      .replaceAll(RegExp(r'[^A-Za-z0-9_ .:/-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Map<String, Object?> _safeQueuedDocumentData(Object? value) {
  if (value is! Map) return const {};
  final safe = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is String && key.trim() == key && key.isNotEmpty) {
      safe[key] = entry.value;
    }
  }
  return Map.unmodifiable(safe);
}
