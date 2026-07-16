import 'package:hive_flutter/hive_flutter.dart';

import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

typedef ExpenseCloudProofReferenceStorageCheck =
    Future<AppStorageCheck> Function();

/// Local-first ledger of verified cloud proof references.
///
/// The receipt ledger remains the source of truth. This store only records a
/// completed cloud transfer, scoped to its original account, so a later
/// metadata backup can safely advertise the proof as recoverable.
class ExpenseCloudProofReferenceStore {
  ExpenseCloudProofReferenceStore._(this._box, {this.storageCheck});

  ExpenseCloudProofReferenceStore.memory({this.storageCheck}) : _box = null;

  static const boxName = 'expense_cloud_proof_references_v1';

  final Box<dynamic>? _box;
  final ExpenseCloudProofReferenceStorageCheck? storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<ExpenseCloudProofReferenceStore> create({
    ExpenseCloudProofReferenceStorageCheck? storageCheck,
  }) async => ExpenseCloudProofReferenceStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck ?? _defaultStorageCheck,
  );

  Future<void> save(ExpenseCloudProofReference reference) => _enqueue(() async {
    _validate(reference);
    await _ensureStorage();
    final record = {
      'organizationId': reference.organizationId,
      'userId': reference.userId,
      'receiptId': reference.receiptId,
      'proofId': reference.proofId,
      'uploadGrantId': reference.uploadGrantId,
      'byteCount': reference.byteCount,
      'contentType': reference.contentType,
      'contentHashSha256': reference.contentHashSha256,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
    };
    final box = _box;
    if (box == null) {
      _memory[_key(reference)] = record;
    } else {
      await box.put(_key(reference), record);
    }
  });

  List<ExpenseCloudProofReference> referencesForReceipt({
    required String organizationId,
    required String userId,
    required String receiptId,
  }) {
    _validateToken(organizationId, 'organizationId');
    _validateToken(userId, 'userId');
    _validateToken(receiptId, 'receiptId');
    final values = _box?.values ?? _memory.values;
    final references = <ExpenseCloudProofReference>[];
    for (final value in values) {
      if (value is! Map) continue;
      final reference = _fromMap(value);
      if (reference == null ||
          reference.organizationId != organizationId ||
          reference.userId != userId ||
          reference.receiptId != receiptId) {
        continue;
      }
      references.add(reference);
    }
    references.sort((a, b) => a.proofId.compareTo(b.proofId));
    return List.unmodifiable(references);
  }

  Future<void> _ensureStorage() async {
    final check = storageCheck;
    if (check == null) return;
    final result = await check();
    if (!result.hasEnoughSpace) throw StateError(result.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (error, stackTrace) {});
    return result;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  static ExpenseCloudProofReference? _fromMap(Map<dynamic, dynamic> value) {
    try {
      final reference = ExpenseCloudProofReference(
        organizationId: '${value['organizationId'] ?? ''}',
        userId: '${value['userId'] ?? ''}',
        receiptId: '${value['receiptId'] ?? ''}',
        proofId: '${value['proofId'] ?? ''}',
        uploadGrantId: '${value['uploadGrantId'] ?? ''}',
        byteCount: value['byteCount'] is int ? value['byteCount'] as int : 0,
        contentType: '${value['contentType'] ?? ''}',
        contentHashSha256: '${value['contentHashSha256'] ?? ''}',
      );
      _validate(reference);
      return reference;
    } catch (_) {
      return null;
    }
  }

  static String _key(ExpenseCloudProofReference reference) =>
      '${reference.organizationId}:${reference.userId}:${reference.receiptId}:${reference.proofId}';

  static void _validate(ExpenseCloudProofReference reference) {
    _validateToken(reference.organizationId, 'organizationId');
    _validateToken(reference.userId, 'userId');
    _validateToken(reference.receiptId, 'receiptId');
    _validateToken(reference.proofId, 'proofId');
    _validateToken(reference.uploadGrantId, 'uploadGrantId');
    if (reference.byteCount <= 0 ||
        !reference.contentType.startsWith('image/') ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(reference.contentHashSha256)) {
      throw ArgumentError('Invalid cloud proof reference.');
    }
  }

  static void _validateToken(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'Unsafe proof reference token.');
    }
  }
}
