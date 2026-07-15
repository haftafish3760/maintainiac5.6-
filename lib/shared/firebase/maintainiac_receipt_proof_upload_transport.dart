import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../widgets/receipt_capture/receipt_capture_models.dart';
import '../widgets/receipt_capture/receipt_proof_storage.dart';

class MaintainiacReceiptProofUploadRequest {
  const MaintainiacReceiptProofUploadRequest({
    required this.orgId,
    required this.uid,
    required this.uploadGrantId,
    required this.attachment,
  });

  final String orgId;
  final String uid;
  final String uploadGrantId;
  final ReceiptAttachmentRecord attachment;
}

class MaintainiacReceiptProofUploadResult {
  const MaintainiacReceiptProofUploadResult({
    required this.stagedStoragePath,
    required this.byteSize,
  });

  final String stagedStoragePath;
  final int byteSize;
}

/// Grant-gated uploader for a proof that has already been saved locally.
///
/// This class cannot delete the local proof, gallery content, or any other
/// device file. A server-created grant and a Cloud-side move into the protected
/// proof path are required before local retention choices may remove a copy.
class MaintainiacReceiptProofUploadTransport {
  MaintainiacReceiptProofUploadTransport({
    FirebaseStorage? storage,
    ReceiptProofStorage? proofStorage,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _proofStorage = proofStorage ?? ReceiptProofStorage.instance;

  final FirebaseStorage _storage;
  final ReceiptProofStorage _proofStorage;

  Future<MaintainiacReceiptProofUploadResult> upload(
    MaintainiacReceiptProofUploadRequest request,
  ) async {
    final attachment = request.attachment;
    final orgId = validatedReceiptProofPathSegment(request.orgId, 'orgId');
    final uid = validatedReceiptProofPathSegment(request.uid, 'uid');
    final grantId = validatedReceiptProofPathSegment(
      request.uploadGrantId,
      'uploadGrantId',
    );
    if (attachment.storageState != ReceiptAttachmentStorageState.permanent ||
        !await _proofStorage.isManagedPermanentProofPath(attachment.path)) {
      throw StateError('Only completed Maintainiac receipt proofs can upload.');
    }
    final source = File(attachment.path);
    final fileName = _fileNameFor(attachment);
    final stagedPath = 'orgs/$orgId/proof-uploads/$uid/$grantId/$fileName';
    final task = _storage
        .ref(stagedPath)
        .putFile(
          source,
          SettableMetadata(
            contentType: attachment.mimeType.trim().isEmpty
                ? null
                : attachment.mimeType,
            customMetadata: {
              'ownerUid': uid,
          'attachmentId': validatedReceiptProofPathSegment(
            attachment.id,
            'attachmentId',
          ),
              if (attachment.fileHash.trim().isNotEmpty)
                'sha256': attachment.fileHash.trim(),
            },
          ),
        );
    final snapshot = await task;
    return MaintainiacReceiptProofUploadResult(
      stagedStoragePath: stagedPath,
      byteSize: snapshot.totalBytes,
    );
  }
}

String validatedReceiptProofPathSegment(String value, String field) {
  final clean = value.trim();
  if (clean.isEmpty || !RegExp(r'^[A-Za-z0-9_-]{1,180}$').hasMatch(clean)) {
    throw ArgumentError.value(value, field, 'Unsafe Firebase path segment.');
  }
  return clean;
}

String _fileNameFor(ReceiptAttachmentRecord attachment) {
  final extension = path.extension(attachment.originalFileName).toLowerCase();
  final safeExtension = RegExp(r'^\.[a-z0-9]{1,12}$').hasMatch(extension)
      ? extension
      : attachment.isPdf
      ? '.pdf'
      : '.jpg';
  return '${validatedReceiptProofPathSegment(attachment.id, 'attachmentId')}$safeExtension';
}
