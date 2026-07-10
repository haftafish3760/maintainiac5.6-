class MaintainiacDerivedOutputRule {
  const MaintainiacDerivedOutputRule({
    required this.id,
    required this.module,
    required this.outputFamily,
    required this.readSourceFamilies,
    required this.allowedOutputWrites,
    required this.forbiddenSourceWrites,
    required this.reason,
  });

  final String id;
  final String module;
  final String outputFamily;
  final Set<String> readSourceFamilies;
  final Set<String> allowedOutputWrites;
  final Set<String> forbiddenSourceWrites;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('derived output rule missing id');
    }
    if (module.trim().isEmpty) {
      failures.add('$id missing module');
    }
    if (outputFamily.trim().isEmpty) {
      failures.add('$id missing output family');
    }
    if (readSourceFamilies.isEmpty) {
      failures.add('$id must declare source reads');
    }
    if (allowedOutputWrites.isEmpty) {
      failures.add('$id must declare allowed output writes');
    }
    if (forbiddenSourceWrites.isEmpty) {
      failures.add('$id must declare forbidden source writes');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    for (final write in allowedOutputWrites) {
      if (forbiddenSourceWrites.contains(write)) {
        failures.add('$id allows and forbids $write');
      }
    }
    return failures;
  }

  bool forbidsSourceWrite(String family) {
    return forbiddenSourceWrites.contains(family);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module,
      'outputFamily': outputFamily,
      'readSourceFamilies': readSourceFamilies.toList()..sort(),
      'allowedOutputWrites': allowedOutputWrites.toList()..sort(),
      'forbiddenSourceWrites': forbiddenSourceWrites.toList()..sort(),
      'reason': reason,
    };
  }
}

class MaintainiacDerivedOutputContract {
  const MaintainiacDerivedOutputContract(this.rules);

  final List<MaintainiacDerivedOutputRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final modules = <String>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate derived output rule ${rule.id}');
      }
      modules.add(rule.module);
      failures.addAll(rule.validate());
    }
    for (final required in {
      'recap',
      'exports',
      'estimates',
      'invoices',
      'notifications',
    }) {
      if (!modules.contains(required)) {
        failures.add('derived output contract missing module $required');
      }
    }
    return failures;
  }

  List<MaintainiacDerivedOutputRule> rulesForModule(String module) {
    return [
      for (final rule in rules)
        if (rule.module == module) rule,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'modules': ({for (final rule in rules) rule.module}.toList()..sort()),
      'rules': [for (final rule in rules) rule.toJson()],
    };
  }
}

const _sourceFamilies = {
  'expenses',
  'inventory',
  'trips',
  'odometer',
  'jobs',
  'maintenance',
};

const maintainiacDerivedOutputContract = MaintainiacDerivedOutputContract([
  MaintainiacDerivedOutputRule(
    id: 'recap_reads_sources_writes_summary',
    module: 'recap',
    outputFamily: 'recap_summary',
    readSourceFamilies: _sourceFamilies,
    allowedOutputWrites: {'recap_summary'},
    forbiddenSourceWrites: _sourceFamilies,
    reason: 'Recaps summarize source records and must not mutate them.',
  ),
  MaintainiacDerivedOutputRule(
    id: 'exports_read_sources_write_artifacts',
    module: 'exports',
    outputFamily: 'export_artifact',
    readSourceFamilies: _sourceFamilies,
    allowedOutputWrites: {'export_artifact'},
    forbiddenSourceWrites: _sourceFamilies,
    reason: 'Exports create files from source records without editing sources.',
  ),
  MaintainiacDerivedOutputRule(
    id: 'estimates_read_sources_write_estimate_output',
    module: 'estimates',
    outputFamily: 'estimate_output',
    readSourceFamilies: {'expenses', 'inventory', 'jobs'},
    allowedOutputWrites: {'estimate_output'},
    forbiddenSourceWrites: {'expenses', 'inventory', 'jobs'},
    reason: 'Estimate documents are derived from source business records.',
  ),
  MaintainiacDerivedOutputRule(
    id: 'invoices_read_sources_write_invoice_output',
    module: 'invoices',
    outputFamily: 'invoice_output',
    readSourceFamilies: {'expenses', 'inventory', 'jobs', 'estimates'},
    allowedOutputWrites: {'invoice_output'},
    forbiddenSourceWrites: {'expenses', 'inventory', 'jobs', 'estimates'},
    reason: 'Invoices are output records and cannot rewrite source truth.',
  ),
  MaintainiacDerivedOutputRule(
    id: 'notifications_read_sources_schedule_events',
    module: 'notifications',
    outputFamily: 'notification_event',
    readSourceFamilies: {'expenses', 'maintenance', 'jobs', 'calendar'},
    allowedOutputWrites: {'notification_event'},
    forbiddenSourceWrites: {'expenses', 'maintenance', 'jobs', 'calendar'},
    reason:
        'Notifications schedule reminders from source data without changing it.',
  ),
]);
