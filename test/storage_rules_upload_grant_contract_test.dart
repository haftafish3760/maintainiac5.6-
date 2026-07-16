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
  });
}
