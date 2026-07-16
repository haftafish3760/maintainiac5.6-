import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('proof upload grants require bounded, unexpired server facts', () async {
    final rules = await File('storage.rules').readAsString();

    expect(rules, contains("uploadGrant(orgId, grantId).status == 'open'"));
    expect(rules, contains('uploadGrant(orgId, grantId).maxBytes is int'));
    expect(rules, contains('uploadGrant(orgId, grantId).maxBytes > 0'));
    expect(
      rules,
      contains('uploadGrant(orgId, grantId).expiresAt is timestamp'),
    );
    expect(
      rules,
      contains('request.time < uploadGrant(orgId, grantId).expiresAt'),
    );
    expect(rules, contains('uploadGrant(orgId, grantId).proofId == fileName'));
    expect(rules, contains("request.resource.contentType.matches('image/.*')"));
    expect(rules, contains('request.resource.metadata.orgId == orgId'));
    expect(rules, contains('request.resource.metadata.uid == uid'));
    expect(rules, contains('request.resource.metadata.proofId == fileName'));
    expect(rules, contains('function hasFinalizedProofGrant('));
    expect(rules, contains("uploadGrant(orgId, grantId).status == 'finalized'"));
    expect(rules, contains('hasFinalizedProofGrant(orgId, uid, grantId, fileName)'));
  });
}
