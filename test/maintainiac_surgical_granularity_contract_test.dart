import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('surgical granularity contract keeps tests individually runnable', () {
    const contract = maintainiacSurgicalGranularityContract;

    expect(contract.validate(), isEmpty);
    expect(contract.toJson()['individualPlainNameRequired'], isTrue);
    expect(contract.toJson()['batchCommandsRejected'], isTrue);
    expect(
      contract.toJson()['singleBehaviorPercent'],
      greaterThanOrEqualTo(80),
    );
    expect(
      contract.toJson().toString(),
      contains('maxSelectorsPerChangedFile'),
    );
  });

  test('surgical granularity contract rejects broad batch selectors', () {
    const badRegistry = MaintainiacSurgicalTestSelectorRegistry([
      MaintainiacSurgicalTestSelector(
        id: 'bad_target',
        scope: MaintainiacSurgicalTestScope.moduleSmoke,
        file: 'lib/full_inventory_suite.dart',
        plainName: 'all tests',
        reason: 'bad target selector',
        tags: {'inventory', 'parser-consumer'},
      ),
      MaintainiacSurgicalTestSelector(
        id: 'bad_batch',
        scope: MaintainiacSurgicalTestScope.moduleSmoke,
        file: 'test/all_inventory_suite.dart',
        plainName: 'all tests',
        reason: 'bad batch selector',
        tags: {'inventory', 'parser-consumer'},
      ),
      MaintainiacSurgicalTestSelector(
        id: 'bad_batch_2',
        scope: MaintainiacSurgicalTestScope.singleBehavior,
        file: 'test/maintainiac_inventory_parser_consumer_test.dart',
        plainName:
            'inventory parser consumer labels broad release-one QA families',
        reason: 'duplicate target',
        tags: {'inventory'},
      ),
      MaintainiacSurgicalTestSelector(
        id: 'bad_batch_name',
        scope: MaintainiacSurgicalTestScope.singleBehavior,
        file: 'test/maintainiac_inventory_parser_consumer_test.dart',
        plainName: 'inventory parser full suite run all checks',
        reason: 'broad plain name',
        tags: {'inventory', 'regression'},
      ),
    ]);
    const badRouter = MaintainiacSurgicalRerunRouter(
      registry: badRegistry,
      rules: [
        MaintainiacSurgicalRerunRule(
          id: 'bad_folder_rule',
          changedPathContains: 'test/support/qa_harness/',
          selectorIds: {'bad_target'},
          reason: 'folder rule is too broad',
        ),
      ],
    );
    const contract = MaintainiacSurgicalGranularityContract(
      registry: badRegistry,
      router: badRouter,
      maxSelectorsPerChangedFile: 1,
    );

    final failures = contract.validate().join('\n');

    expect(failures, contains('bad_target must target one Dart test file'));
    expect(
      failures,
      contains('broad selector must be explicitly release-gated'),
    );
    expect(failures, contains('command looks like a batch run'));
    expect(failures, contains('plain-name looks too broad'));
    expect(failures, contains('must target a file, not a folder'));
    expect(failures, contains('missing rerun rule'));
  });

  test('surgical selectors point at real individual test declarations', () {
    const registry = maintainiacSurgicalTestSelectorRegistry;

    for (final selector in registry.selectors) {
      final file = File(selector.file);
      expect(
        file.existsSync(),
        isTrue,
        reason: '${selector.id} points at missing file ${selector.file}',
      );
      final source = file.readAsStringSync();
      final declarations = _testDeclarationsNamed(source, selector.plainName);

      expect(
        declarations,
        1,
        reason:
            '${selector.id} must map to exactly one real test declaration in ${selector.file}',
      );
    }
  });
}

int _testDeclarationsNamed(String source, String plainName) {
  final escaped = RegExp.escape(plainName);
  final singleQuoted = RegExp("test\\(\\s*'$escaped'");
  final doubleQuoted = RegExp('test\\(\\s*"$escaped"');

  return singleQuoted.allMatches(source).length +
      doubleQuoted.allMatches(source).length;
}
