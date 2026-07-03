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
    expect(registry.toJson().toString(), contains('QA-INVENTORY-PARSER-001'));
    expect(registry.toJson().toString(), contains('QA-DEVICE-001'));
    expect(registry.toJson().toString(), contains('QA-SCOPE-001'));
    expect(registry.toJson().toString(), contains('QA-AUDIT-001'));
    expect(registry.toJson().toString(), contains('QA-EXPORT-001'));
    expect(registry.toJson().toString(), contains('QA-MUTATION-001'));
    expect(registry.toJson().toString(), contains('QA-FAILURE-001'));
    expect(registry.toJson().toString(), contains('hive-source-of-truth'));
    expect(
      registry.commandPlanFor(MaintainiacQaCasePriority.releaseBlocker),
      contains('flutter test test/maintainiac_qa_backbone_test.dart'),
    );
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
      MaintainiacQaCase(
        id: 'bad_id',
        title: 'Bad id',
        module: MaintainiacQaModule.expenses,
        behavior: 'Malformed QA case identifiers must fail.',
        evidenceTarget: 'bad_id',
        priority: MaintainiacQaCasePriority.core,
        tags: {'registry'},
      ),
      MaintainiacQaCase(
        id: 'QA-BAD-EVIDENCE-001',
        title: 'Bad evidence target',
        module: MaintainiacQaModule.expenses,
        behavior: 'Malformed evidence targets must fail.',
        evidenceTarget: 'Bad Evidence Target',
        priority: MaintainiacQaCasePriority.core,
        tags: {'registry'},
      ),
    ]);

    final failures = registry.validate();

    expect(failures, contains('duplicate QA case id QA-DUP'));
    expect(failures, contains('duplicate evidence target same'));
    expect(failures, contains('QA-DUP missing title'));
    expect(failures, contains('QA-DUP missing behavior'));
    expect(failures, contains('QA-DUP missing searchable tags'));
    expect(failures, contains('bad_id must use stable QA-AREA-### id format'));
    expect(
      failures,
      contains(
        'QA-BAD-EVIDENCE-001 evidence target must be dot-delimited snake case',
      ),
    );
  });
}
