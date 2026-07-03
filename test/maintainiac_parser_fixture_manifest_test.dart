import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('parser fixture manifest labels inventory and expense ground truth', () {
    final manifest = MaintainiacParserFixtureManifest([
      MaintainiacParserFixtureSet(
        id: 'inventory_en_us_core_ambiguous',
        domain: 'inventory_parser',
        path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
        locale: 'en-US',
        country: 'US',
        owner: 'maintainiac-qa',
        source: MaintainiacParserFixtureSource.synthetic,
        merchant: 'mixed',
        trade: 'plumbing',
        expectedBehavior:
            'Ambiguous dangerous words return ranked review candidates.',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: {'inventory', 'parser', 'dangerous-word'},
      ),
      MaintainiacParserFixtureSet(
        id: 'expense_en_us_fuel_core',
        domain: 'expense_receipt_parser',
        path: 'test/fixtures/expenses/fuel_receipts.json',
        locale: 'en-US',
        country: 'US',
        owner: 'maintainiac-qa',
        source: MaintainiacParserFixtureSource.synthetic,
        merchant: 'gas_station',
        trade: 'driver',
        expectedBehavior: 'Fuel totals balance in integer cents.',
        reviewedAt: DateTime.utc(2026, 7, 3),
        requiresReview: true,
        tags: {'expenses', 'fuel', 'money'},
      ),
    ]);

    expect(manifest.validate(), isEmpty);
    expect(manifest.byDomain('inventory_parser'), hasLength(1));
    expect(manifest.byDomain('expense_receipt_parser'), hasLength(1));
  });

  test('parser fixture manifest rejects ungoverned fixture metadata', () {
    final manifest = MaintainiacParserFixtureManifest([
      MaintainiacParserFixtureSet(
        id: 'bad_fixture',
        domain: 'inventory_parser',
        path: 'tmp/bad.json',
        locale: 'english',
        country: 'USA',
        owner: '',
        source: MaintainiacParserFixtureSource.anonymizedReal,
        expectedBehavior: '',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: {'inventory'},
      ),
    ]);

    final failures = manifest.validate().join('\n');

    expect(failures, contains('path must live under test/fixtures'));
    expect(failures, contains('locale must look like'));
    expect(failures, contains('country must be two-letter'));
    expect(failures, contains('missing owner'));
    expect(failures, contains('missing expected behavior'));
    expect(failures, contains('privacy-reviewed'));
    expect(failures, contains('missing expense receipt parser fixtures'));
  });

  test('parser fixture manifest keeps dangerous words review-only', () {
    final manifest = MaintainiacParserFixtureManifest([
      MaintainiacParserFixtureSet(
        id: 'inventory_bad_dangerous_word',
        domain: 'inventory_parser',
        path: 'test/fixtures/work_supply_parser/bad.json',
        locale: 'en-US',
        country: 'US',
        owner: 'maintainiac-qa',
        source: MaintainiacParserFixtureSource.synthetic,
        expectedBehavior: 'PVC should require review.',
        reviewedAt: DateTime.utc(2026, 7, 3),
        requiresReview: false,
        tags: {'inventory', 'dangerous-word'},
      ),
      MaintainiacParserFixtureSet(
        id: 'expense_ok',
        domain: 'expense_receipt_parser',
        path: 'test/fixtures/expenses/fuel.json',
        locale: 'en-US',
        country: 'US',
        owner: 'maintainiac-qa',
        source: MaintainiacParserFixtureSource.synthetic,
        expectedBehavior: 'Expense fixture balances.',
        reviewedAt: DateTime.utc(2026, 7, 3),
        tags: {'expense'},
      ),
    ]);

    expect(manifest.validate().join('\n'), contains('must require review'));
  });
}
