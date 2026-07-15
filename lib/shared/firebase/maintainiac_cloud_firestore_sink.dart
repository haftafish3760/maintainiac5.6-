import 'package:cloud_firestore/cloud_firestore.dart';

import 'maintainiac_firestore_upload_queue.dart';

/// Production transport for already-validated queued documents.
///
/// It deliberately accepts only the queue's path/data contract. Receipt images
/// use the separate, grant-gated Storage path; this sink never uploads files.
class MaintainiacCloudFirestoreDocumentSink
    implements MaintainiacFirestoreDocumentSink {
  MaintainiacCloudFirestoreDocumentSink({FirebaseFirestore? firestore})
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
