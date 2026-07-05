import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project rules require quick answers before broad audits', () {
    final rules = File('PROJECT_RULES.md').readAsStringSync().toLowerCase();

    expect(rules, contains('codex rate-limit and evidence rule'));
    expect(
      rules,
      contains('do you want a quick estimate or a verified audit?'),
    );
    expect(rules, contains('do not scan broad repo paths'));
    expect(rules, contains('smallest relevant files first'));
    expect(rules, contains('long-running checks must run non-interactively'));
  });
}
