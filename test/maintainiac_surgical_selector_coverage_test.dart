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
}
