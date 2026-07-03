import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_qa_runner.dart';

void main() {
  test('QA runner lists reusable whole-app groups', () {
    final result = runMaintainiacQaRunner(['--list-groups']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('inventory'));
    expect(result.stdout, contains('expenses'));
    expect(result.stdout, contains('security'));
    expect(result.stdout, contains('sync'));
  });

  test('QA runner validates contracts without launching Flutter', () {
    final result = runMaintainiacQaRunner([
      '--group',
      'inventory',
      '--strict',
    ]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('MAINTAINIAC_QA_RUNNER'));
    expect(result.stdout, contains('inventory_parser_consumer'));
    expect(result.stdout, isNot(contains('flutter test test/')));
  });

  test('QA runner emits bounded JSON by default', () {
    final result = runMaintainiacQaRunner([
      '--group',
      'security',
      '--json',
      '--strict',
    ]);

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;

    expect(payload['failureCount'], 0);
    expect(payload['selectedCommandSample'], isA<List<Object?>>());
    expect(payload.containsKey('selectedCommands'), isFalse);
    expect(result.stdout, isNot(contains('"metrics"')));
  });

  test('QA runner resolves changed files to surgical commands only', () {
    final result = runMaintainiacQaRunner([
      '--changed',
      'test/support/qa_harness/maintainiac_qa_case_registry.dart',
      '--commands-only',
      '--strict',
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('--plain-name'));
    expect(result.stdout, contains('QA case registry commands'));
    expect(result.stdout, isNot(contains('&&')));
    expect(result.stdout, isNot(contains('flutter test test/ ')));
  });

  test('QA runner does not fall back to broad commands for unmatched paths', () {
    final result = runMaintainiacQaRunner([
      '--changed',
      'docs/qa/maintainiac_qa_runner.md',
      '--commands-only',
      '--strict',
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, isEmpty);
    expect(result.stderr, isEmpty);
  });

  test('QA runner rejects unknown groups', () {
    final result = runMaintainiacQaRunner(['--group', 'nonsense']);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Unknown QA runner group'));
  });
}
