import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

const _defaultOutputDir = 'build/parser_qa_curation/plumbing_core';

void main(List<String> args) {
  final outputDir = _argValue(args, '--output-dir') ?? _defaultOutputDir;
  final report = buildPlumbingCoreReadinessAudit();
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  final directory = Directory(outputDir)..createSync(recursive: true);
  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    ':',
    '',
  );
  final latest = File(
    '${directory.path}/latest_plumbing_core_readiness_audit.json',
  );
  final stamped = File(
    '${directory.path}/plumbing_core_readiness_audit_$timestamp.json',
  );

  latest.writeAsStringSync(encoded, flush: true);
  stamped.writeAsStringSync(encoded, flush: true);

  final summary = report['summary']! as Map<String, Object?>;
  stdout.writeln(
    'PLUMBING_CORE_READINESS_AUDIT '
    'core=${summary['coreRows']} '
    'releaseReady=${summary['releaseReadyItems']} '
    'metadataReady=${summary['metadataReadyCandidates']} '
    'needsWork=${summary['needsWorkItems']} '
    'critical=${summary['criticalItems']} '
    'report=${latest.path}',
  );
}

Map<String, Object?> buildPlumbingCoreReadinessAudit() {
  final coreRows =
      workSupplyCatalogItems
          .where(
            (item) =>
                item.trade == 'Plumbing' &&
                item.packTier == WorkSupplyPackTier.core &&
                item.marketScopes.contains(WorkSupplyMarketScope.residential),
          )
          .toList(growable: false)
        ..sort((left, right) => left.name.compareTo(right.name));
  final findings = [for (final item in coreRows) _readinessFinding(item)]
    ..sort(_findingSort);
  final families = [
    for (final family in _familyContracts)
      _familyReport(
        family,
        findings.where((finding) => finding.family == family.name),
      ),
  ];

  return {
    'schema': 'maintainiac.inventory.plumbing_core_readiness_audit.v1',
    'scope': 'Plumbing / Residential / Core',
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'releaseStandard':
        'An item is release-ready only after catalog metadata, English and '
        'Spanish parser terms, ambiguity negatives, and focused parser '
        'evidence are present. Metadata-ready is not release-ready.',
    'rules': {
      'noMutation': true,
      'broadGeneratedParserWavesAllowed': false,
      'finishClosestFamiliesFirst': true,
      'parserShardPrerequisite':
          'Run broad generated parser shards only after family readiness '
          'queues are closed or intentionally waived with a reason.',
    },
    'summary': _summary(findings),
    'familyReadiness': [for (final family in families) family.toJson()],
    'actionQueues': _actionQueues(findings),
    'items': [for (final finding in findings) finding.toJson()],
  };
}

_ReadinessFinding _readinessFinding(WorkSupplyItem item) {
  final text = item.searchableText.toLowerCase();
  final directText = _directText(item);
  final family = _classifyFamily(directText);
  final issues = <String>[];
  final warnings = <String>[];
  final identity = _identityCompleteness(item, directText);

  _require(item.aliases.length >= 4, issues, 'missing_alias_depth');
  _require(
    item.intelligence.receiptPatterns.length >= 8,
    issues,
    'missing_receipt_pattern_depth',
  );
  _require(
    item.intelligence.highImportanceTokens.length >= 4,
    issues,
    'missing_high_importance_tokens',
  );
  _require(
    item.intelligence.negativeMatchTokens.length >= 3,
    issues,
    'missing_negative_match_tokens',
  );
  _require(
    item.intelligence.attributeTokens.contains('plumbing-core'),
    issues,
    'missing_plumbing_core_attribute',
  );
  _require(
    item.intelligence.attributeTokens.contains('residential-service'),
    issues,
    'missing_residential_service_attribute',
  );
  _require(_hasSpanish(item), issues, 'missing_spanish_terms');
  _require(_hasClassification(item), issues, 'missing_classification');
  _require(_hasVersioning(item), issues, 'missing_catalog_or_parser_version');
  _require(
    item.intelligence.sourceConfidence.isNotEmpty,
    issues,
    'missing_source_confidence',
  );

  if (!identity.hasMaterial && _requiresMaterial(directText)) {
    warnings.add('missing_material_context');
  }
  if (!identity.hasSize && _requiresSize(directText)) {
    warnings.add('missing_size_context');
  }
  if (!identity.hasShape && _requiresShape(directText)) {
    warnings.add('missing_shape_context');
  }
  if (!identity.hasConnection && _requiresConnection(directText)) {
    warnings.add('missing_connection_context');
  }

  for (final risk in _ambiguityRisks(directText)) {
    if (!_hasNegativeForRisk(item, risk)) {
      issues.add('missing_${risk}_ambiguity_negative');
    }
  }
  if (_looksSpecialOrder(directText)) warnings.add('special_order_review');
  if (_looksLegacyWithoutRepairBridge(directText)) {
    warnings.add('legacy_material_review');
  }

  final parserEvidence = _parserEvidenceStatus(item, text, family);
  if (parserEvidence != 'focused_parser_evidence_present') {
    issues.add(parserEvidence);
  }

  final status = issues.isEmpty && warnings.isEmpty
      ? 'release_ready_candidate'
      : issues.isEmpty
      ? 'metadata_ready_needs_review'
      : 'needs_work';
  final severity = issues.any(_isCriticalIssue)
      ? 'critical'
      : issues.isNotEmpty
      ? 'major'
      : warnings.isNotEmpty
      ? 'review'
      : 'ready';

  return _ReadinessFinding(
    item: item,
    family: family,
    status: status,
    severity: severity,
    readinessPercent: _score(issues, warnings),
    issues: issues.toSet().toList(growable: false)..sort(),
    warnings: warnings.toSet().toList(growable: false)..sort(),
    nextAction: _nextAction(issues, warnings),
  );
}

