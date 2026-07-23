import 'maintainiac_callable_functions.dart';
import 'maintainiac_firestore_documents.dart';
import 'maintainiac_firestore_upload_queue.dart';
import 'maintainiac_hosted_plan_client.dart';

class MaintainiacCallableDurableRecordSink
    implements
        MaintainiacFirestoreDocumentSink,
        MaintainiacFirestoreBatchDocumentSink,
        MaintainiacHostedReservationRequiredSink,
        MaintainiacServerCommittedBatchSink {
  const MaintainiacCallableDurableRecordSink(this._functions);

  final MaintainiacCallableFunctionClient _functions;

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) => throw StateError(
    'Hosted durable records require a server-authorized batch attempt.',
  );

  @override
  Future<void> writeDocuments(
    List<MaintainiacFirestoreDocumentDraft> documents,
  ) => throw StateError(
    'Hosted durable records require a server-authorized batch attempt.',
  );

  @override
  Future<MaintainiacHostedSyncReservation> writeServerAuthorizedDocuments({
    required String attemptId,
    required List<MaintainiacFirestoreDocumentDraft> documents,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(attemptId) ||
        documents.isEmpty ||
        documents.length > MaintainiacFirestoreUploadPolicy.maxBatchSize) {
      throw ArgumentError('Invalid hosted durable record batch.');
    }
    for (final document in documents) {
      MaintainiacFirestoreUploadPolicy.validateDraft(document);
      if (document.data['schema'] != 'maintainiac_durable_record_v1') {
        throw ArgumentError('Only generic durable records use this sink.');
      }
    }
    final response = await _functions.call(
      name: 'commitDurableRecordBatch',
      data: {
        'attemptId': attemptId,
        'documents': [
          for (final document in documents)
            {
              'path': document.path,
              'data': Map<String, Object?>.unmodifiable(document.data),
            },
        ],
      },
    );
    final attemptedCount = response['attemptedCount'];
    final writtenCount = response['writtenCount'];
    final batchSha256 = response['batchSha256'];
    if (attemptedCount != documents.length ||
        writtenCount is! int ||
        writtenCount < 0 ||
        writtenCount > documents.length ||
        batchSha256 is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(batchSha256)) {
      throw const FormatException('Hosted durable commit response is invalid.');
    }
    return MaintainiacHostedSyncReservation.fromServer(response);
  }
}
