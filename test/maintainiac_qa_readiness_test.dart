import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA readiness ledger tracks completed backbone and remaining gaps', () {
    final ledger = MaintainiacQaReadinessLedger.currentBackbone();

    expect(ledger.validate(), isEmpty);
    expect(ledger.releaseReady, isTrue);
    expect(ledger.countsByStatus['ready'], greaterThanOrEqualTo(5));
    expect(ledger.countsByStatus['partial'], 0);
    expect(ledger.countsByStatus['missing'], 0);
    expect(ledger.toJson().toString(), contains('inventory_parser_consumer'));
    expect(ledger.toJson().toString(), contains('expense_parser_consumer'));
    expect(ledger.toJson().toString(), contains('device_capability_probe'));
    expect(ledger.toJson().toString(), contains('scope_policy_probe'));
    expect(ledger.toJson().toString(), contains('audit_trail_probe'));
    expect(ledger.toJson().toString(), contains('export_privacy_probe'));
    expect(ledger.toJson().toString(), contains('mutation_guard_probe'));
    expect(ledger.toJson().toString(), contains('failure_taxonomy_probe'));
    expect(ledger.toJson().toString(), contains('quality_gate_matrix'));
    expect(ledger.toJson().toString(), contains('cost/quota'));
    expect(ledger.toJson().toString(), contains('surgical_selector_coverage'));
    expect(ledger.toJson().toString(), contains('surgical_rerun_router'));
    expect(ledger.toJson().toString(), contains('source_truth_gate'));
    expect(ledger.toJson().toString(), contains('financial_formula_registry'));
    expect(ledger.toJson().toString(), contains('qa_telemetry_privacy_gate'));
    expect(ledger.toJson().toString(), contains('release_evidence_bundle'));
    expect(ledger.toJson().toString(), contains('fixture_governance_gate'));
    expect(ledger.toJson().toString(), contains('restart_lifecycle_gate'));
    expect(ledger.toJson().toString(), contains('module_boundary_gate'));
    expect(ledger.toJson().toString(), contains('performance_budget_registry'));
  });

  test('QA readiness ledger dart evidence references existing files', () {
    final ledger = MaintainiacQaReadinessLedger.currentBackbone();
    final missingEvidence = <String>[];

    for (final item in ledger.items) {
      for (final evidence in item.evidence) {
        if (!evidence.endsWith('.dart')) continue;
        if (!_evidenceFileExists(evidence)) {
          missingEvidence.add('${item.id}:$evidence');
        }
      }
    }

    expect(
      missingEvidence,
      isEmpty,
      reason: 'Ready QA backbone claims must point at real Dart evidence.',
    );
  });

  test('QA readiness ledger ready claims include dart evidence', () {
    final ledger = MaintainiacQaReadinessLedger.currentBackbone();
    final readyWithoutDartEvidence = <String>[];

    for (final item in ledger.items) {
      if (item.status != MaintainiacQaReadinessStatus.ready) continue;
      final dartEvidence = item.evidence.where((entry) {
        return entry.endsWith('.dart') && _evidenceFileExists(entry);
      });
      if (dartEvidence.isEmpty) readyWithoutDartEvidence.add(item.id);
    }

    expect(
      readyWithoutDartEvidence,
      isEmpty,
      reason: 'Ready QA backbone claims need at least one real Dart artifact.',
    );
  });

  test('QA readiness ledger rejects fake ready claims without evidence', () {
    const ledger = MaintainiacQaReadinessLedger([
      MaintainiacQaReadinessItem(
        id: 'fake_ready',
        module: MaintainiacQaModule.expenses,
        description: 'This should fail because there is no evidence.',
        status: MaintainiacQaReadinessStatus.ready,
      ),
      MaintainiacQaReadinessItem(
        id: 'fake_gap',
        module: MaintainiacQaModule.inventory,
        description: 'This should fail because partial needs named gaps.',
        status: MaintainiacQaReadinessStatus.partial,
      ),
    ]);

    expect(
      ledger.validate(),
      contains('fake_ready marked ready without evidence'),
    );
    expect(ledger.validate(), contains('fake_gap marked partial without gaps'));
  });

  test(
    'QA readiness ledger rejects duplicate blank or placeholder evidence',
    () {
      const ledger = MaintainiacQaReadinessLedger([
        MaintainiacQaReadinessItem(
          id: 'weak_evidence',
          module: MaintainiacQaModule.security,
          description:
              'This should fail because the evidence cannot be trusted.',
          status: MaintainiacQaReadinessStatus.ready,
          evidence: [
            'maintainiac_real_gate.dart',
            'maintainiac_real_gate.dart',
            ' ',
            'todo',
            'unknown',
            'fake',
            'placeholder_contract.dart',
          ],
        ),
      ]);

      expect(
        ledger.validate(),
        contains(
          'weak_evidence has duplicate evidence reference '
          'maintainiac_real_gate.dart',
        ),
      );
      expect(
        ledger.validate(),
        contains('weak_evidence has blank evidence reference'),
      );
      expect(
        ledger.validate(),
        contains('weak_evidence has placeholder evidence reference todo'),
      );
      expect(
        ledger.validate(),
        contains('weak_evidence has placeholder evidence reference unknown'),
      );
      expect(
        ledger.validate(),
        contains('weak_evidence has placeholder evidence reference fake'),
      );
      expect(
        ledger.validate(),
        contains(
          'weak_evidence has placeholder evidence reference '
          'placeholder_contract.dart',
        ),
      );
    },
  );
}

bool _evidenceFileExists(String fileName) {
  return File('test/support/qa_harness/$fileName').existsSync() ||
      File('test/$fileName').existsSync() ||
      File('lib/$fileName').existsSync() ||
      File('tool/$fileName').existsSync();
}
