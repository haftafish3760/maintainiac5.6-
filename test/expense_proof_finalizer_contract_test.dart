import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'proof finalization verifies the staged object before closing its grant',
    () async {
    final source = await File('functions/index.js').readAsString();

    expect(source, contains("defineInt('EXPENSE_MAX_PROOF_BYTES'"));
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
