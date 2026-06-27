import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_schema.dart';

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

class MaintainiacFirestoreUploadPolicy {
  const MaintainiacFirestoreUploadPolicy._();

  static const maxBatchSize = 20;
  static const maxQueuedRecords = 500;
  static const maxDocumentBytes = 768 * 1024;

  static const allowedTopLevelCollections = <String>{
    MaintainiacFirestoreSchema.orgs,
    MaintainiacFirestoreSchema.catalogPacks,
    MaintainiacFirestoreSchema.parserHealth,
    MaintainiacFirestoreSchema.catalogHealth,
    MaintainiacFirestoreSchema.sharedCorrectionCandidates,
  };

  static const blockedSensitiveKeys = <String>{
    'rawReceiptText',
    'receiptText',
    'ocrText',
    'merchantName',
    'storeName',
    'customerName',
    'jobName',
    'description',
    'correctedDescription',
    'catalogItemName',
    'itemName',
    'lineText',
    'address',
    'phone',
    'email',
    'vin',
    'plateNumber',
  };

  static const blockedEverywhereKeys = <String>{
    'rawReceiptText',
    'rawOcrText',
    'ocrText',
    'importedText',
    'localPath',
    'path',
    'vin',
    'VIN',
    'vehicleIdentificationNumber',
    'licensePlate',
    'plate',
    'plateNumber',
    'tagNumber',
    'passengerName',
    'passengerPhone',
    'passengerAddress',
    'patientName',
    'patientPhone',
    'patientAddress',
    'medicalRecordNumber',
    'diagnosis',
    'dateOfBirth',
    'dob',
  };

  static void validateDraft(MaintainiacFirestoreDocumentDraft draft) {
    _validatePath(draft.path);
    _validateDocumentSize(draft);
    _validateNoSensitiveKeys(
      draft.data,
      allowPrivateExpenseBackup: _isPrivateExpenseBackupPath(draft.path),
    );
    _validateCatalogReadShape(draft);
  }

  static void _validatePath(String path) {
    final clean = path.trim();
    if (clean.isEmpty ||
        clean.startsWith('/') ||
        clean.endsWith('/') ||
        clean.contains('//') ||
        clean.contains('..')) {
      throw ArgumentError.value(path, 'path', 'Unsafe Firestore path.');
    }
    final parts = clean.split('/');
    if (parts.length.isOdd) {
      throw ArgumentError.value(path, 'path', 'Path must target a document.');
    }
    if (!allowedTopLevelCollections.contains(parts.first)) {
      throw ArgumentError.value(
        path,
        'path',
        'Unsupported top-level collection.',
      );
    }
  }

  static void _validateDocumentSize(MaintainiacFirestoreDocumentDraft draft) {
    final bytes = utf8.encode(jsonEncode(draft.data)).length;
    if (bytes > maxDocumentBytes) {
      throw ArgumentError.value(
        bytes,
        draft.path,
        'Firestore document is too large for the guarded queue.',
      );
    }
  }

  static bool _isPrivateExpenseBackupPath(String path) {
    final parts = path.trim().split('/');
    return parts.length >= 4 &&
        parts.first == MaintainiacFirestoreSchema.orgs &&
        (parts[2] == MaintainiacFirestoreSchema.orgExpenses ||
            parts[2] == MaintainiacFirestoreSchema.orgSettings);
  }

