import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('failure taxonomy classifies common QA failure families', () {
    const probe = MaintainiacFailureTaxonomyProbe();

    expect(
      probe.classify('missing id in schema'),
      MaintainiacFailureCategory.schema,
    );
    expect(
      probe.classify('VIN leaked in export'),
      MaintainiacFailureCategory.privacy,
    );
    expect(
      probe.classify('cross-account data bleed'),
      MaintainiacFailureCategory.security,
    );
    expect(
      probe.classify('dirty sync retry failed'),
      MaintainiacFailureCategory.sync,
    );
    expect(
      probe.classify('tax rounding total mismatch'),
      MaintainiacFailureCategory.money,
    );
    expect(
      probe.classify('permission missing'),
      MaintainiacFailureCategory.permissions,
    );
    expect(
      probe.classify('monthly recap mutated source collection expenses'),
      MaintainiacFailureCategory.sourceMutation,
    );
    expect(
      probe.classify('parser confidence too high'),
      MaintainiacFailureCategory.parser,
    );
    expect(
      probe.classify('catalog100k timeout'),
      MaintainiacFailureCategory.performance,
    );
    expect(
      probe.classify('holdout fixture changed'),
      MaintainiacFailureCategory.fixture,
    );
  });

  test('failure taxonomy summarizes failure buckets', () {
    const probe = MaintainiacFailureTaxonomyProbe();
    final summary = probe.summarize(const [
      'VIN leaked',
      'card leaked',
      'dirty sync retry failed',
      'tax total mismatch',
      'unknown nonsense',
    ]);

    expect(summary['privacy'], 2);
    expect(summary['sync'], 1);
    expect(summary['money'], 1);
    expect(summary['unknown'], 1);
  });
}
