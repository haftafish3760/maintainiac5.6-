import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

const _defaultOutputDir = 'build/parser_qa_curation/electrical_core';

void main(List<String> args) {
  final outputDir = _argValue(args, '--output-dir') ?? _defaultOutputDir;
  final report = buildElectricalCoreReadinessAudit();
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  final directory = Directory(outputDir)..createSync(recursive: true);
  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    ':',
    '',
  );
  final latest = File(
    '${directory.path}/latest_electrical_core_readiness_audit.json',
  );
  final stamped = File(
    '${directory.path}/electrical_core_readiness_audit_$timestamp.json',
  );

  latest.writeAsStringSync(encoded, flush: true);
  stamped.writeAsStringSync(encoded, flush: true);

  final summary = report['summary']! as Map<String, Object?>;
  stdout.writeln(
    'ELECTRICAL_CORE_READINESS_AUDIT '
    'core=${summary['coreRows']} '
    'releaseReady=${summary['releaseReadyItems']} '
    'metadataReady=${summary['metadataReadyCandidates']} '
    'needsWork=${summary['needsWorkItems']} '
    'critical=${summary['criticalItems']} '
    'report=${latest.path}',
  );
}

Map<String, Object?> buildElectricalCoreReadinessAudit() {
  final coreRows =
      workSupplyCatalogItems
          .where(
            (item) =>
                item.trade == 'Electrical' &&
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
    'schema': 'maintainiac.inventory.electrical_core_readiness_audit.v1',
    'scope': 'Electrical / Residential / Core',
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'releaseStandard':
        'An Electrical Core item is release-ready only after catalog metadata, '
        'English and Spanish parser terms, ambiguity negatives, and focused '
        'parser evidence are present.',
    'rules': {
      'noMutation': true,
      'broadGeneratedParserWavesAllowed': false,
      'finishFamilyStructureFirst': true,
    },
    'summary': _summary(findings),
    'familyReadiness': [for (final family in families) family.toJson()],
    'actionQueues': _actionQueues(findings),
    'items': [for (final finding in findings) finding.toJson()],
  };
}

_ReadinessFinding _readinessFinding(WorkSupplyItem item) {
  final directText = _directText(item);
  final searchable = item.searchableText.toLowerCase();
  final family = _classifyFamily(_familyText(item));
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
    item.intelligence.attributeTokens.contains('electrical-core'),
    issues,
    'missing_electrical_core_attribute',
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

  if (!identity.hasSize && _requiresSize(directText, family)) {
    warnings.add('missing_size_context');
  }
  if (!identity.hasElectricalIdentity && _requiresElectricalIdentity(family)) {
    warnings.add('missing_electrical_identity_context');
  }
  for (final risk in _ambiguityRisks(directText)) {
    if (!_hasNegativeForRisk(item, risk)) {
      issues.add('missing_${risk}_ambiguity_negative');
    }
  }

  final parserEvidence = _parserEvidenceStatus(searchable, family);
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
    hasSize: item.intelligence.size.isNotEmpty || _sizePattern.hasMatch(text),
    hasElectricalIdentity:
        item.intelligence.material.isNotEmpty ||
        item.intelligence.connectionType.isNotEmpty ||
        item.intelligence.shapeOrStyle.isNotEmpty ||
        _identityTerms.any(text.contains),
  );
}

bool _requiresSize(String text, String family) {
  if (_hasAny(text, _naturallyUnsizedElectricalSignals)) return false;
  if (family == 'wire and cable') return true;
  if (family == 'conduit and fittings') return true;
  if (family == 'breakers and panels') {
    return _hasAny(text, ['breaker', 'disconnect', 'load center', 'panel']);
  }
  if (family == 'boxes and covers') {
    return _hasAny(text, ['box', 'mud ring', 'extension ring']);
  }
  if (family == 'grounding and bonding') {
    return _hasAny(text, ['ground rod', 'ground clamp', 'lug']);
  }
  return false;
}

bool _requiresElectricalIdentity(String family) {
  return family != 'electrical consumables';
}

List<String> _ambiguityRisks(String text) {
  final risks = <String>[];
  if (_hasAny(text, ['conduit', 'pvc'])) risks.add('plumbing');
  if (_hasAny(text, ['low voltage', 'thermostat', 'transformer'])) {
    risks.add('hvac');
  }
  if (_hasAny(text, ['box', 'plate', 'cover', 'strap'])) {
    risks.add('general_hardware');
  }
  if (_hasAny(text, ['copper', 'connector', 'wire'])) {
    risks.add('cross_trade');
  }
  return risks.toSet().toList(growable: false);
}

bool _hasNegativeForRisk(WorkSupplyItem item, String risk) {
  final negatives = item.intelligence.negativeMatchTokens
      .join(' ')
      .toLowerCase();
  return switch (risk) {
    'plumbing' => _hasAny(negatives, ['plumbing', 'pipe', 'water']),
    'hvac' => _hasAny(negatives, ['air filter', 'condensate', 'hvac']),
    'general_hardware' => _hasAny(negatives, ['cabinet', 'drywall', 'paint']),
    'cross_trade' => _hasAny(negatives, ['hvac', 'plumbing', 'low voltage']),
    _ => false,
  };
}

String _parserEvidenceStatus(String text, String family) {
  if (_familiesWithFocusedParserEvidence.contains(family)) {
    return 'focused_parser_evidence_present';
  }
  if (_hasAny(text, ['gfci', 'breaker', 'emt connector', 'nm-b'])) {
    return 'focused_parser_evidence_present';
  }
  return 'missing_focused_parser_evidence';
}