  static void _validateNoSensitiveKeys(
    Object? value, {
    String parent = '',
    bool allowPrivateExpenseBackup = false,
  }) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final blocked = allowPrivateExpenseBackup
            ? blockedEverywhereKeys.contains(key)
            : blockedSensitiveKeys.contains(key);
        if (blocked) {
          throw ArgumentError.value(
            key,
            parent,
            'Sensitive field is not allowed in Firestore upload queue.',
          );
        }
        _validateNoSensitiveKeys(
          entry.value,
          parent: key,
          allowPrivateExpenseBackup: allowPrivateExpenseBackup,
        );
      }
    } else if (value is Iterable) {
      for (final item in value) {
        _validateNoSensitiveKeys(
          item,
          parent: parent,
          allowPrivateExpenseBackup: allowPrivateExpenseBackup,
        );
      }
    }
  }

  static void _validateCatalogReadShape(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    if (!draft.path.startsWith('${MaintainiacFirestoreSchema.catalogPacks}/')) {
      return;
    }
    if (draft.data['firestoreItemDocumentReadCount'] != 0) {
      throw ArgumentError.value(
        draft.data['firestoreItemDocumentReadCount'],
        draft.path,
        'Catalog packs must never require item-document reads.',
      );
    }
    if (draft.data['deliveryMode'] != 'manifest_storage_chunks') {
      throw ArgumentError.value(
        draft.data['deliveryMode'],
        draft.path,
        'Catalog packs must use manifest plus Storage chunks.',
      );
    }
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

class MaintainiacFirestoreUploadQueueStore {
  MaintainiacFirestoreUploadQueueStore._(this._box);

  static const boxName = 'maintainiac_firestore_upload_queue';

  final Box<dynamic> _box;

  static Future<MaintainiacFirestoreUploadQueueStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return MaintainiacFirestoreUploadQueueStore._(box);
  }

  List<MaintainiacFirestoreQueuedDocument> get records {
    final loaded = <MaintainiacFirestoreQueuedDocument>[];
    for (final value in _box.values) {
      final record = MaintainiacFirestoreQueuedDocument.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  List<MaintainiacFirestoreQueuedDocument> get pendingRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  Future<MaintainiacFirestoreQueuedDocument> enqueue(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
  }) async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = MaintainiacFirestoreQueuedDocument(
      id: _recordIdFor(draft.path, queuedAt),
      path: draft.path,
      data: Map<String, Object?>.unmodifiable(draft.data),
      queuedAtUtc: queuedAt,
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  Future<MaintainiacFirestoreQueuedDocument> enqueueReplacingPendingForPath(
    MaintainiacFirestoreDocumentDraft draft, {
    DateTime? queuedAtUtc,
  }) async {
    MaintainiacFirestoreUploadPolicy.validateDraft(draft);
    for (final record in pendingRecords) {
      if (record.path == draft.path) {
        await _box.delete(record.id);
      }
    }
    return enqueue(draft, queuedAtUtc: queuedAtUtc);
  }

  Future<List<MaintainiacFirestoreQueuedDocument>> enqueueAll(
    Iterable<MaintainiacFirestoreDocumentDraft> drafts, {
    DateTime? queuedAtUtc,
  }) async {
    final queued = <MaintainiacFirestoreQueuedDocument>[];
    for (final draft in drafts) {
      queued.add(await enqueue(draft, queuedAtUtc: queuedAtUtc));
    }
    return List.unmodifiable(queued);
  }

  List<MaintainiacFirestoreQueuedDocument> nextBatch({int? limit}) {
    final cappedLimit = (limit ?? MaintainiacFirestoreUploadPolicy.maxBatchSize)
        .clamp(0, MaintainiacFirestoreUploadPolicy.maxBatchSize)
        .toInt();
    return List.unmodifiable(pendingRecords.take(cappedLimit));
  }

  Future<void> markAttempted(
    MaintainiacFirestoreQueuedDocument record, {
    required String error,
    DateTime? nowUtc,
  }) async {
    if (record.isEmpty) return;
    final attempted = MaintainiacFirestoreQueuedDocument(
      id: record.id,
      path: record.path,
      data: record.data,
      queuedAtUtc: record.queuedAtUtc,
      attemptCount: record.attemptCount + 1,
      lastAttemptAtUtc: (nowUtc ?? DateTime.now().toUtc()).toUtc(),
      lastError: error,
      uploadedAtUtc: record.uploadedAtUtc,
    );
    await _box.put(attempted.id, attempted.toMap());
  }

  Future<void> markUploaded(
    Iterable<String> recordIds, {
    DateTime? nowUtc,
  }) async {
    final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final id in recordIds) {
      final record = MaintainiacFirestoreQueuedDocument.fromStored(
        _box.get(id),
      );
      if (record.isEmpty) continue;
      final uploaded = MaintainiacFirestoreQueuedDocument(
        id: record.id,
        path: record.path,
        data: record.data,
        queuedAtUtc: record.queuedAtUtc,
        attemptCount: record.attemptCount,
        lastAttemptAtUtc: record.lastAttemptAtUtc,
        lastError: record.lastError,
        uploadedAtUtc: uploadedAt,
      );
      await _box.put(uploaded.id, uploaded.toMap());
    }
  }

  Future<void> clearUploaded() async {
    for (final record in records) {
      if (record.uploadedAtUtc != null) {
        await _box.delete(record.id);
      }
    }
  }

  Future<void> clearAll() => _box.clear();

  Future<void> _trimOldestIfNeeded() async {
    final extraCount =
        records.length - MaintainiacFirestoreUploadPolicy.maxQueuedRecords;
    if (extraCount <= 0) return;
    for (final record in records.take(extraCount)) {
      await _box.delete(record.id);
    }
  }

  String _recordIdFor(String path, DateTime queuedAtUtc) {
    final basePath = path
        .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final base = '${queuedAtUtc.microsecondsSinceEpoch}_$basePath';
    var id = base;
    var suffix = 1;
    while (_box.containsKey(id)) {
      id = '$base-$suffix';
      suffix += 1;
    }
    return id;
  }
}

abstract class MaintainiacFirestoreDocumentSink {
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  });
}

