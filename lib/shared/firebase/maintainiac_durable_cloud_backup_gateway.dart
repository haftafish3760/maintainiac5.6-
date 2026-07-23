import '../records/maintainiac_durable_record_store.dart';
import 'maintainiac_cloud_identity.dart';
import 'maintainiac_durable_cloud_revision_store.dart';
import 'maintainiac_firestore_durable_record_codec.dart';
import 'maintainiac_firestore_upload_queue.dart';

/// The only module-neutral entry point from local durable records into the
/// shared Firestore retry ledger. Feature screens never construct cloud paths,
/// account scopes, owner fields, or retry behavior.
class MaintainiacDurableCloudBackupGateway {
  MaintainiacDurableCloudBackupGateway({
    required MaintainiacDurableRecordStore records,
    required MaintainiacFirestoreUploadQueueStore queue,
    required MaintainiacCloudIdentityProvider identityProvider,
    MaintainiacDurableCloudRevisionStore? revisions,
  }) : _records = records,
       _queue = queue,
       _identityProvider = identityProvider,
       _revisions = revisions;

  final MaintainiacDurableRecordStore _records;
  final MaintainiacFirestoreUploadQueueStore _queue;
  final MaintainiacCloudIdentityProvider _identityProvider;
  final MaintainiacDurableCloudRevisionStore? _revisions;

  Future<MaintainiacFirestoreQueuedDocument?> queueRecord({
    required String organizationId,
    required MaintainiacDurableRecord record,
    int schemaVersion = 1,
    DateTime? queuedAtUtc,
  }) async {
    final uid = _authenticatedUid();
    return _queueRecordForUid(
      organizationId: organizationId,
      uid: uid,
      record: record,
      schemaVersion: schemaVersion,
      queuedAtUtc: queuedAtUtc,
    );
  }

  Future<MaintainiacFirestoreQueuedDocument?> _queueRecordForUid({
    required String organizationId,
    required String uid,
    required MaintainiacDurableRecord record,
    required int schemaVersion,
    required DateTime? queuedAtUtc,
  }) async {
    final draft = MaintainiacFirestoreDurableRecordCodec.encode(
      organizationId: organizationId,
      uid: uid,
      accountScopeId: '$organizationId.$uid',
      schemaVersion: schemaVersion,
      record: record,
    );
    if (_revisions?.isAcknowledged(draft) ?? false) return null;
    return _queue.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: queuedAtUtc,
      preserveAttemptMetadata: false,
    );
  }

  Future<List<MaintainiacFirestoreQueuedDocument>> queueModule({
    required String organizationId,
    required String module,
    int schemaVersion = 1,
    DateTime? queuedAtUtc,
  }) => queueModules(
    organizationId: organizationId,
    modules: [module],
    schemaVersions: {module: schemaVersion},
    queuedAtUtc: queuedAtUtc,
  );

  /// Stages multiple module snapshots before one user-authorized sync. The
  /// upload coordinator can then send their records in bounded shared batches
  /// instead of each screen creating a separate sync engine or network event.
  Future<List<MaintainiacFirestoreQueuedDocument>> queueModules({
    required String organizationId,
    required Iterable<String> modules,
    Map<String, int> schemaVersions = const {},
    DateTime? queuedAtUtc,
  }) async {
    final uid = _authenticatedUid();
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(organizationId)) {
      throw ArgumentError.value(organizationId, 'organizationId');
    }
    final uniqueModules = <String>{};
    for (final module in modules) {
      if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(module)) {
        throw ArgumentError.value(module, 'modules');
      }
      uniqueModules.add(module);
      if (uniqueModules.length > 100) {
        throw ArgumentError('A backup request contains too many modules.');
      }
    }
    for (final module in uniqueModules) {
      final schemaVersion = schemaVersions[module] ?? 1;
      if (schemaVersion < 1) {
        throw ArgumentError.value(schemaVersion, 'schemaVersions[$module]');
      }
    }
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final queued = <MaintainiacFirestoreQueuedDocument>[];
    for (final module in uniqueModules) {
      for (final record in _records.recordsFor(module, includeDeleted: true)) {
        final pending = await _queueRecordForUid(
          organizationId: organizationId,
          uid: uid,
          record: record,
          schemaVersion: schemaVersions[module] ?? 1,
          queuedAtUtc: queuedAt,
        );
        if (pending != null) queued.add(pending);
      }
    }
    return List.unmodifiable(queued);
  }

  String _authenticatedUid() {
    final uid = _identityProvider.currentUid?.trim() ?? '';
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(uid)) {
      throw StateError('Cloud backup requires an authenticated account.');
    }
    return uid;
  }
}