void _require(bool condition, List<String> issues, String issue) {
  if (!condition) issues.add(issue);
}

bool _hasSpanish(WorkSupplyItem item) {
  final text = item.searchableText.toLowerCase();
  return text.contains('spanish') ||
      text.contains('es-us') ||
      _spanishTerms.any(text.contains);
}

bool _hasClassification(WorkSupplyItem item) {
  final classification = item.intelligence.classification;
  return classification.inventoryCategory.isNotEmpty &&
      classification.expenseCategory.isNotEmpty &&
      classification.jobMaterialCategory.isNotEmpty;
}

bool _hasVersioning(WorkSupplyItem item) {
  return item.intelligence.catalogVersion.isNotEmpty &&
      item.intelligence.parserVersion.isNotEmpty;
}

_IdentityCompleteness _identityCompleteness(WorkSupplyItem item, String text) {
  return _IdentityCompleteness(
    hasMaterial:
        item.intelligence.material.isNotEmpty || _materials.any(text.contains),
    hasSize: item.intelligence.size.isNotEmpty || _sizePattern.hasMatch(text),
    hasShape:
        item.intelligence.shapeOrStyle.isNotEmpty || _shapes.any(text.contains),
    hasConnection:
        item.intelligence.connectionType.isNotEmpty ||
        _connections.any(text.contains),
  );
}

bool _requiresSize(String text) {
  return _hasAny(text, [
    'adapter',
    'coupling',
    'fitting',
    'line',
    'pipe',
    'valve',
  ]);
}

bool _requiresMaterial(String text) {
  return _hasAny(text, [
    'adapter',
    'connector',
    'coupling',
    'fitting',
    'hose',
    'line',
    'pipe',
    'valve',
  ]);
}

bool _requiresShape(String text) {
  return _hasAny(text, [
    'adapter',
    'copper',
    'coupling',
    'cpvc',
    'fitting',
    'pex',
    'pvc',
  ]);
}

bool _requiresConnection(String text) {
  if (_isWaterTreatmentDirectText(text) && !_hasAny(text, ['line', 'valve'])) {
    return false;
  }
  return _hasAny(text, [
    'adapter',
    'copper',
    'cpvc',
    'connector',
    'pex',
    'push',
    'supply',
    'valve',
  ]);
}

List<String> _ambiguityRisks(String text) {
  final risks = <String>[];
  if (_hasAny(text, ['conduit', 'cpvc', 'pipe', 'pvc'])) {
    risks.add('electrical');
  }
  if (_hasAny(text, ['condensate', 'filter', 'gauge', 'pvc'])) {
    risks.add('hvac');
  }
  if (_hasAny(text, ['filter', 'salt', 'softener'])) {
    risks.add('general_hardware');
  }
  if (_hasAny(text, ['copper', 'gauge', 'valve'])) {
    risks.add('cross_trade');
  }
  return risks.toSet().toList(growable: false);
}

