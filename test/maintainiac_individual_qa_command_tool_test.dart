import 'package:flutter_test/flutter_test.dart';

import '../tool/maintainiac_individual_qa_command.dart';

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

  test('individual QA command tool rejects unknown selectors', () {
    final result = resolveMaintainiacIndividualQaCommand([
      '--id',
      'missing_selector',
    ]);

    expect(result.exitCode, 66);
    expect(result.stderr, contains('No individual QA command matched'));
  });
}
