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

  test('project rules require bundled work and non-idle testing', () {
    final rules = File('PROJECT_RULES.md').readAsStringSync().toLowerCase();

    expect(rules, contains('codex bundling and non-idle testing rule'));
    expect(rules, contains('bundle related edits'));
    expect(rules, contains('run targeted tests after a bundle'));
    expect(rules, contains('use test/build wait time'));
    expect(rules, contains('rerun the narrow failed test first'));
    expect(rules, contains('full quality gates belong at milestones'));
  });
}
