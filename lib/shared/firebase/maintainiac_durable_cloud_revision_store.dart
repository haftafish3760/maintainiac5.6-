import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_upload_queue.dart';

typedef MaintainiacCloudRevisionStorageCheck =
    Future<AppStorageCheck> Function();

class MaintainiacDurableCloudRevision {
  const MaintainiacDurableCloudRevision({
    required this.path,
    required this.accountScopeId,
    required this.localRevision,
    required this.contentSha256,
    required this.acknowledgedAtUtc,
  });

  factory MaintainiacDurableCloudRevision.fromMap(Map<dynamic, dynamic> map) {
    final acknowledgedAt = DateTime.tryParse(
      map['acknowledgedAtUtc']?.toString() ?? '',
    );
    final revision = MaintainiacDurableCloudRevision(
      path: map['path']?.toString() ?? '',
      accountScopeId: map['accountScopeId']?.toString() ?? '',
      localRevision: map['localRevision'] is int
          ? map['localRevision'] as int
          : -1,
      contentSha256: map['contentSha256']?.toString() ?? '',
      acknowledgedAtUtc:
          acknowledgedAt?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    revision.validate();
    return revision;
  }

  final String path;
  final String accountScopeId;
  final int localRevision;
  final String contentSha256;
  final DateTime acknowledgedAtUtc;

  void validate() {
    if (!path.startsWith('orgs/') ||
        path.split('/').length != 4 ||
        accountScopeId.isEmpty ||
        localRevision < 1 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(contentSha256) ||
        acknowledgedAtUtc.millisecondsSinceEpoch <= 0) {
      throw const FormatException('Cloud revision checkpoint is corrupt.');
    }
  }

  Map<String, Object?> toMap() => {
    'path': path,
    'accountScopeId': accountScopeId,
    'localRevision': localRevision,
    'contentSha256': contentSha256,
    'acknowledgedAtUtc': acknowledgedAtUtc.toUtc().toIso8601String(),
  };
}

class MaintainiacDurableCloudRevisionStore {
  MaintainiacDurableCloudRevisionStore._(
    this._box, {
    MaintainiacCloudRevisionStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  MaintainiacDurableCloudRevisionStore.memory({
    MaintainiacCloudRevisionStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static const boxName = 'maintainiac_durable_cloud_revisions';

  static Future<MaintainiacDurableCloudRevisionStore> create({
    MaintainiacCloudRevisionStorageCheck? storageCheck,
  }) async => MaintainiacDurableCloudRevisionStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final MaintainiacCloudRevisionStorageCheck _storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  MaintainiacDurableCloudRevision? checkpointFor(String path) {
    final value = _box?.get(_key(path)) ?? _memory[_key(path)];
    if (value == null) return null;
    if (value is! Map) {
      throw StateError('Cloud revision checkpoint is corrupt.');
    }
    try {
      return MaintainiacDurableCloudRevision.fromMap(value);
    } on FormatException catch (error) {
      throw StateError('Cloud revision checkpoint is corrupt: $error');
    }
  }

  bool isAcknowledged(MaintainiacFirestoreDocumentDraft draft) {
    if (draft.data['schema'] != 'maintainiac_durable_record_v1') return false;
    final checkpoint = checkpointFor(draft.path);
    return checkpoint != null &&
        checkpoint.accountScopeId == draft.data['accountScopeId'] &&
        checkpoint.localRevision == draft.data['localRevision'] &&
        checkpoint.contentSha256 == draft.data['contentSha256'];
  }

  Future<void> acknowledge(
    List<MaintainiacFirestoreQueuedDocument> uploaded, {
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final generic = uploaded
        .where(
          (record) => record.data['schema'] == 'maintainiac_durable_record_v1',
        )
        .toList(growable: false);
    if (generic.isEmpty) return;
    final storage = await _storageCheck();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final record in generic) {
      final revision = MaintainiacDurableCloudRevision(
        path: record.path,
        accountScopeId: record.data['accountScopeId']?.toString() ?? '',
        localRevision: record.data['localRevision'] is int
            ? record.data['localRevision'] as int
            : -1,
        contentSha256: record.data['contentSha256']?.toString() ?? '',
        acknowledgedAtUtc: now,
      );
      revision.validate();
      final map = Map<String, Object?>.unmodifiable(revision.toMap());
      if (_box == null) {
        _memory[_key(record.path)] = map;
      } else {
        await _box.put(_key(record.path), map);
      }
    }
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static String _key(String path) =>
      sha256.convert(utf8.encode(path)).toString();

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}
