import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'parser fixture manifest separates golden holdout regression and malformed roles',
    () {
      final manifest = maintainiacParserFixtureManifest;

      expect(manifest.validate(), isEmpty);
      expect(manifest.byDomain('inventory_parser'), isNotEmpty);
      expect(manifest.byDomain('expense_receipt_parser'), isNotEmpty);
      expect(manifest.toJson().toString(), contains('holdout'));
      expect(manifest.toJson().toString(), contains('regression'));
      expect(manifest.toJson().toString(), contains('redaction-proof'));
    },
  );

  test('parser fixture manifest rejects unsafe fixture governance gaps', () {
    final manifest = MaintainiacParserFixtureManifest([
      MaintainiacParserFixtureSet(
        id: 'bad_holdout',
        domain: 'inventory_parser',
        path: 'test/fixtures/work_supply_parser/bad.json',
        locale: 'en-US',
        country: 'US',
        owner: 'qa',
        source: MaintainiacParserFixtureSource.synthetic,
        role: MaintainiacParserFixtureRole.holdout,
        expectedBehavior: 'bad',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: const {'training'},
      ),
      MaintainiacParserFixtureSet(
        id: 'bad_real',
        domain: 'expense_receipt_parser',
        path: 'test/fixtures/expense_receipts/bad.json',
        locale: 'en-US',
        country: 'US',
        owner: 'qa',
        source: MaintainiacParserFixtureSource.anonymizedReal,
        role: MaintainiacParserFixtureRole.regression,
        expectedBehavior: 'bad',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: const {'regression', 'privacy-reviewed'},
      ),
    ]);

    final failures = manifest.validate().join('\n');

    expect(
      failures,
      contains('bad_holdout tags must include fixture role holdout'),
    );
    expect(
      failures,
      contains('bad_holdout holdout fixtures must not be training fixtures'),
    );
    expect(
      failures,
      contains('bad_real anonymized real fixture needs redaction-proof tag'),
    );
    expect(failures, contains('bad_real regression fixtures need bug id tag'));
    expect(failures, contains('fixture manifest missing role golden'));
    expect(failures, contains('fixture manifest missing role malformed'));
  });
}
