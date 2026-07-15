import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_receipt_proof_upload_transport.dart';

void main() {
  test(
    'receipt proof upload paths reject traversal and unsafe identifiers',
    () {
      expect(validatedReceiptProofPathSegment('ORG_12-A', 'orgId'), 'ORG_12-A');
      expect(
        () => validatedReceiptProofPathSegment('../other-user', 'orgId'),
        throwsArgumentError,
      );
      expect(
        () => validatedReceiptProofPathSegment('uid/other', 'uid'),
        throwsArgumentError,
      );
      expect(
        () => validatedReceiptProofPathSegment('', 'uploadGrantId'),
        throwsArgumentError,
      );
    },
  );
}