bool _hasNegativeForRisk(WorkSupplyItem item, String risk) {
  final negatives = item.intelligence.negativeMatchTokens
      .join(' ')
      .toLowerCase();
  return switch (risk) {
    'electrical' => _hasAny(negatives, ['conduit', 'electrical', 'wire']),
    'hvac' => _hasAny(negatives, ['air filter', 'condensate', 'hvac']),
    'general_hardware' => _hasAny(negatives, [
      'ice melt',
      'pool',
      'swimming pool',
      'table salt',
    ]),
    'cross_trade' => _hasAny(negatives, ['air filter', 'electrical', 'hvac']),
    _ => false,
  };
}

String _parserEvidenceStatus(WorkSupplyItem item, String text, String family) {
  if (_familiesWithFocusedParserEvidence.contains(family)) {
    return 'focused_parser_evidence_present';
  }
  if (_hasAny(text, [
    'angle stop',
    'pressure gauge',
    'push-fit ball valve',
    'supply line',
  ])) {
    return 'focused_parser_evidence_present';
  }
  return 'missing_focused_parser_evidence';
}

String _classifyFamily(String text) {
  for (final family in _familyContracts) {
    if (_hasAnySignal(text, family.signals)) return family.name;
  }
  return 'unclassified plumbing core';
}

_FamilyReadiness _familyReport(
  _FamilyContract family,
  Iterable<_ReadinessFinding> findings,
) {
  final rows = findings.toList(growable: false);
  return _FamilyReadiness(
    family: family.name,
    total: rows.length,
    releaseReady: rows
        .where((item) => item.status == 'release_ready_candidate')
        .length,
    metadataReady: rows.where((item) => item.status != 'needs_work').length,
    critical: rows.where((item) => item.severity == 'critical').length,
    topIssues: _topIssues(rows),
    nextAction: rows.isEmpty
        ? 'add_or_reclassify_core_family_items'
        : _familyNextAction(rows),
  );
}

Map<String, Object?> _summary(List<_ReadinessFinding> findings) {
  return {
    'coreRows': findings.length,
    'releaseReadyItems': findings
        .where((item) => item.status == 'release_ready_candidate')
        .length,
    'metadataReadyCandidates': findings
        .where((item) => item.status != 'needs_work')
        .length,
    'needsWorkItems': findings
        .where((item) => item.status == 'needs_work')
        .length,
    'criticalItems': findings
        .where((item) => item.severity == 'critical')
        .length,
    'readinessFloor': findings.isEmpty
        ? 0
        : findings.map((item) => item.readinessPercent).reduce(_min),
    'readinessAverage': findings.isEmpty
        ? 0
        : double.parse(
            (findings
                        .map((item) => item.readinessPercent)
                        .reduce((left, right) => left + right) /
                    findings.length)
                .toStringAsFixed(2),
          ),
    'readyForMacValidation': false,
    'reason':
        'Plumbing Core still needs item-level metadata and focused parser '
        'evidence before Mac validation or broad generated parser waves.',
  };
}

Map<String, Object?> _actionQueues(List<_ReadinessFinding> findings) {
  List<Map<String, Object?>> queue(bool Function(_ReadinessFinding item) test) {
    return [
      for (final finding in findings.where(test).take(100))
        {
          'id': finding.item.id,
          'name': finding.item.name,
          'family': finding.family,
          'readinessPercent': finding.readinessPercent,
          'nextAction': finding.nextAction,
          'issues': finding.issues,
          'warnings': finding.warnings,
        },
    ];
  }

  return {
    'finishFirst': queue(
      (item) =>
          item.status != 'release_ready_candidate' &&
          item.readinessPercent >= 85,
    ),
    'criticalMetadata': queue((item) => item.severity == 'critical'),
    'spanishTerms': queue(
      (item) => item.issues.contains('missing_spanish_terms'),
    ),
    'ambiguityNegatives': queue(
      (item) =>
          item.issues.any((issue) => issue.contains('ambiguity_negative')),
    ),
    'parserEvidence': queue(
      (item) => item.issues.contains('missing_focused_parser_evidence'),
    ),
    'manualReview': queue((item) => item.warnings.isNotEmpty),
  };
}

