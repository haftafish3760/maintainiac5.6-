import 'dart:io';

import '../parser_qa_platform/parser_qa_platform.dart';
import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPlatformContractSuite extends QaSuite {
  const WorkSupplyParserPlatformContractSuite()
    : super('inventory.parser_platform_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _pillars = [
    _PlatformPillar('environment_independent_parser_core', [
      'environment-independent parser core',
      'pure parser input',
      'pure parser output',
      'parserQaDomainAdapters',
      'mobile adapter',
      'server adapter',
      'QA harness adapter',
      'batch parser adapter',
    ]),
    _PlatformPillar('review_only_result_contract', [
      'review-only parser result',
      'Nothing auto-saves',
      'inventory.result_contract',
      'inventory.review_safety_contract',
    ]),
    _PlatformPillar('fast_local_harness', [
      'large parser QA batches in one process',
      'fast non-Flutter parser test harness',
      'inventory.runtime_profile_contract',
      'inventory.execution_command_contract',
    ]),
    _PlatformPillar('ui_independent_parser_contracts', [
      'UI can move',
      'parser contracts must not',
      'Do not write detailed UI/widget QA',
      'inventory.boundary_guard',
    ]),
    _PlatformPillar('golden_and_generated_fixtures', [
      'golden fixtures',
      'generated risky receipt-line families',
      'inventory.golden_fixtures',
      'inventory.generated_cases',
    ]),
    _PlatformPillar('ambiguity_first_ranked_candidates', [
      'Ambiguity-first',
      'ranked candidates',
      'inventory.trade_context',
      'inventory.separation_safety',
    ]),
    _PlatformPillar('merchant_rule_packs', [
      'Merchant rule packs',
      'major merchant alias normalization',
      'inventory.merchant_rules',
    ]),
    _PlatformPillar('negative_conflict_graph', [
      'Negative-match/conflict graph',
      'inventory.alias_conflicts',
      'inventory.dangerous_words',
    ]),
    _PlatformPillar('versioned_pack_intelligence', [
      'Versioned pack intelligence',
      'chunk checksums',
      'inventory.pack_lifecycle',
      'inventory.pack_health_score',
    ]),
    _PlatformPillar('correction_review_pipeline', [
      'Correction review pipeline',
      'manual promotion',
      'inventory.correction_feedback_contract',
    ]),
    _PlatformPillar('device_storage_cloud_strategy', [
      'Device/storage strategy',
      'cloud fallback disclosure',
      'inventory.device_storage_contract',
    ]),
    _PlatformPillar('privacy_security_firebase_boundary', [
      'Security/Firebase boundary',
      'no live hosted writes in tests',
      'inventory.security_privacy',
      'inventory.no_live_services_contract',
    ]),
    _PlatformPillar('admin_safe_observability', [
      'admin-safe report',
      'Command One diagnostics',
      'inventory.admin_report_contract',
      'inventory.telemetry_contract',
    ]),
    _PlatformPillar('release_gates_and_baselines', [
      'Release gates',
      'baseline diff',
      'inventory.release_manifest',
      'inventory.baseline_contract',
    ]),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final plan = _readPlan(failures);
    final present = <String>[];
    var checked = _pillars.length + 1;

    for (final pillar in _pillars) {
      final missing = [
        for (final token in pillar.tokens)
          if (!plan.contains(token)) token,
      ];
      if (missing.isEmpty) {
        present.add(pillar.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_parser_platform_pillar:${pillar.name}',
          message: 'World-class parser platform pillar is not documented.',
          severity: QaSeverity.error,
          expected: pillar.tokens.join(' + '),
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Document the pillar and its owner suites before bulk catalog expansion.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    final adapterDomains = <String>{};
    for (final adapter in parserQaDomainAdapters) {
      checked++;
      adapterDomains.add(adapter.domain);
      final adapterFailures = adapter.validateContract();
      if (adapterFailures.isEmpty) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'invalid_inventory_domain_adapter:${adapter.domain}',
          message: 'Parser QA domain adapter does not satisfy contract.',
          severity: QaSeverity.error,
          expected: 'valid reusable parser QA domain adapter',
          actual: adapterFailures.join('; '),
          suggestedFix:
              'Fix the adapter before adding parser suites for this domain.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }
    for (final requiredDomain in _requiredAdapterDomains) {
      checked++;
      if (adapterDomains.contains(requiredDomain)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_reusable_parser_domain_adapter:$requiredDomain',
          message:
              'Reusable QA backbone is missing a required parser-domain adapter.',
          severity: QaSeverity.error,
          expected: _requiredAdapterDomains.join(', '),
          actual: adapterDomains.join(', '),
          suggestedFix:
              'Register every release-critical parser domain in parserQaDomainAdapters so inventory is not a one-off harness.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentPillars': present,
        'pillarCount': _pillars.length,
        'domainAdapters': adapterDomains.toList()..sort(),
        'plan': _planPath,
      },
    );
  }

  String _readPlan(List<QaFailure> failures) {
    final file = File(_planPath);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_parser_platform_plan',
        message: 'Parser platform contract plan file is missing.',
        expected: _planPath,
        actual: 'not found',
        suggestedFix: 'Restore the parser QA plan before release gating.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

const _requiredAdapterDomains = {
  'work_supply_inventory_parser',
  'expense_receipt_parser',
  'maintenance_parser',
};

class _PlatformPillar {
  const _PlatformPillar(this.name, this.tokens);

  final String name;
  final List<String> tokens;
}