String _classifyFamily(String text) {
  for (final family in _familyContracts) {
    if (_hasAnySignal(text, family.signals)) return family.name;
  }
  return 'unclassified electrical core';
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
  final releaseReadyCount = findings
      .where((item) => item.status == 'release_ready_candidate')
      .length;
  final metadataReadyCount = findings
      .where((item) => item.status != 'needs_work')
      .length;
  final needsWorkCount = findings
      .where((item) => item.status == 'needs_work')
      .length;
  final criticalCount = findings
      .where((item) => item.severity == 'critical')
      .length;
  final readyForMacValidation =
      findings.isNotEmpty &&
      releaseReadyCount == findings.length &&
      metadataReadyCount == findings.length &&
      needsWorkCount == 0 &&
      criticalCount == 0;

  return {
    'coreRows': findings.length,
    'releaseReadyItems': releaseReadyCount,
    'metadataReadyCandidates': metadataReadyCount,
    'needsWorkItems': needsWorkCount,
    'criticalItems': criticalCount,
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
    'readyForMacValidation': readyForMacValidation,
    'reason': readyForMacValidation
        ? 'Electrical Core item metadata and focused parser evidence are clean '
              'on the Windows deterministic readiness gate. Proceed to Mac '
              'validation before final release signoff.'
        : 'Electrical Core still needs item-level metadata, family taxonomy, '
              'and focused parser evidence before Mac validation or broad '
              'generated parser waves.',
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
      issue == 'missing_electrical_core_attribute' ||
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

String _familyText(WorkSupplyItem item) {
  return [
    item.id,
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.variant,
    item.unit,
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

const _familiesWithFocusedParserEvidence = <String>{
  // Existing focused parser suites cover these families in:
  // - test/work_supply_electrical_receipt_parser_test.dart
  // - test/work_supply_priority_trade_merchant_receipt_parser_test.dart
  // - test/work_supply_priority_trades_spanish_receipt_parser_test.dart
  // Keep this list honest: add a family only after executable parser tests
  // prove representative receipt behavior for that family.
  'wire and cable',
  'boxes and covers',
  'devices and controls',
  'breakers and panels',
  'conduit and fittings',
  'connectors and consumables',
  'grounding and bonding',
  'lighting alarms and low voltage',
  'service equipment and disconnects',
};

const _familyContracts = [
  _FamilyContract('wire and cable', [
    'cable',
    'nm-b',
    'nmb',
    'romex',
    'ser',
    'seu',
    'thhn',
    'thwn',
    'uf-b',
    'wire',
  ]),
  _FamilyContract('boxes and covers', [
    'box',
    'cover',
    'mud ring',
    'old work',
    'wall plate',
    'weatherproof',
  ]),
  _FamilyContract('devices and controls', [
    'contactor',
    'dimmer',
    'fan speed control',
    'gfci',
    'outlet',
    'photocell',
    'receptacle',
    'relay',
    'smart control',
    'switch',
    'time clock',
    'timer',
  ]),
  _FamilyContract('service equipment and disconnects', [
    'ac disconnect',
    'dead front',
    'disconnect',
    'ground bar',
    'neutral bar',
    'panel cover',
    'pullout',
    'safety switch',
    'service entrance',
    'surge',
  ]),
  _FamilyContract('breakers and panels', [
    'afci',
    'breaker',
    'circuit breaker',
    'dual function',
    'load center',
    'panel',
  ]),
  _FamilyContract('conduit and fittings', [
    'conduit',
    'emt',
    'flex',
    'fitting',
    'locknut',
    'raceway',
    'rigid',
  ]),
  _FamilyContract('connectors and consumables', [
    'anti short',
    'butt splice',
    'connector',
    'electrical tape',
    'lever connector',
    'staple',
    'wire nut',
  ]),
  _FamilyContract('grounding and bonding', [
    'bonding',
    'ground',
    'grounding',
    'lug',
    'pigtail',
  ]),
  _FamilyContract('lighting alarms and low voltage', [
    'alarm',
    'chime',
    'doorbell',
    'fixture',
    'lampholder',
    'lighting',
    'low voltage',
    'smoke',
    'transformer',
  ]),
];

const _spanishTerms = [
  'alarma',
  'apagador',
  'caja',
  'cable',
  'cinta',
  'conector',
  'conducto',
  'disyuntor',
  'enchufe',
  'interruptor',
  'placa',
  'tierra',
  'tomacorriente',
];

const _identityTerms = [
  'afci',
  'awg',
  'box',
  'breaker',
  'cable',
  'connector',
  'conduit',
  'duplex',
  'emt',
  'gfci',
  'ground',
  'nm-b',
  'receptacle',
  'switch',
  'thhn',
  'wire',
];

const _naturallyUnsizedElectricalSignals = [
  'anti short',
  'blank cover',
  'bonding jumper',
  'breaker filler',
  'cable staples',
  'circuit directory',
  'cover plate',
  'device cover',
  'dimmer',
  'doorbell chime',
  'electrical tape',
  'fixture chain',
  'fixture strap',
  'ground screw',
  'grounding pigtail',
  'keyless lampholder',
  'lampholder',
  'lockout',
  'nm cable connector pack',
  'occupancy sensor',
  'panel directory',
  'panel filler',
  'panel screw',
  'smoke alarm',
  'surge protector',
  'switch',
  'wall plate',
  'weatherproof lampholder',
  'wire nut',
];

final _sizePattern = RegExp(
  r'\b\d+(/\d+)?\s*(a|amp|awg|ft|gang|in|inch|v|volt|w|")\b|\b\d+/\d+\b|\b\d+[-/]\d+\b',
);

class _IdentityCompleteness {
  const _IdentityCompleteness({
    required this.hasSize,
    required this.hasElectricalIdentity,
  });

  final bool hasSize;
  final bool hasElectricalIdentity;
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