Map<String, int> _topIssues(List<_ReadinessFinding> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    for (final issue in [...row.issues, ...row.warnings]) {
      counts.update(issue, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  final entries = counts.entries.toList()
    ..sort((left, right) {
      final byCount = right.value.compareTo(left.value);
      return byCount == 0 ? left.key.compareTo(right.key) : byCount;
    });
  return Map.fromEntries(entries.take(8));
}

String _familyNextAction(List<_ReadinessFinding> rows) {
  final top = _topIssues(rows);
  final releaseReadyCount = rows
      .where((row) => row.status == 'release_ready_candidate')
      .length;
  if (releaseReadyCount == rows.length) return 'candidate_for_release_lock';
  if (top.isEmpty) return 'run_focused_family_parser_evidence';
  final issue = top.keys.first;
  if (issue == 'missing_focused_parser_evidence') {
    return 'add_focused_family_parser_fixtures';
  }
  if (issue.contains('ambiguity_negative')) {
    return 'add_family_ambiguity_negatives';
  }
  if (issue == 'missing_spanish_terms') return 'add_family_spanish_terms';
  return 'complete_family_metadata_contract';
}

bool _isCriticalIssue(String issue) {
  return issue == 'missing_alias_depth' ||
      issue == 'missing_receipt_pattern_depth' ||
      issue == 'missing_high_importance_tokens' ||
      issue == 'missing_negative_match_tokens' ||
      issue == 'missing_focused_parser_evidence';
}

int _score(List<String> issues, List<String> warnings) {
  var score = 100;
  for (final issue in issues.toSet()) {
    score -= _isCriticalIssue(issue) ? 12 : 7;
  }
  score -= warnings.toSet().length * 3;
  return score.clamp(0, 100);
}

bool _looksSpecialOrder(String text) {
  return _hasAny(text, ['commercial', 'industrial']) ||
      RegExp(r'(^|[^0-9/])(3|4|6)\s*(in|inch|")([^0-9]|$)').hasMatch(text);
}

bool _isWaterTreatmentDirectText(String text) {
  return _hasAny(text, [
    'filter cartridge',
    'reverse osmosis',
    'softener',
    'water filter',
    'water treatment',
  ]);
}

bool _looksLegacyWithoutRepairBridge(String text) {
  if (!_hasAny(text, ['black iron', 'cast iron', 'galvanized'])) return false;
  return !_hasAny(text, [
    'adapter',
    'fernco',
    'no hub',
    'repair',
    'transition',
  ]);
}

bool _hasAny(String text, Iterable<String> terms) => terms.any(text.contains);

bool _hasAnySignal(String text, Iterable<String> terms) {
  return terms.any((term) {
    if (term.contains(' ')) return text.contains(term);
    return RegExp(
      r'(^|[^a-z0-9])' + RegExp.escape(term) + r'([^a-z0-9]|$)',
    ).hasMatch(text);
  });
}

String _directText(WorkSupplyItem item) {
  return [
    item.id,
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    item.unit,
    ...item.aliases,
  ].join(' ').toLowerCase();
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

int _findingSort(_ReadinessFinding left, _ReadinessFinding right) {
  final severityOrder = {'critical': 0, 'major': 1, 'review': 2, 'ready': 3};
  final bySeverity = severityOrder[left.severity]!.compareTo(
    severityOrder[right.severity]!,
  );
  if (bySeverity != 0) return bySeverity;
  final byScore = left.readinessPercent.compareTo(right.readinessPercent);
  if (byScore != 0) return byScore;
  final byFamily = left.family.compareTo(right.family);
  if (byFamily != 0) return byFamily;
  return left.item.name.compareTo(right.item.name);
}

int _min(int left, int right) => left < right ? left : right;

const _familiesWithFocusedParserEvidence = {
  'angle stops and supply lines',
  'push-fit fittings and valves',
  'water treatment',
  'well pressure service',
};

const _familyContracts = [
  _FamilyContract('push-fit fittings and valves', [
    'push fit',
    'push to connect',
    'push-fit',
    'sharkbite',
  ]),
  _FamilyContract('pex fittings and valves', ['pex']),
  _FamilyContract('cpvc fittings and valves', ['cpvc']),
  _FamilyContract('pvc pressure fittings', ['pvc pressure', 'pvc schedule 40']),
  _FamilyContract('pvc dwv fittings and access', [
    'cleanout',
    'dwv',
    'pvc dwv',
  ]),
  _FamilyContract('copper fittings and valves', ['copper']),
  _FamilyContract('angle stops and supply lines', [
    'angle stop',
    'supply line',
    'supply stop',
  ]),
  _FamilyContract('toilet and faucet repair', [
    'aerator',
    'faucet',
    'fill valve',
    'flapper',
    'toilet',
    'wax ring',
  ]),
  _FamilyContract('tubular drains and traps', [
    'basket strainer',
    'p-trap',
    'slip joint',
    'tailpiece',
  ]),
  _FamilyContract('water heater service', ['water heater']),
  _FamilyContract('well pressure service', [
    'pitless',
    'pressure gauge',
    'pressure switch',
    'pressure tank',
    'well pump',
  ]),
  _FamilyContract('water treatment', [
    'filter cartridge',
    'salt pellet',
    'softener',
    'water filter',
  ]),
  _FamilyContract('service consumables and tools', [
    'basin wrench',
    'cement',
    'drain snake',
    'pipe cutter',
    'primer',
    'putty',
    'thread seal',
  ]),
  _FamilyContract('legacy repair bridges', [
    'fernco',
    'no hub',
    'shielded',
    'transition',
  ]),
];

const _materials = [
  'brass',
  'carbon',
  'copper',
  'cpvc',
  'crystal',
  'membrane',
  'plastic',
  'pex',
  'potassium',
  'pvc',
  'quartz',
  'resin',
  'rubber',
  'salt',
  'sediment',
  'stainless',
  'steel',
];

const _shapes = [
  'adapter',
  'bushing',
  'coupling',
  'elbow',
  'flange',
  'gauge',
  'line',
  'tee',
  'trap',
  'valve',
];

const _connections = [
  'clamp',
  'compression',
  'connector',
  'corrugated',
  'crimp',
  'female',
  'fip',
  'hose',
  'male',
  'od',
  'push',
  'slip',
  'solvent',
  'sweat',
  'thread',
];

const _spanishTerms = [
  'acople',
  'adaptador',
  'bomba',
  'codo',
  'cople',
  'filtro',
  'fregadero',
  'grifo',
  'inodoro',
  'llave',
  'manometro',
  'sal',
  'suavizador',
  'tee',
  'trampa',
  'valvula',
];

final _sizePattern = RegExp(
  r'\b\d+(/\d+)?\s*(cu ft|gal|gpd|hp|in|inch|lb|psi|w|")\b|\b\d+/\d+\b|\b\d+k\b',
);

class _IdentityCompleteness {
  const _IdentityCompleteness({
    required this.hasMaterial,
    required this.hasSize,
    required this.hasShape,
    required this.hasConnection,
  });

  final bool hasMaterial;
  final bool hasSize;
  final bool hasShape;
  final bool hasConnection;
}

class _FamilyContract {
  const _FamilyContract(this.name, this.signals);

  final String name;
  final List<String> signals;
}

class _FamilyReadiness {
  const _FamilyReadiness({
    required this.family,
    required this.total,
    required this.releaseReady,
    required this.metadataReady,
    required this.critical,
    required this.topIssues,
    required this.nextAction,
  });

  final String family;
  final int total;
  final int releaseReady;
  final int metadataReady;
  final int critical;
  final Map<String, int> topIssues;
  final String nextAction;

  Map<String, Object?> toJson() => {
    'family': family,
    'total': total,
    'releaseReady': releaseReady,
    'metadataReady': metadataReady,
    'critical': critical,
    'topIssues': topIssues,
    'nextAction': nextAction,
  };
}

class _ReadinessFinding {
  const _ReadinessFinding({
    required this.item,
    required this.family,
    required this.status,
    required this.severity,
    required this.readinessPercent,
    required this.issues,
    required this.warnings,
    required this.nextAction,
  });

  final WorkSupplyItem item;
  final String family;
  final String status;
  final String severity;
  final int readinessPercent;
  final List<String> issues;
  final List<String> warnings;
  final String nextAction;

  Map<String, Object?> toJson() => {
    'id': item.id,
    'name': item.name,
    'family': family,
    'status': status,
    'severity': severity,
    'readinessPercent': readinessPercent,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'variant': item.variant,
    'unit': item.unit,
    'aliases': item.aliases,
    'receiptPatterns': item.intelligence.receiptPatterns,
    'highImportanceTokens': item.intelligence.highImportanceTokens,
    'negativeMatchTokens': item.intelligence.negativeMatchTokens,
    'attributeTokens': item.intelligence.attributeTokens,
    'issues': issues,
    'warnings': warnings,
    'nextAction': nextAction,
  };
}

String _nextAction(List<String> issues, List<String> warnings) {
  if (issues.contains('missing_focused_parser_evidence')) {
    return 'add_focused_parser_fixture';
  }
  if (issues.any((issue) => issue.contains('ambiguity_negative'))) {
    return 'add_ambiguity_negative_tokens';
  }
  if (issues.contains('missing_spanish_terms')) return 'add_spanish_terms';
  if (issues.isNotEmpty) return 'complete_metadata_contract';
  if (warnings.isNotEmpty) return 'manual_review_then_lock';
  return 'candidate_for_release_lock';
}
