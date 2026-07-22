import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'proof finalization verifies the staged object before closing its grant',
    () async {
      final source = await File('functions/index.js').readAsString();

      expect(source, contains("defineInt('EXPENSE_MAX_PROOF_BYTES'"));
      expect(source, contains("'Proof size configuration is invalid.'"));
      expect(source, contains("'Proof exceeds the configured upload limit.'"));
      expect(source, contains("'EXPENSE_PROOF_GRANT_LIFETIME_SECONDS'"));
      expect(source, contains("'EXPENSE_DEFAULT_PROOF_QUOTA_BYTES'"));
      expect(source, contains("'EXPENSE_MAX_OPEN_PROOF_GRANTS'"));
      expect(source, contains('const issuedGrant = await db.runTransaction'));
      expect(source, contains('const existingGrant = openGrants.docs.find'));
      expect(source, contains("'Proof storage quota is exhausted.'"));
      expect(source, contains('storageUsedBytes'));
      expect(source, contains('function finalizedProofResult'));
      expect(source, contains('exports.cleanupExpiredExpenseProofUploads'));
      expect(source, contains("'EXPENSE_EXPIRED_PROOF_CLEANUP_BATCH'"));
      expect(source, contains("status: 'expired'"));
      expect(source, contains('retainedProofPath'));
      expect(source, isNot(contains('.file(path).delete(')));
      expect(source, contains('exports.finalizeExpenseProofUpload = onCall('));
      expect(source, contains("{ enforceAppCheck: true }"));
      expect(source, contains('data.status !== \'open\''));
      expect(source, contains('data.proofId !== proofId'));
      expect(source, contains('OWN_RECEIPT_PERMISSIONS.has(permission)'));
      expect(source, contains('custom.contentSha256 !== contentSha256'));
      expect(source, contains("status: 'finalized'"));
    },
  );
}
