import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'upload grant metadata remains unavailable after membership is revoked',
    () async {
      final rules = await File('firestore.rules').readAsString();

      expect(rules, contains('match /uploadGrants/{grantId}'));
      expect(
        rules,
        contains(
          '(isActiveMember(orgId) && resource.data.uid == request.auth.uid)',
        ),
      );
      expect(rules, contains('allow write: if false;'));
    },
  );
}
