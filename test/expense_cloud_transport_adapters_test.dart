import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_finalizer.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_storage.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_proof_upload_grant.dart';
import 'package:maintaniac/shared/firebase/maintainiac_callable_functions.dart';
import 'package:maintaniac/shared/firebase/maintainiac_cloud_object_store.dart';

void main() {
  test(
    'proof grant adapter delegates through the shared callable client',
    () async {
      final client = _CallableClient({
        'grantId': 'grant_1',
        'maxBytes': 2048,
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      });
      final issuer = FirebaseExpenseCloudProofUploadGrantIssuer(client: client);

      final grant = await issuer.issue(
        organizationId: 'org_1',
        proofId: 'proof_1',
        requestedBytes: 1024,
      );

      expect(grant.id, 'grant_1');
      expect(grant.maximumBytes, 2048);
      expect(client.name, 'issueExpenseProofUploadGrant');
      expect(client.data['requestedBytes'], 1024);
    },
  );

  test('proof finalizer validates the shared callable response', () async {
    const hash =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final client = _CallableClient({
      'status': 'finalized',
      'byteCount': 4,
      'contentSha256': hash,
    });
    final finalizer = FirebaseExpenseCloudProofFinalizer(client: client);

    await finalizer.finalize(
      const ExpenseCloudProofReference(
        organizationId: 'org_1',
        userId: 'user_1',
        receiptId: 'receipt_1',
        proofId: 'proof_1',
        uploadGrantId: 'grant_1',
        byteCount: 4,
        contentType: 'image/jpeg',
        contentHashSha256: hash,
      ),
    );

    expect(client.name, 'finalizeExpenseProofUpload');
    expect(client.data['receiptId'], 'receipt_1');
  });

  test(
    'proof object adapter delegates only through shared cloud storage',
    () async {
      final shared = _CloudObjectStore();
      final adapter = FirebaseExpenseCloudProofObjectStore(store: shared);
      final bytes = Uint8List.fromList([1, 2, 3]);

      await adapter.upload(
        path: 'orgs/org_1/proof-uploads/user_1/grant_1/proof_1',
        bytes: bytes,
        contentType: 'image/jpeg',
        metadata: const {'orgId': 'org_1'},
      );
      final downloaded = await adapter.download(
        path: shared.path!,
        maxBytes: 3,
      );

      expect(shared.uploaded, bytes);
      expect(downloaded, bytes);
    },
  );
}

class _CallableClient implements MaintainiacCallableFunctionClient {
  _CallableClient(this.response);

  final Map<String, Object?> response;
  String? name;
  Map<String, Object?> data = const {};

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    this.name = name;
    this.data = data;
    return response;
  }
}

class _CloudObjectStore implements MaintainiacCloudObjectStore {
  String? path;
  Uint8List? uploaded;

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {
    this.path = path;
    uploaded = bytes;
  }

  @override
  Future<Uint8List> download({
    required String path,
    required int maxBytes,
  }) async => uploaded!;
}