class MaintainiacFirestoreUploadCoordinator {
  const MaintainiacFirestoreUploadCoordinator({
    required MaintainiacFirestoreUploadQueueStore queue,
    required MaintainiacFirestoreDocumentSink sink,
    bool uploadEnabled = false,
  }) : _queue = queue,
       _sink = sink,
       _uploadEnabled = uploadEnabled;

  final MaintainiacFirestoreUploadQueueStore _queue;
  final MaintainiacFirestoreDocumentSink _sink;
  final bool _uploadEnabled;

  Future<MaintainiacFirestoreUploadResult> uploadPending({
    int? limit,
    DateTime? nowUtc,
  }) async {
    if (!_uploadEnabled) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.disabled,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
        reason: 'Firestore uploads are disabled until hosted sync is enabled.',
      );
    }

    final batch = _queue.nextBatch(limit: limit);
    if (batch.isEmpty) {
      return const MaintainiacFirestoreUploadResult(
        status: MaintainiacFirestoreUploadStatus.empty,
        attemptedCount: 0,
        uploadedCount: 0,
        failedCount: 0,
      );
    }

    var uploadedCount = 0;
    var failedCount = 0;
    final uploadedIds = <String>[];
    for (final record in batch) {
      try {
        MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(
            path: record.path,
            data: record.data,
          ),
        );
        await _sink.writeDocument(path: record.path, data: record.data);
        uploadedIds.add(record.id);
        uploadedCount += 1;
      } catch (error) {
        failedCount += 1;
        await _queue.markAttempted(
          record,
          error: error.toString(),
          nowUtc: nowUtc,
        );
      }
    }
    await _queue.markUploaded(uploadedIds, nowUtc: nowUtc);

    final status = failedCount == 0
        ? MaintainiacFirestoreUploadStatus.uploaded
        : uploadedCount == 0
        ? MaintainiacFirestoreUploadStatus.failed
        : MaintainiacFirestoreUploadStatus.partial;
    return MaintainiacFirestoreUploadResult(
      status: status,
      attemptedCount: batch.length,
      uploadedCount: uploadedCount,
      failedCount: failedCount,
    );
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
