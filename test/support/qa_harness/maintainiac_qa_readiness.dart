import 'maintainiac_qa_environment.dart';

enum MaintainiacQaReadinessStatus { ready, partial, missing }

class MaintainiacQaReadinessItem {
  const MaintainiacQaReadinessItem({
    required this.id,
    required this.module,
    required this.description,
    required this.status,
    this.evidence = const [],
    this.gaps = const [],
  });

  final String id;
  final MaintainiacQaModule module;
  final String description;
  final MaintainiacQaReadinessStatus status;
  final List<String> evidence;
  final List<String> gaps;

  bool get isBlocking => status == MaintainiacQaReadinessStatus.missing;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('readiness item missing id');
    if (description.trim().isEmpty) {
      failures.add('$id missing description');
    }
    if (status == MaintainiacQaReadinessStatus.ready && evidence.isEmpty) {
      failures.add('$id marked ready without evidence');
    }
    if (status != MaintainiacQaReadinessStatus.ready && gaps.isEmpty) {
      failures.add('$id marked ${status.name} without gaps');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module.name,
      'description': description,
      'status': status.name,
      'blocking': isBlocking,
      'evidence': evidence,
      'gaps': gaps,
    };
  }
}

class MaintainiacQaReadinessLedger {
  const MaintainiacQaReadinessLedger(this.items);

