import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Immutable, tenant-scoped reference to a receipt proof stored in Firebase
/// Storage. It deliberately contains no device path or OCR text.
class ExpenseCloudProofReference {
  const ExpenseCloudProofReference({
    required this.organizationId,
    required this.userId,
    required this.receiptId,
    required this.proofId,
    required this.uploadGrantId,
    required this.byteCount,
    required this.contentType,
    required this.contentHashSha256,
    this.isFinalized = false,
  });

  final String organizationId;
  final String userId;
  final String receiptId;
  final String proofId;
  final String uploadGrantId;
  final int byteCount;
  final String contentType;
  final String contentHashSha256;
  final bool isFinalized;

  ExpenseCloudProofReference finalized() => ExpenseCloudProofReference(
    organizationId: organizationId,
    userId: userId,
    receiptId: receiptId,
    proofId: proofId,
    uploadGrantId: uploadGrantId,
    byteCount: byteCount,
    contentType: contentType,
    contentHashSha256: contentHashSha256,
    isFinalized: true,
  );

  String get storagePath => ExpenseCloudProofStorage.storagePathFor(
    organizationId: organizationId,
    userId: userId,
    uploadGrantId: uploadGrantId,
    proofId: proofId,
  );
}

abstract interface class ExpenseCloudProofObjectStore {
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  });

  Future<Uint8List> download({required String path, required int maxBytes});
}

class FirebaseExpenseCloudProofObjectStore
    implements ExpenseCloudProofObjectStore {
  FirebaseExpenseCloudProofObjectStore({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {
    await _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(contentType: contentType, customMetadata: metadata),
        );
  }

  @override
  Future<Uint8List> download({
    required String path,
    required int maxBytes,
  }) async {
    final bytes = await _storage.ref(path).getData(maxBytes);
    if (bytes == null) throw StateError('Cloud proof is unavailable.');
    return bytes;
  }
}

/// Storage-only proof transfer boundary. Callers must keep the local proof as
/// the source of truth until upload succeeds and their retention policy allows
/// removal. This class never deletes device files.
class ExpenseCloudProofStorage {
  ExpenseCloudProofStorage({
    required ExpenseCloudProofObjectStore objectStore,
    this.maximumProofBytes = 20 * 1024 * 1024,
  }) : _objectStore = objectStore;

  final ExpenseCloudProofObjectStore _objectStore;
  final int maximumProofBytes;

  Future<ExpenseCloudProofReference> uploadProof({
    required String organizationId,
    required String userId,
    required String receiptId,
    required String proofId,
    required String uploadGrantId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _validateIdentity(organizationId, 'organizationId');
    _validateIdentity(userId, 'userId');
    _validateIdentity(receiptId, 'receiptId');
    _validateIdentity(proofId, 'proofId');
    _validateIdentity(uploadGrantId, 'uploadGrantId');
    final normalizedContentType = contentType.trim().toLowerCase();
    if (!normalizedContentType.startsWith('image/')) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'An image is required.',
      );
    }
    _validateBytes(bytes.length);
    final reference = ExpenseCloudProofReference(
      organizationId: organizationId,
      userId: userId,
      receiptId: receiptId,
      proofId: proofId,
      uploadGrantId: uploadGrantId,
      byteCount: bytes.length,
      contentType: normalizedContentType,
      contentHashSha256: sha256.convert(bytes).toString(),
    );
    await _objectStore.upload(
      path: reference.storagePath,
      bytes: bytes,
      contentType: normalizedContentType,
      metadata: {
        'orgId': organizationId,
        'uid': userId,
        'receiptId': receiptId,
        'proofId': proofId,
        'contentSha256': reference.contentHashSha256,
      },
    );
    return reference;
  }

  Future<Uint8List> downloadProof(ExpenseCloudProofReference reference) async {
    if (!reference.isFinalized) {
      throw StateError('Cloud proof is not finalized for recovery.');
    }
    _validateIdentity(reference.organizationId, 'organizationId');
    _validateIdentity(reference.userId, 'userId');
    _validateIdentity(reference.receiptId, 'receiptId');
    _validateIdentity(reference.proofId, 'proofId');
    _validateIdentity(reference.uploadGrantId, 'uploadGrantId');
    _validateBytes(reference.byteCount);
    final bytes = await _objectStore.download(
      path: reference.storagePath,
      maxBytes: reference.byteCount,
    );
    if (bytes.length != reference.byteCount) {
      throw StateError('Cloud proof size does not match its durable record.');
    }
    if (sha256.convert(bytes).toString() != reference.contentHashSha256) {
      throw StateError('Cloud proof contents do not match its durable record.');
    }
    return bytes;
  }

  static String storagePathFor({
    required String organizationId,
    required String userId,
    required String uploadGrantId,
    required String proofId,
  }) => 'orgs/$organizationId/proof-uploads/$userId/$uploadGrantId/$proofId';

  void _validateBytes(int byteCount) {
    if (byteCount <= 0 || byteCount > maximumProofBytes) {
      throw StateError('Proof size is outside the approved storage limit.');
    }
  }

  static void _validateIdentity(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'Unsafe storage identifier.');
    }
  }
}
