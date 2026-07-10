enum MaintainiacSourceTruthRole { source, mirror, suggestion, derivedOutput }

class MaintainiacSourceTruthRule {
  const MaintainiacSourceTruthRule({
    required this.id,
    required this.module,
    required this.recordFamily,
    required this.role,
    required this.allowedToMutateSource,
    required this.mustBeUserConfirmed,
    required this.reason,
  });

  final String id;
  final String module;
  final String recordFamily;
  final MaintainiacSourceTruthRole role;
  final bool allowedToMutateSource;
  final bool mustBeUserConfirmed;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('source truth rule missing id');
    if (module.trim().isEmpty) failures.add('$id missing module');
    if (recordFamily.trim().isEmpty) failures.add('$id missing record family');
    if (reason.trim().isEmpty) failures.add('$id missing reason');
    if (role == MaintainiacSourceTruthRole.mirror && allowedToMutateSource) {
      failures.add('$id mirror must not mutate source records');
    }
    if (role == MaintainiacSourceTruthRole.suggestion &&
        allowedToMutateSource &&
        !mustBeUserConfirmed) {
      failures.add('$id suggestion cannot mutate source without confirmation');
    }
    if (role == MaintainiacSourceTruthRole.derivedOutput &&
        allowedToMutateSource) {
      failures.add('$id derived output must not mutate source records');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module,
      'recordFamily': recordFamily,
      'role': role.name,
      'allowedToMutateSource': allowedToMutateSource,
      'mustBeUserConfirmed': mustBeUserConfirmed,
      'reason': reason,
    };
  }
}

class MaintainiacSourceTruthGate {
  const MaintainiacSourceTruthGate(this.rules);

  final List<MaintainiacSourceTruthRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final modules = <String>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate source truth rule ${rule.id}');
      }
      modules.add(rule.module);
      failures.addAll(rule.validate());
    }
    for (final required in {
      'expenses',
      'inventory',
      'jobs',
      'estimates',
      'invoices',
      'recap',
      'exports',
      'sync',
    }) {
      if (!modules.contains(required)) {
        failures.add('source truth gate missing module $required');
      }
    }
    return failures;
  }

  List<MaintainiacSourceTruthRule> mutableSourceRules() {
    return [
      for (final rule in rules)
        if (rule.allowedToMutateSource) rule,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'mutableSourceRuleCount': mutableSourceRules().length,
      'rules': [for (final rule in rules) rule.toJson()],
    };
  }
}

const maintainiacSourceTruthGate = MaintainiacSourceTruthGate([
  MaintainiacSourceTruthRule(
    id: 'expenses_user_confirmed_source',
    module: 'expenses',
    recordFamily: 'expense',
    role: MaintainiacSourceTruthRole.source,
    allowedToMutateSource: true,
    mustBeUserConfirmed: true,
    reason: 'Confirmed expense records are local source-of-truth records.',
  ),
  MaintainiacSourceTruthRule(
    id: 'inventory_user_confirmed_source',
    module: 'inventory',
    recordFamily: 'inventory_movement',
    role: MaintainiacSourceTruthRole.source,
    allowedToMutateSource: true,
    mustBeUserConfirmed: true,
    reason: 'Confirmed inventory movements update local stock truth.',
  ),
  MaintainiacSourceTruthRule(
    id: 'jobs_material_source',
    module: 'jobs',
    recordFamily: 'job_material',
    role: MaintainiacSourceTruthRole.source,
    allowedToMutateSource: true,
    mustBeUserConfirmed: true,
    reason: 'Job material changes are explicit local source operations.',
  ),
  MaintainiacSourceTruthRule(
    id: 'estimate_output_read_only',
    module: 'estimates',
    recordFamily: 'estimate_output',
    role: MaintainiacSourceTruthRole.derivedOutput,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason: 'Estimate outputs read expenses/inventory without mutating them.',
  ),
  MaintainiacSourceTruthRule(
    id: 'invoice_output_read_only',
    module: 'invoices',
    recordFamily: 'invoice_output',
    role: MaintainiacSourceTruthRole.derivedOutput,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason:
        'Invoice outputs read source records without silently changing them.',
  ),
  MaintainiacSourceTruthRule(
    id: 'recap_read_only',
    module: 'recap',
    recordFamily: 'recap_summary',
    role: MaintainiacSourceTruthRole.derivedOutput,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason: 'Recaps summarize source records only.',
  ),
  MaintainiacSourceTruthRule(
    id: 'export_read_only',
    module: 'exports',
    recordFamily: 'export_artifact',
    role: MaintainiacSourceTruthRole.derivedOutput,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason: 'Exports write artifacts and must not mutate source records.',
  ),
  MaintainiacSourceTruthRule(
    id: 'firestore_mirror_read_only_truth',
    module: 'sync',
    recordFamily: 'firestore_payload',
    role: MaintainiacSourceTruthRole.mirror,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason: 'Firestore is backup/mirror, not the app truth.',
  ),
  MaintainiacSourceTruthRule(
    id: 'parser_suggestion_review_only',
    module: 'inventory',
    recordFamily: 'parser_candidate',
    role: MaintainiacSourceTruthRole.suggestion,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason: 'Parser candidates remain suggestions until the user confirms.',
  ),
  MaintainiacSourceTruthRule(
    id: 'expense_parser_suggestion_review_only',
    module: 'expenses',
    recordFamily: 'expense_parser_candidate',
    role: MaintainiacSourceTruthRole.suggestion,
    allowedToMutateSource: false,
    mustBeUserConfirmed: false,
    reason: 'Expense parser output cannot overwrite confirmed expense data.',
  ),
]);
