import 'maintainiac_callable_functions.dart';
import 'maintainiac_callable_durable_record_sink.dart';
import 'maintainiac_cloud_identity.dart';
import 'maintainiac_durable_cloud_revision_store.dart';
import 'maintainiac_firestore_upload_queue.dart';
import 'maintainiac_hosted_plan_client.dart';

class MaintainiacHostedFirestoreDocumentSink
    extends FirebaseFirestoreDocumentSink
    implements MaintainiacHostedReservationRequiredSink {
  MaintainiacHostedFirestoreDocumentSink({
    required MaintainiacCloudIdentityProvider identityProvider,
  }) : super(identityProvider: identityProvider);
}

/// Single production composition root for module-neutral Firebase backup.
///
/// Screens share this runtime instead of constructing their own queue, sink,
/// quota, identity, or acknowledgment behavior.
class MaintainiacFirebaseDurableStorageRuntime {
  const MaintainiacFirebaseDurableStorageRuntime._({
    required this.queue,
    required this.revisions,
    required this.uploads,
    required this.hostedPlan,
  });

  static Future<MaintainiacFirebaseDurableStorageRuntime> create({
    MaintainiacFirestoreUploadQueueStore? queue,
    MaintainiacDurableCloudRevisionStore? revisions,
    MaintainiacCloudIdentityProvider? identity,
    MaintainiacCallableFunctionClient? functions,
    MaintainiacFirestoreDocumentSink? sink,
    bool uploadEnabled = true,
    bool Function()? uploadNetworkAllowed,
  }) async {
    final resolvedQueue =
        queue ?? await MaintainiacFirestoreUploadQueueStore.create();
    final resolvedRevisions =
        revisions ?? await MaintainiacDurableCloudRevisionStore.create();
    final resolvedIdentity =
        identity ?? FirebaseMaintainiacCloudIdentityProvider();
    final resolvedFunctions =
        functions ?? FirebaseMaintainiacCallableFunctionClient();
    final hostedPlan = MaintainiacHostedPlanClient(
      functions: resolvedFunctions,
      identity: resolvedIdentity,
    );
    final resolvedSink =
        sink ?? MaintainiacCallableDurableRecordSink(resolvedFunctions);
    final serverCommitted = resolvedSink is MaintainiacServerCommittedBatchSink;
    final uploads = MaintainiacFirestoreUploadCoordinator(
      queue: resolvedQueue,
      sink: resolvedSink,
      uploadEnabled: uploadEnabled,
      identityProvider: resolvedIdentity,
      uploadNetworkAllowed: uploadNetworkAllowed,
      hostedSyncReservationProvider: serverCommitted
          ? null
          : (attemptId, batchSha256, batchBytes) => hostedPlan.reserveSync(
              attemptId: attemptId,
              batchSha256: batchSha256,
              batchBytes: batchBytes,
            ),
      uploadAcknowledgment: (records, acknowledgedAtUtc) =>
          resolvedRevisions.acknowledge(records, nowUtc: acknowledgedAtUtc),
    );
    return MaintainiacFirebaseDurableStorageRuntime._(
      queue: resolvedQueue,
      revisions: resolvedRevisions,
      uploads: uploads,
      hostedPlan: hostedPlan,
    );
  }

  final MaintainiacFirestoreUploadQueueStore queue;
  final MaintainiacDurableCloudRevisionStore revisions;
  final MaintainiacFirestoreUploadCoordinator uploads;
  final MaintainiacHostedPlanClient hostedPlan;
}
