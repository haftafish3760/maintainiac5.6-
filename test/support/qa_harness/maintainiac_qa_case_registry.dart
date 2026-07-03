import 'maintainiac_qa_environment.dart';

enum MaintainiacQaCasePriority { releaseBlocker, core, standard, hardening }

class MaintainiacQaCase {
  const MaintainiacQaCase({
    required this.id,
    required this.title,
    required this.module,
    required this.behavior,
    required this.evidenceTarget,
    required this.priority,
    this.testCommand = '',
    this.tags = const {},
  });

  final String id;
  final String title;
  final MaintainiacQaModule module;
  final String behavior;
  final String evidenceTarget;
  final MaintainiacQaCasePriority priority;
  final String testCommand;
  final Set<String> tags;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('case missing id');
    if (title.trim().isEmpty) failures.add('$id missing title');
    if (behavior.trim().isEmpty) failures.add('$id missing behavior');
    if (evidenceTarget.trim().isEmpty) {
      failures.add('$id missing evidence target');
    }
    if (tags.any((tag) => tag.trim().isEmpty)) {
      failures.add('$id has blank tag');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'module': module.name,
      'behavior': behavior,
      'evidenceTarget': evidenceTarget,
      'priority': priority.name,
      if (testCommand.isNotEmpty) 'testCommand': testCommand,
      'tags': tags.toList()..sort(),
    };
  }
}

class MaintainiacQaCaseRegistry {
  const MaintainiacQaCaseRegistry(this.cases);

