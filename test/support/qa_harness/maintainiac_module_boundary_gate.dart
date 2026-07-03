class MaintainiacModuleBoundaryRule {
  const MaintainiacModuleBoundaryRule({
    required this.id,
    required this.owner,
    required this.module,
    required this.allowedPathPrefixes,
    required this.forbiddenPathTokens,
    required this.violationAction,
  });

  final String id;
  final String owner;
  final String module;
  final Set<String> allowedPathPrefixes;
  final Set<String> forbiddenPathTokens;
  final String violationAction;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('module boundary rule missing id');
    if (owner.trim().isEmpty) failures.add('$id missing owner');
    if (module.trim().isEmpty) failures.add('$id missing module');
    if (allowedPathPrefixes.isEmpty) {
      failures.add('$id missing allowed path prefixes');
    }
    if (forbiddenPathTokens.isEmpty) {
      failures.add('$id missing forbidden path tokens');
    }
    if (violationAction.trim().isEmpty) {
      failures.add('$id missing violation action');
    }
    return failures;
  }

  bool allowsPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return allowedPathPrefixes.any(normalized.startsWith) &&
        !forbiddenPathTokens.any(normalized.toLowerCase().contains);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'owner': owner,
      'module': module,
      'allowedPathPrefixes': allowedPathPrefixes.toList()..sort(),
      'forbiddenPathTokens': forbiddenPathTokens.toList()..sort(),
      'violationAction': violationAction,
    };
  }
}

class MaintainiacModuleBoundaryGate {
  const MaintainiacModuleBoundaryGate(this.rules);

  final List<MaintainiacModuleBoundaryRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final modules = <String>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate module boundary rule ${rule.id}');
      }
      modules.add(rule.module);
      failures.addAll(rule.validate());
    }
    for (final required in {
      'inventory',
      'expenses',
      'parser_qa',
      'sync',
      'exports',
      'security_privacy',
    }) {
      if (!modules.contains(required)) {
        failures.add('module boundary gate missing module $required');
      }
    }
    return failures;
  }

  List<String> violationsFor(String ruleId, Iterable<String> paths) {
    final rule = rules.firstWhere((entry) => entry.id == ruleId);
    return [
      for (final path in paths)
        if (!rule.allowsPath(path)) path,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'rules': [for (final rule in rules) rule.toJson()],
    };
  }
}

const _forbiddenCameraOcrTokens = {
  'camera',
  'ocr',
  'mlkit',
  'googlevision',
  'textrecognizer',
};

const maintainiacModuleBoundaryGate = MaintainiacModuleBoundaryGate([
  MaintainiacModuleBoundaryRule(
    id: 'inventory_parser_lane',
    owner: 'inventory-qa',
    module: 'inventory',
    allowedPathPrefixes: {
      'test/support/qa_harness/',
      'test/support/work_supply_parser_qa/',
      'test/maintainiac_',
      'test/work_supply_',
      'docs/qa/',
    },
    forbiddenPathTokens: _forbiddenCameraOcrTokens,
    violationAction:
        'Stop inventory QA edits and move OCR/camera work to the dedicated thread.',
  ),
  MaintainiacModuleBoundaryRule(
    id: 'expense_parser_lane',
    owner: 'expense-qa',
    module: 'expenses',
    allowedPathPrefixes: {
      'test/support/qa_harness/',
      'test/expense_',
      'test/maintainiac_',
      'docs/qa/',
    },
    forbiddenPathTokens: _forbiddenCameraOcrTokens,
    violationAction:
        'Keep expense parser QA provider-free and do not edit OCR/camera implementation.',
  ),
  MaintainiacModuleBoundaryRule(
    id: 'parser_qa_lane',
    owner: 'maintainiac-qa',
    module: 'parser_qa',
    allowedPathPrefixes: {
      'test/support/qa_harness/',
      'test/support/parser_qa_platform/',
      'test/maintainiac_',
      'docs/qa/',
    },
    forbiddenPathTokens: _forbiddenCameraOcrTokens,
    violationAction:
        'Parser QA may model provider boundaries but must not modify provider implementation.',
  ),
  MaintainiacModuleBoundaryRule(
    id: 'sync_lane',
    owner: 'sync-qa',
    module: 'sync',
    allowedPathPrefixes: {
      'test/support/qa_harness/',
      'test/maintainiac_',
      'docs/qa/',
    },
    forbiddenPathTokens: {'firebase_live_write', 'production_firestore'},
    violationAction:
        'Use fakes/emulators and never run live sync writes from QA harness tests.',
  ),
  MaintainiacModuleBoundaryRule(
    id: 'exports_lane',
    owner: 'exports-qa',
    module: 'exports',
    allowedPathPrefixes: {
      'test/support/qa_harness/',
      'test/maintainiac_',
      'docs/qa/',
    },
    forbiddenPathTokens: {'rawreceipttext', 'cardnumber', 'patient'},
    violationAction:
        'Exports QA must stay redacted and owned; raw private fields are forbidden.',
  ),
  MaintainiacModuleBoundaryRule(
    id: 'security_privacy_lane',
    owner: 'security-qa',
    module: 'security_privacy',
    allowedPathPrefixes: {
      'test/support/qa_harness/',
      'test/maintainiac_',
      'docs/qa/',
    },
    forbiddenPathTokens: {'secret_key', 'service_account', 'private_key'},
    violationAction:
        'Security QA must not introduce secrets or live credentials into repo fixtures.',
  ),
]);
