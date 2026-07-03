import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_individual_qa_command.dart';
import 'support/qa_harness/qa_harness.dart';

void main() {
  test('individual QA command tool returns one exact command by id', () {
    final result = resolveMaintainiacIndividualQaCommand([
      '--id',
      'qa_environment_local_truth',
    ]);

    expect(result.exitCode, 0);
    expect(
      result.stdout,
      equals(
        'flutter test test/maintainiac_qa_environment_test.dart '
        '--plain-name "QA environment fakes preserve local truth and mirror copies"',
      ),
    );
    expect(result.stdout, isNot(contains('&&')));
  });

  test('individual QA command tool lists focused commands by risk', () {
    final result = resolveMaintainiacIndividualQaCommand([
      '--risk',
      'financial',
    ]);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('--plain-name'));
    expect(result.stdout, contains('financial scenario runner'));
  });

  test(
    'individual QA command tool resolves changed files to focused commands',
    () {
      final result = resolveMaintainiacIndividualQaCommand([
        '--changed',
        'test/support/qa_harness/maintainiac_surgical_granularity_contract.dart',
      ]);

      expect(result.exitCode, 0);
      expect(
        result.stdout,
        contains(
          'surgical granularity contract keeps tests individually runnable',
        ),
      );
      expect(
        result.stdout,
        contains('surgical granularity contract rejects broad batch selectors'),
      );
      expect(result.stdout, isNot(contains('test/all')));
    },
  );

  test('individual QA command tool resolves every selector test file', () {
    const registry = maintainiacSurgicalTestSelectorRegistry;

    for (final file in {
      for (final selector in registry.selectors) selector.file,
    }) {
      final result = resolveMaintainiacIndividualQaCommand(['--changed', file]);

      expect(result.exitCode, 0, reason: 'Expected $file to resolve.');
      expect(result.stdout, contains('--plain-name'));
      expect(
        result.stdout,
        isNot(contains('No individual QA command matched')),
      );
    }
  });

  test(
    'individual QA command tool returns all selectors for a changed file',
    () {
      const registry = maintainiacSurgicalTestSelectorRegistry;

      for (final file in {
        for (final selector in registry.selectors) selector.file,
      }) {
        final expectedCommands = [
          for (final selector in registry.selectors)
            if (selector.file == file) selector.command,
        ];
        final result = resolveMaintainiacIndividualQaCommand([
          '--changed',
          file,
        ]);
        final actualCommands = result.stdout
            .trim()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList(growable: false);

        expect(result.exitCode, 0, reason: 'Expected $file to resolve.');
        expect(actualCommands, unorderedEquals(expectedCommands));
      }
    },
  );

  test(
    'individual QA command tool changed test file output stays file scoped',
    () {
      const registry = maintainiacSurgicalTestSelectorRegistry;

      for (final file in {
        for (final selector in registry.selectors) selector.file,
      }) {
        final expectedCommands = {
          for (final selector in registry.selectors)
            if (selector.file == file) selector.command,
        };
        final result = resolveMaintainiacIndividualQaCommand([
          '--changed',
          file,
        ]);
        final actualCommands = result.stdout
            .trim()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toSet();

        expect(result.exitCode, 0, reason: 'Expected $file to resolve.');
        expect(
          actualCommands,
          expectedCommands,
          reason:
              '$file must only return its own individual plain-name commands.',
        );
      }
    },
  );

  test(
    'individual QA command tool resolves every selector id exactly once',
    () {
      const registry = maintainiacSurgicalTestSelectorRegistry;

      for (final selector in registry.selectors) {
        final result = resolveMaintainiacIndividualQaCommand([
          '--id',
          selector.id,
        ]);

        expect(
          result.exitCode,
          0,
          reason: 'Expected ${selector.id} to resolve.',
        );
        expect(result.stdout.trim(), selector.command);
        expect(
          result.stdout.trim().split('\n'),
          hasLength(1),
          reason: '${selector.id} must stay surgical and return one command.',
        );
      }
    },
  );

  test('individual QA command tool changed output is unique and surgical', () {
    const registry = maintainiacSurgicalTestSelectorRegistry;
    final result = resolveMaintainiacIndividualQaCommand([
      '--changed',
      'test/support/qa_harness/maintainiac_surgical_test_selector.dart',
      '--changed',
      'test/support/qa_harness/maintainiac_surgical_test_selector.dart',
    ]);
    final commands = result.stdout
        .trim()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);

    expect(result.exitCode, 0);
    expect(commands, isNotEmpty);
    expect(commands.toSet(), hasLength(commands.length));
    for (final command in commands) {
      final selector = registry.selectors.singleWhere(
        (candidate) => candidate.command == command,
      );

      expect(selector.scope, MaintainiacSurgicalTestScope.singleBehavior);
      expect(command, contains(' --plain-name '));
      expect(command, isNot(contains('&&')));
      expect(command, isNot(contains(';')));
    }
  });

  test('individual QA command tool rejects unknown selectors', () {
    final result = resolveMaintainiacIndividualQaCommand([
      '--id',
      'missing_selector',
    ]);

    expect(result.exitCode, 66);
    expect(result.stderr, contains('No individual QA command matched'));
  });
}