  factory MaintainiacQaCaseRegistry.backboneSeed() {
    return const MaintainiacQaCaseRegistry([
      MaintainiacQaCase(
        id: 'QA-BACKBONE-001',
        title: 'Whole-app backbone contract',
        module: MaintainiacQaModule.performance,
        behavior:
            'The shared QA harness exposes modules, fakes, fixtures, gates, readiness, and parser adapters without live services.',
        evidenceTarget: 'maintainiac.qa_backbone_contract',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        testCommand: 'flutter test test/maintainiac_qa_backbone_test.dart',
        tags: {'backbone', 'release-gate', 'no-live-services'},
      ),
      MaintainiacQaCase(
        id: 'QA-SYNC-001',
        title: 'Local write before cloud mirror',
        module: MaintainiacQaModule.sync,
        behavior:
            'Hive/local writes are recorded before Firestore mirror writes.',
        evidenceTarget: 'sync.local_write_before_mirror',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        tags: {'hive-source-of-truth', 'firestore-mirror'},
      ),
      MaintainiacQaCase(
        id: 'QA-SEC-001',
        title: 'Forbidden private data scan',
        module: MaintainiacQaModule.security,
        behavior:
            'VIN, plate-like, passenger/patient, and card-like data are detected before logs or reports expose them.',
        evidenceTarget: 'security.forbidden_data_scan',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        tags: {'privacy', 'redaction', 'security'},
      ),
      MaintainiacQaCase(
        id: 'QA-MONEY-001',
        title: 'Deterministic cents-only ledger',
        module: MaintainiacQaModule.expenses,
        behavior:
            'Expense totals, tax, discounts, refunds, and category rollups balance in integer cents.',
        evidenceTarget: 'maintainiac_financial_ledger_test',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        testCommand: 'flutter test test/maintainiac_financial_ledger_test.dart',
        tags: {'expenses', 'money', 'ledger'},
      ),
      MaintainiacQaCase(
        id: 'QA-BOUNDARY-001',
        title: 'Forbidden implementation boundary scan',
        module: MaintainiacQaModule.security,
        behavior:
            'Parser and harness lanes can prove they did not drift into camera, OCR provider, or live Firebase code.',
        evidenceTarget: 'maintainiac_source_boundary_test',
        priority: MaintainiacQaCasePriority.core,
        testCommand: 'flutter test test/maintainiac_source_boundary_test.dart',
        tags: {'boundary', 'ocr-off-limits', 'firebase'},
      ),
      MaintainiacQaCase(
        id: 'QA-DEVICE-001',
        title: 'Device storage pack-mode policy',
        module: MaintainiacQaModule.performance,
        behavior:
            'The app chooses local, compact-local, cloud-assisted, or blocked pack mode from device capability, storage, App Check, and network state.',
        evidenceTarget: 'maintainiac_device_capability_test',
        priority: MaintainiacQaCasePriority.core,
        testCommand:
            'flutter test test/maintainiac_device_capability_test.dart',
        tags: {'device', 'storage', 'pack-delivery'},
      ),
      MaintainiacQaCase(
        id: 'QA-SCOPE-001',
        title: 'Account company employee and vehicle scoping',
        module: MaintainiacQaModule.security,
        behavior:
            'Records are accessible only when account, company, employee, assigned vehicle, and required permission rules pass.',
        evidenceTarget: 'maintainiac_scope_policy_test',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        testCommand: 'flutter test test/maintainiac_scope_policy_test.dart',
        tags: {'security', 'permissions', 'fleet'},
      ),
      MaintainiacQaCase(
        id: 'QA-AUDIT-001',
        title: 'Audit trail completeness and user confirmation',
        module: MaintainiacQaModule.security,
        behavior:
            'Audit events preserve actor, action, target, ordered timestamps, and before/after evidence when users confirm parser suggestions.',
        evidenceTarget: 'maintainiac_audit_trail_test',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        testCommand: 'flutter test test/maintainiac_audit_trail_test.dart',
        tags: {'audit', 'confirmation', 'regression'},
      ),
      MaintainiacQaCase(
        id: 'QA-EXPORT-001',
        title: 'Export ownership and privacy sanitization',
        module: MaintainiacQaModule.exports,
        behavior:
            'Exports include only active-account records and reject or remove private fields before writing.',
        evidenceTarget: 'maintainiac_export_privacy_test',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        testCommand: 'flutter test test/maintainiac_export_privacy_test.dart',
        tags: {'exports', 'privacy', 'ownership'},
      ),
      MaintainiacQaCase(
        id: 'QA-MUTATION-001',
        title: 'Derived outputs do not mutate source records',
        module: MaintainiacQaModule.recap,
        behavior:
            'Recaps, exports, notifications, estimates, invoices, and reports cannot write source collections unless explicitly scoped as a source operation.',
        evidenceTarget: 'maintainiac_mutation_guard_test',
        priority: MaintainiacQaCasePriority.releaseBlocker,
        testCommand: 'flutter test test/maintainiac_mutation_guard_test.dart',
        tags: {'source-of-truth', 'derived-output', 'mutation-guard'},
      ),
      MaintainiacQaCase(
        id: 'QA-FAILURE-001',
        title: 'Failure taxonomy routes QA failures',
        module: MaintainiacQaModule.performance,
        behavior:
            'QA failures are classified into stable categories so reports can route issues instead of emitting vague failure text.',
        evidenceTarget: 'maintainiac_failure_taxonomy_test',
        priority: MaintainiacQaCasePriority.core,
        testCommand: 'flutter test test/maintainiac_failure_taxonomy_test.dart',
        tags: {'failure-routing', 'admin-report', 'triage'},
      ),
    ]);
  }

  final List<MaintainiacQaCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final evidenceTargets = <String>{};
    for (final qaCase in cases) {
      if (!ids.add(qaCase.id)) {
        failures.add('duplicate QA case id ${qaCase.id}');
      }
      if (!evidenceTargets.add(qaCase.evidenceTarget)) {
        failures.add('duplicate evidence target ${qaCase.evidenceTarget}');
      }
      failures.addAll(qaCase.validate());
    }
    return failures;
  }

  List<MaintainiacQaCase> byPriority(MaintainiacQaCasePriority priority) {
    return [
      for (final qaCase in cases)
        if (qaCase.priority == priority) qaCase,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'releaseBlockerCount': byPriority(
        MaintainiacQaCasePriority.releaseBlocker,
      ).length,
      'cases': [for (final qaCase in cases) qaCase.toJson()],
    };
  }
}
