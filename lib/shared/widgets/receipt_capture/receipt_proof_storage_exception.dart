part of 'receipt_proof_storage.dart';

class ReceiptProofStorageException implements Exception {
  const ReceiptProofStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
