import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFleetPermissionContextSuite extends QaSuite {
  const WorkSupplyParserFleetPermissionContextSuite()
    : super('inventory.fleet_permission_context_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_barcode_inventory_identity_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_job_context_bridge_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_admin_privacy_rollup_qa.dart',
    'test/work_supply_parser_fleet_permission_context_behavior_test.dart',
    'lib/screens/work_supplies/data/work_supply_inventory_destination.dart',
  };

  static const _fleetContextTokens = {
    'fleet',
    'vehicle',
    'truck',
    'employee',
    'helper',
    'owner',
    'permission',
    'role',
    'shop inventory',
    'vehicle inventory',
    'job staging',
    'active job',
  };

  static const _permissionRules = {
    'parser_candidate_does_not_grant_inventory_permission',
    'employee_context_can_filter_vehicle_inventory',
    'owner_context_can_see_company_inventory',
    'helper_context_requires_limited_actions',
    'vehicle_inventory_context_can_boost_ranking',
    'vehicle_inventory_context_does_not_force_match',
    'fleet_inventory_is_separate_from_catalog_pack',
    'same_item_can_exist_in_multiple_vehicle_locations',
    'permission_denied_returns_review_warning',
    'admin_rollup_never_exposes_employee_private_data',
  };

  static const _workflowRiskTokens = {
    'add to inventory',
    'add to job',
    'add to estimate',
    'add to invoice',
    'transfer vehicle',
    'mark out of stock',
    'purchased not in stock',
    'review-only',
    'suggested action',
    'warnings',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _fleetContextTokens.length;
    _requireTokens(
      failures,
      source,
      _fleetContextTokens,
      idPrefix: 'missing_fleet_context',
      message: 'Fleet/permission parser QA is missing required context.',
      fix:
          'Parser QA must model owner, employee/helper, vehicle, fleet, shop, job-staging, and active-job contexts.',
      triage: QaFailureTriage.governance,
    );

    checked += _permissionRules.length;
    _requireRules(failures, source, _permissionRules);

    checked += _workflowRiskTokens.length;
    _requireTokens(
      failures,
      source,
      _workflowRiskTokens,
      idPrefix: 'missing_fleet_workflow_risk',
      message: 'Fleet/permission parser QA is missing workflow risk coverage.',
      fix:
          'Parser suggestions must stay review-only and permission-aware before inventory, job, estimate, invoice, transfer, or stock actions.',
      triage: QaFailureTriage.reviewSafety,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Fleet, vehicle, employee, and permission context may guide parser ranking, but never authorizes silent inventory or job writes.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_fleet_permission_rule:${_safeId(rule)}',
          message: 'Fleet/permission parser QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit fleet and permission rules before parser candidates can route into company inventory workflows.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
