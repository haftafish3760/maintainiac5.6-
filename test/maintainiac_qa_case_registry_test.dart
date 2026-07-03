import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA case registry labels behavior evidence and priority', () {
    final registry = MaintainiacQaCaseRegistry.backboneSeed();

    expect(registry.validate(), isEmpty);
    expect(registry.cases, hasLength(greaterThanOrEqualTo(5)));
    expect(
      registry.byPriority(MaintainiacQaCasePriority.releaseBlocker),
      hasLength(greaterThanOrEqualTo(4)),
    );
    expect(registry.toJson().toString(), contains('QA-MONEY-001'));
    expect(registry.toJson().toString(), contains('QA-DEVICE-001'));
    expect(registry.toJson().toString(), contains('QA-SCOPE-001'));
    expect(registry.toJson().toString(), contains('QA-AUDIT-001'));
    expect(registry.toJson().toString(), contains('hive-source-of-truth'));
  });

  test('QA case registry rejects duplicate and unlabeled cases', () {
    const registry = MaintainiacQaCaseRegistry([
      MaintainiacQaCase(
        id: 'QA-DUP',
        title: '',
        module: MaintainiacQaModule.expenses,
        behavior: '',
        evidenceTarget: 'same',
        priority: MaintainiacQaCasePriority.core,
      ),
      MaintainiacQaCase(
        id: 'QA-DUP',
        title: 'Duplicate',
        module: MaintainiacQaModule.expenses,
        behavior: 'Duplicate evidence target must fail.',
        evidenceTarget: 'same',
        priority: MaintainiacQaCasePriority.core,
      ),
    ]);

    final failures = registry.validate();

    expect(failures, contains('duplicate QA case id QA-DUP'));
    expect(failures, contains('duplicate evidence target same'));
    expect(failures, contains('QA-DUP missing title'));
    expect(failures, contains('QA-DUP missing behavior'));
  });
}
