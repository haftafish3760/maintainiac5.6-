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
  }) async {
    final records = _records.recordsFor(module, includeDeleted: true);
    final queued = <MaintainiacFirestoreQueuedDocument>[];
    for (final record in records) {
      final pending = await queueRecord(
        organizationId: organizationId,
        record: record,
        schemaVersion: schemaVersion,
        queuedAtUtc: queuedAtUtc,
      );
      if (pending != null) queued.add(pending);
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
