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

class MaintainiacSourceAuditDebt {
  const MaintainiacSourceAuditDebt({
    required this.path,
    required this.owner,
    required this.reason,
    required this.splitPlan,
    required this.targetMaxLines,
  });

  final String path;
  final String owner;
  final String reason;
  final String splitPlan;
  final int targetMaxLines;

  List<String> validate() {
    final failures = <String>[];
    if (path.trim().isEmpty) failures.add('source debt missing path');
    if (owner.trim().isEmpty) failures.add('$path missing owner');
    if (reason.trim().isEmpty) failures.add('$path missing reason');
    if (splitPlan.trim().isEmpty) failures.add('$path missing split plan');
    if (targetMaxLines <= 0 || targetMaxLines > 1000) {
      failures.add('$path target max lines must be 1..1000');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'path': path,
      'owner': owner,
      'reason': reason,
      'splitPlan': splitPlan,
      'targetMaxLines': targetMaxLines,
    };
  }
}

class MaintainiacSourceAuditDebtLedger {
  const MaintainiacSourceAuditDebtLedger(this.debts);

  final List<MaintainiacSourceAuditDebt> debts;

  List<String> validate({Set<String> actualOversizedPaths = const {}}) {
    final failures = <String>[];
    final paths = <String>{};
    for (final debt in debts) {
      if (!paths.add(_normalizePath(debt.path))) {
        failures.add('duplicate source debt ${debt.path}');
      }
      failures.addAll(debt.validate());
    }
    for (final path in actualOversizedPaths.map(_normalizePath)) {
      if (!paths.contains(path)) {
        failures.add('oversized production file missing debt entry $path');
      }
    }
    return failures;
  }

  List<String> validateAgainstPolicy(MaintainiacSourceAuditPolicy policy) {
    final failures = validate();
    for (final debt in debts) {
      final normalizedPath = _normalizePath(debt.path);
      final rule = policy.ruleFor(normalizedPath);
      if (rule == null) {
        failures.add('$normalizedPath has no source audit rule');
        continue;
      }
      if (rule.scope != MaintainiacSourceAuditScope.production) {
        failures.add('$normalizedPath debt must be production scoped');
      }
      if (!normalizedPath.startsWith('lib/')) {
        failures.add('$normalizedPath debt must target a production lib file');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'debtCount': debts.length,
      'debts': [for (final debt in debts) debt.toJson()],
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

const maintainiacSourceAuditDebtLedger = MaintainiacSourceAuditDebtLedger([
  MaintainiacSourceAuditDebt(
    path: 'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    owner: 'inventory_parser',
    reason: 'Legacy generated parser surface is over the production cap.',
    splitPlan: 'Split parser stages, token maps, and scoring helpers.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path:
        'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    owner: 'receipt_camera',
    reason: 'Camera review controls need modular extraction.',
    splitPlan: 'Split controls, actions, preview, and state adapters.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path:
        'lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_core.dart',
    owner: 'inventory_parser',
    reason: 'Trade score generated data exceeds app file cap.',
    splitPlan: 'Shard generated trade score tables by family.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/screens/expenses/data/expense_screen_telemetry.dart',
    owner: 'expenses',
    reason: 'Expense telemetry helper is too broad.',
    splitPlan: 'Split event schema, redaction, counters, and summaries.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
    owner: 'receipt_camera',
    reason: 'Image processing implementation is over the production cap.',
    splitPlan: 'Split transforms, validation, persistence, and diagnostics.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path:
        'lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_finishes.dart',
    owner: 'inventory_parser',
    reason: 'Generated finish scoring data exceeds app file cap.',
    splitPlan: 'Shard finish score data by material and surface family.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    owner: 'expenses',
    reason: 'Expense receipt entry screen needs smaller view components.',
    splitPlan: 'Split layout sections, actions, and review summaries.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/screens/invoices/data/invoice_pdf_template_renderer.dart',
    owner: 'invoices',
    reason: 'Invoice PDF renderer needs template module split.',
    splitPlan: 'Split header, line items, totals, and rendering utilities.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/screens/expenses/data/expense_receipt_parser_logic.dart',
    owner: 'expenses',
    reason: 'Expense parser logic needs staged parser modules.',
    splitPlan: 'Split normalization, extraction, categorization, and review.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
    owner: 'receipt_camera',
    reason: 'Receipt capture model file exceeds app file cap.',
    splitPlan: 'Split source, derived artifact, review, and queue models.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/shared/widgets/receipt_capture/receipt_ocr_service.dart',
    owner: 'receipt_camera',
    reason: 'OCR service file exceeds app file cap.',
    splitPlan:
        'Split provider contracts, local adapter, cloud adapter, and errors.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path:
        'lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_exterior.dart',
    owner: 'inventory_parser',
    reason: 'Generated exterior score data exceeds app file cap.',
    splitPlan: 'Shard exterior score data by family.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    owner: 'receipt_camera',
    reason: 'Receipt review screen needs component extraction.',
    splitPlan: 'Split preview, controls, warnings, and navigation surfaces.',
    targetMaxLines: 1000,
  ),
  MaintainiacSourceAuditDebt(
    path: 'lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart',
    owner: 'expenses',
    reason: 'Expense entry actions file exceeds app file cap.',
    splitPlan: 'Split draft, save, review, parser, and sync actions.',
    targetMaxLines: 1000,
  ),
]);

String _normalizePath(String path) => path.replaceAll('\\', '/');
