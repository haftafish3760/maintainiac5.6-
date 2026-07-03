enum MaintainiacSourceAuditScope { production, qaHarness, docs }

class MaintainiacSourceAuditRule {
  const MaintainiacSourceAuditRule({
    required this.id,
    required this.scope,
    required this.pathPrefix,
    required this.preferredMaxLines,
    required this.hardMaxLines,
    required this.reason,
  });

  final String id;
  final MaintainiacSourceAuditScope scope;
  final String pathPrefix;
  final int preferredMaxLines;
  final int hardMaxLines;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('source audit rule missing id');
    }
    if (pathPrefix.trim().isEmpty) {
      failures.add('$id missing path prefix');
    }
    if (preferredMaxLines <= 0) {
      failures.add('$id missing preferred line limit');
    }
    if (hardMaxLines < preferredMaxLines) {
      failures.add('$id hard limit must be at least preferred limit');
    }
    if (scope == MaintainiacSourceAuditScope.production &&
        hardMaxLines > 1000) {
      failures.add('$id production hard limit must not exceed 1000 lines');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    return failures;
  }

  bool appliesTo(String path) {
    return path.replaceAll('\\', '/').startsWith(pathPrefix);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'scope': scope.name,
      'pathPrefix': pathPrefix,
      'preferredMaxLines': preferredMaxLines,
      'hardMaxLines': hardMaxLines,
      'reason': reason,
    };
  }
}

class MaintainiacSourceAuditPolicy {
  const MaintainiacSourceAuditPolicy(this.rules);

  final List<MaintainiacSourceAuditRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final scopes = <MaintainiacSourceAuditScope>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate source audit rule ${rule.id}');
      }
      scopes.add(rule.scope);
      failures.addAll(rule.validate());
    }
    for (final required in MaintainiacSourceAuditScope.values) {
      if (!scopes.contains(required)) {
        failures.add('source audit policy missing scope ${required.name}');
      }
    }
    return failures;
  }

  MaintainiacSourceAuditRule? ruleFor(String path) {
    for (final rule in rules) {
      if (rule.appliesTo(path)) {
        return rule;
      }
    }
    return null;
  }

  String? violationFor({required String path, required int lineCount}) {
    final rule = ruleFor(path);
    if (rule == null) {
      return 'No source audit rule covers $path';
    }
    if (lineCount > rule.hardMaxLines) {
      return '$path exceeds hard line limit ${rule.hardMaxLines}';
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'rules': [for (final rule in rules) rule.toJson()],
    };
  }
}

const maintainiacSourceAuditPolicy = MaintainiacSourceAuditPolicy([
  MaintainiacSourceAuditRule(
    id: 'production_dart_modularity',
    scope: MaintainiacSourceAuditScope.production,
    pathPrefix: 'lib/',
    preferredMaxLines: 500,
    hardMaxLines: 1000,
    reason:
        'Production app files should stay modular unless functionality requires a documented exception.',
  ),
  MaintainiacSourceAuditRule(
    id: 'qa_harness_modularity',
    scope: MaintainiacSourceAuditScope.qaHarness,
    pathPrefix: 'test/support/qa_harness/',
    preferredMaxLines: 750,
    hardMaxLines: 1500,
    reason:
        'QA infrastructure may be larger than UI files but still needs bounded modules.',
  ),
  MaintainiacSourceAuditRule(
    id: 'test_file_modularity',
    scope: MaintainiacSourceAuditScope.qaHarness,
    pathPrefix: 'test/',
    preferredMaxLines: 750,
    hardMaxLines: 1500,
    reason:
        'Tests can be larger than app files, but one file should not become the whole suite.',
  ),
  MaintainiacSourceAuditRule(
    id: 'qa_docs_modularity',
    scope: MaintainiacSourceAuditScope.docs,
    pathPrefix: 'docs/qa/',
    preferredMaxLines: 1000,
    hardMaxLines: 3000,
    reason:
        'QA plans can be long-form docs, but very large docs should be split by topic.',
  ),
]);
