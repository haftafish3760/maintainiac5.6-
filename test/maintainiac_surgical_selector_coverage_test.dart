import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'surgical selector coverage requires selectors for every focused behavior',
    () {
      const coverage = maintainiacSurgicalSelectorCoverage;

      expect(coverage.validate(), isEmpty);
      expect(
        coverage.toJson()['expectedBehaviorCount'],
        greaterThanOrEqualTo(22),
      );
      expect(coverage.toJson()['selectorCount'], greaterThanOrEqualTo(22));
      expect(
        coverage.toJson()['individualCommandCount'],
        equals(coverage.toJson()['expectedBehaviorCount']),
      );
      expect(
        coverage.toJson().toString(),
        contains(
          'expense parser consumer keeps commands focused and provider-free',
        ),
      );
    },
  );

  test('surgical selector coverage rejects missing behavior selectors', () {
    const coverage = MaintainiacSurgicalSelectorCoverage(
      registry: MaintainiacSurgicalTestSelectorRegistry([]),
      expectations: [
        MaintainiacSurgicalCoverageExpectation(
          file: 'test/maintainiac_inventory_parser_consumer_test.dart',
          plainNames: {
            'inventory parser consumer labels broad release-one QA families',
          },
        ),
      ],
    );

    final failures = coverage.validate().join('\n');

    expect(
      failures,
      contains(
        'missing surgical selector for "inventory parser consumer labels broad release-one QA families"',
      ),
    );
  });

  test('surgical selector coverage rejects unlisted selector targets', () {
    const coverage = MaintainiacSurgicalSelectorCoverage(
      registry: MaintainiacSurgicalTestSelectorRegistry([
        MaintainiacSurgicalTestSelector(
          id: 'unexpected',
          scope: MaintainiacSurgicalTestScope.singleBehavior,
          file: 'test/maintainiac_inventory_parser_consumer_test.dart',
          plainName: 'unexpected inventory behavior',
          reason: 'prove unlisted selectors are blocked',
          tags: {'inventory', 'parser-consumer'},
        ),
      ]),
      expectations: [
        MaintainiacSurgicalCoverageExpectation(
          file: 'test/maintainiac_inventory_parser_consumer_test.dart',
          plainNames: {
            'inventory parser consumer labels broad release-one QA families',
          },
        ),
      ],
    );

    final failures = coverage.validate().join('\n');

    expect(
      failures,
      contains(
        'selector target is not expected: test/maintainiac_inventory_parser_consumer_test.dart::unexpected inventory behavior',
      ),
    );
  });

  test('surgical selector registry rejects broad batch selector scopes', () {
    const registry = MaintainiacSurgicalTestSelectorRegistry([
      MaintainiacSurgicalTestSelector(
        id: 'broad_batch',
        scope: MaintainiacSurgicalTestScope.releaseGate,
        file: 'test/maintainiac_qa_backbone_test.dart',
        plainName: 'main Maintainiac QA backbone covers whole app modules',
        reason: 'prove broad scopes are blocked from the surgical registry',
        tags: {'qa-backbone', 'regression'},
      ),
    ]);

    final failures = registry.validate().join('\n');

    expect(
      failures,
      contains('broad_batch must be an individual single-behavior selector'),
    );
  });

  test('surgical selector registry commands are all individually runnable', () {
    const registry = maintainiacSurgicalTestSelectorRegistry;

    for (final selector in registry.selectors) {
      expect(selector.scope, MaintainiacSurgicalTestScope.singleBehavior);
      expect(selector.command, contains(' --plain-name '));
      expect(selector.command, isNot(contains('&&')));
      expect(selector.command, isNot(contains(';')));
    }
  });

  test(
    'surgical selector coverage ignores fixture strings that look like tests',
    () {
      const source =
          'void main() {\n'
          "  test('real behavior test', () {});\n"
          '  final fixture = \'test("generated fixtures", () {});\';\n'
          '}\n';

      expect(_declaredTestNames(source), {'real behavior test'});
    },
  );

  test('surgical selector coverage lists every test in registered files', () {
    const coverage = maintainiacSurgicalSelectorCoverage;
    final failures = <String>[];

    for (final expectation in coverage.expectations) {
      final file = File(expectation.file);
      if (!file.existsSync()) {
        failures.add('missing coverage file ${expectation.file}');
        continue;
      }

      final declaredTests = _declaredTestNames(file.readAsStringSync());
      for (final testName in declaredTests) {
        if (!expectation.plainNames.contains(testName)) {
          failures.add('${expectation.file} missing selector for "$testName"');
        }
      }
    }

    expect(failures, isEmpty);
  });
}

Set<String> _declaredTestNames(String source) {
  final names = <String>{};
  final pattern = RegExp(
    r'''^\s*test(?:Widgets)?\(\s*(['"])(.*?)\1''',
    multiLine: true,
  );

  for (final match in pattern.allMatches(source)) {
    names.add(match.group(2)!);
  }
  return names;
}