  factory MaintainiacQaReadinessLedger.currentBackbone() {
    return const MaintainiacQaReadinessLedger([
      MaintainiacQaReadinessItem(
        id: 'shared_environment',
        module: MaintainiacQaModule.sync,
        description:
            'Fake local, mirror, storage, clock, device, and permission environment.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_environment.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'shared_builders_assertions',
        module: MaintainiacQaModule.inventory,
        description:
            'Reusable builders and assertions for records, money, audit, sync, and ownership.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: [
          'maintainiac_qa_builders.dart',
          'maintainiac_qa_assertions.dart',
        ],
      ),
      MaintainiacQaReadinessItem(
        id: 'regression_registry',
        module: MaintainiacQaModule.security,
        description:
            'Permanent registry shape for bug ID, root cause, fixture, expected behavior, and module tags.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_regression_registry.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'scenario_runners',
        module: MaintainiacQaModule.performance,
        description:
            'Executable sync, security, financial, and performance scenario runners.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_scenario_runners.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'source_boundary_scanner',
        module: MaintainiacQaModule.security,
        description:
            'Reusable scan for forbidden implementation drift and live-service usage.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_source_boundary.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'device_capability_probe',
        module: MaintainiacQaModule.performance,
        description:
            'Reusable device/storage policy probe for local, compact, cloud-assisted, and blocked pack modes.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_device_capability.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'scope_policy_probe',
        module: MaintainiacQaModule.security,
        description:
            'Reusable account, company, employee, vehicle, and permission scoping probe.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_scope_policy.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'audit_trail_probe',
        module: MaintainiacQaModule.security,
        description:
            'Reusable audit trail probe for ordered events and user-confirmed suggestion evidence.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_audit_trail.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'export_privacy_probe',
        module: MaintainiacQaModule.exports,
        description:
            'Reusable export ownership, private-key rejection, and sanitization probe.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_export_privacy.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'mutation_guard_probe',
        module: MaintainiacQaModule.recap,
        description:
            'Reusable guard proving derived outputs do not mutate source-of-truth collections.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_mutation_guard.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'failure_taxonomy_probe',
        module: MaintainiacQaModule.performance,
        description:
            'Reusable failure taxonomy for routing QA failures by schema, privacy, sync, money, permissions, source mutation, parser, performance, and fixture family.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_failure_taxonomy.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'execution_manifest',
        module: MaintainiacQaModule.performance,
        description:
            'Reusable manifest labels every QA check with purpose, command, cadence, owner, live-service policy, and failure action.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_execution_manifest.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'quality_gate_matrix',
        module: MaintainiacQaModule.performance,
        description:
            'Release gates include sync, security, financial, performance, regression, persistence chaos, evidence, accessibility/localization, and cost/quota coverage.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_quality_gates.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'run_ledger',
        module: MaintainiacQaModule.performance,
        description:
            'Reusable QA run ledger records command labels, input signatures, scopes, outcomes, reports, and actionable failure summaries.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_run_ledger.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'source_fingerprint',
        module: MaintainiacQaModule.performance,
        description:
            'Reusable source fingerprint helper creates deterministic input signatures for surgical rerun decisions.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_fingerprint.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'checkpoint_policy',
        module: MaintainiacQaModule.performance,
        description:
            'Reusable checkpoint policy formalizes milestone and thirty-minute GitHub backup pushes.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_checkpoint_policy.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'artifact_policy',
        module: MaintainiacQaModule.security,
        description:
            'Reusable artifact policy keeps QA reports, fixtures, and regressions redacted and out of synced or wrong-drive folders.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_artifact_policy.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'parser_candidate_contract',
        module: MaintainiacQaModule.inventory,
        description:
            'Reusable parser result contract preserves evidence, confidence reasons, warnings, missing fields, and review-only status until user confirmation.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_parser_candidate_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'parser_fixture_manifest',
        module: MaintainiacQaModule.inventory,
        description:
            'Reusable parser fixture manifest tracks locale, country, merchant, trade, owner, source, expected behavior, review date, and privacy metadata.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_parser_fixture_manifest.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'correction_learning_contract',
        module: MaintainiacQaModule.inventory,
        description:
            'Reusable correction-learning contract turns user corrections into reviewable alias/rule/regression proposals without silently mutating official packs or confirmed source records.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_correction_learning_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'local_first_contract',
        module: MaintainiacQaModule.sync,
        description:
            'Reusable local-first contract proves Hive/local source writes happen before Firestore mirror writes and derived outputs stay read-only.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_local_first_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'sync_conflict_contract',
        module: MaintainiacQaModule.sync,
        description:
            'Reusable sync conflict contract handles same-field conflicts, safe different-field merges, review queues, local wins, and mirror-only cloud behavior.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_sync_conflict_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'pricing_contract',
        module: MaintainiacQaModule.invoices,
        description:
            'Reusable pricing contract proves integer-cent tax allocation, discounts, markups, invoice/estimate totals, and read-only source pricing behavior.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_pricing_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'module_suite_matrix',
        module: MaintainiacQaModule.jobs,
        description:
            'Reusable module suite matrix labels executable, scaffolded, and planned QA coverage for inventory, expenses, jobs, estimates, invoices, calendar, maintenance, fleet, exports, and payments.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_module_suite_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'schedule_contract',
        module: MaintainiacQaModule.calendar,
        description:
            'Reusable schedule contract validates audited job scheduling, maintenance reminders, notification permission behavior, UTC storage, vehicle scoping, and non-mutating derived reminders.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_schedule_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'payment_contract',
        module: MaintainiacQaModule.payments,
        description:
            'Reusable payment contract validates audited payment/refund records, invoice links, card privacy, deterministic ledger effects, and read-only invoice source totals.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_payment_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'job_contract',
        module: MaintainiacQaModule.jobs,
        description:
            'Reusable job contract validates confirmed estimate and receipt-backed job materials, audit IDs, local-first material changes, user confirmation, and read-only derived job summaries.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_job_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'inventory_parser_consumer',
        module: MaintainiacQaModule.inventory,
        description:
            'Inventory parser QA consumer is registered and has extensive domain suites.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: [
          'work_supply_parser_domain_adapter',
          'maintainiac_inventory_parser_consumer_contract.dart',
          'maintainiac_inventory_parser_consumer_test.dart',
        ],
      ),
      MaintainiacQaReadinessItem(
        id: 'expense_parser_consumer',
        module: MaintainiacQaModule.expenses,
        description:
            'Expense receipt parser is registered as a parser QA platform consumer.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: [
          'expense_receipt_parser_domain_adapter',
          'maintainiac_expense_parser_consumer_contract.dart',
          'maintainiac_expense_parser_consumer_test.dart',
        ],
      ),
      MaintainiacQaReadinessItem(
        id: 'module_specific_suites',
        module: MaintainiacQaModule.jobs,
        description:
            'Every app module gets executable suites on top of the shared backbone.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_module_suite_contract.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'surgical_selector_coverage',
        module: MaintainiacQaModule.performance,
        description:
            'Every focused parser-consumer QA behavior has an individual plain-name selector.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: [
          'maintainiac_surgical_test_selector.dart',
          'maintainiac_surgical_selector_coverage.dart',
        ],
      ),
      MaintainiacQaReadinessItem(
        id: 'surgical_rerun_router',
        module: MaintainiacQaModule.performance,
        description:
            'Changed parser QA contract files map to exact individual rerun commands.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_surgical_rerun_router.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'source_truth_gate',
        module: MaintainiacQaModule.sync,
        description:
            'Hive/local source records, Firestore mirrors, parser suggestions, and derived outputs have explicit mutation rules.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_source_truth_gate.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'financial_formula_registry',
        module: MaintainiacQaModule.invoices,
        description:
            'Money formulas, rounding policies, source-mutation rules, and individual test commands are registered across release-one money modules.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_financial_formula_registry.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'qa_telemetry_privacy_gate',
        module: MaintainiacQaModule.privacy,
        description:
            'QA reports, admin dashboards, parser diagnostics, export artifacts, and run ledgers have redaction rules.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_qa_telemetry_privacy_gate.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'release_evidence_bundle',
        module: MaintainiacQaModule.performance,
        description:
            'Milestone evidence requirements include analyzer, individual tests, backbone visibility, privacy, source-truth, and GitHub push proof.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_release_evidence_bundle.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'fixture_governance_gate',
        module: MaintainiacQaModule.security,
        description:
            'Fixture families have owner, metadata, privacy level, review cadence, and repository storage rules.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_fixture_governance_gate.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'restart_lifecycle_gate',
        module: MaintainiacQaModule.sync,
        description:
            'Drafts, reviews, local writes, partial syncs, and conflict queues have restart recovery expectations.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_restart_lifecycle_gate.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'module_boundary_gate',
        module: MaintainiacQaModule.security,
        description:
            'QA module lanes define allowed paths, forbidden tokens, owners, and violation actions.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_module_boundary_gate.dart'],
      ),
      MaintainiacQaReadinessItem(
        id: 'performance_budget_registry',
        module: MaintainiacQaModule.performance,
        description:
            'Named performance budgets exist for backbone, indexing, generated fixtures, reports, rerun routing, and memory.',
        status: MaintainiacQaReadinessStatus.ready,
        evidence: ['maintainiac_performance_budget_registry.dart'],
      ),
    ]);
  }

  final List<MaintainiacQaReadinessItem> items;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    for (final item in items) {
      if (!ids.add(item.id)) {
        failures.add('duplicate readiness item ${item.id}');
      }
      failures.addAll(item.validate());
    }
    return failures;
  }

  bool get releaseReady {
    return items.every(
      (item) => item.status == MaintainiacQaReadinessStatus.ready,
    );
  }

  Map<String, int> get countsByStatus {
    return {
      for (final status in MaintainiacQaReadinessStatus.values)
        status.name: items.where((item) => item.status == status).length,
    };
  }

  Map<String, Object?> toJson() {
    return {
      'releaseReady': releaseReady,
      'countsByStatus': countsByStatus,
      'items': [for (final item in items) item.toJson()],
    };
  }
}
