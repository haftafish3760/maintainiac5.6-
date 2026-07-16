import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_reference_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';

void main() {
  test(
    'persists a completed proof reference only for its original account',
    () async {
      final store = ExpenseCloudProofReferenceStore.memory();
      const reference = ExpenseCloudProofReference(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        byteCount: 3,
        contentType: 'image/jpeg',
        contentHashSha256:
            '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
        isFinalized: true,
      );

      await store.save(reference);

      final saved = store.referencesForReceipt(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
      );
      expect(saved, hasLength(1));
      expect(saved.single.storagePath, reference.storagePath);
      expect(saved.single.contentHashSha256, reference.contentHashSha256);
      expect(saved.single.isFinalized, isTrue);
      expect(
        store.referencesForReceipt(
          organizationId: 'org_1',
          userId: 'other_user',
          receiptId: 'receipt_1',
        ),
        isEmpty,
      );
    },
  );

  test(
    'does not claim a proof upload when local reference storage is unsafe',
    () async {
      final store = ExpenseCloudProofReferenceStore.memory(
        storageCheck: () => throw StateError('Insufficient storage'),
      );
      const reference = ExpenseCloudProofReference(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        byteCount: 3,
        contentType: 'image/jpeg',
        contentHashSha256:
            '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
        isFinalized: true,
      );

      await expectLater(() => store.save(reference), throwsStateError);
      expect(
        store.referencesForReceipt(
          organizationId: 'org_1',
          userId: 'user_1',
          receiptId: 'receipt_1',
        ),
        isEmpty,
      );
    },
  );

  test('keeps the newest verified grant after queued saves', () async {
    final store = ExpenseCloudProofReferenceStore.memory();
    const first = ExpenseCloudProofReference(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      byteCount: 3,
      contentType: 'image/jpeg',
      contentHashSha256:
          '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
      isFinalized: true,
    );
    const latest = ExpenseCloudProofReference(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_2',
      byteCount: 3,
      contentType: 'image/jpeg',
      contentHashSha256:
          '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
      isFinalized: true,
    );

    await Future.wait([store.save(first), store.save(latest)]);

    final saved = store.referencesForReceipt(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
    );
    expect(saved, hasLength(1));
    expect(saved.single.uploadGrantId, 'grant_2');
  });

  test('never persists an unfinalized proof upload as recoverable', () async {
    final store = ExpenseCloudProofReferenceStore.memory();
    const pending = ExpenseCloudProofReference(
      organizationId: 'org_1',
      userId: 'user_1',
      receiptId: 'receipt_1',
      proofId: 'proof_1',
      uploadGrantId: 'grant_1',
      byteCount: 3,
      contentType: 'image/jpeg',
      contentHashSha256:
          '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
    );

    await expectLater(() => store.save(pending), throwsArgumentError);
  });
}
