import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

const _defaultOutputDir = 'build/parser_qa_curation/hvac_core';

void main(List<String> args) {
  final outputDir = _argValue(args, '--output-dir') ?? _defaultOutputDir;
  final report = buildHvacCoreReadinessAudit();
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  final directory = Directory(outputDir)..createSync(recursive: true);
  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    ':',
    '',
  );
  final latest = File(
    '${directory.path}/latest_hvac_core_readiness_audit.json',
  );
  final stamped = File(
    '${directory.path}/hvac_core_readiness_audit_$timestamp.json',
  );

  latest.writeAsStringSync(encoded, flush: true);
  stamped.writeAsStringSync(encoded, flush: true);

  final summary = report['summary']! as Map<String, Object?>;
  stdout.writeln(
    'HVAC_CORE_READINESS_AUDIT '
    'core=${summary['coreRows']} '
    'releaseReady=${summary['releaseReadyItems']} '
    'metadataReady=${summary['metadataReadyCandidates']} '
    'needsWork=${summary['needsWorkItems']} '
    'critical=${summary['criticalItems']} '
    'report=${latest.path}',
  );
}

Map<String, Object?> buildHvacCoreReadinessAudit() {
  final coreRows =
      workSupplyCatalogItems
          .where(
            (item) =>
                item.trade == 'HVAC' &&
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
    'schema': 'maintainiac.inventory.hvac_core_readiness_audit.v1',
    'scope': 'HVAC / Residential / Core',
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'releaseStandard':
        'An HVAC Core item is release-ready only after catalog metadata, '
        'English and Spanish parser terms, ambiguity negatives, and focused '
        'chaotic receipt parser evidence are present.',
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
  final text = item.searchableText.toLowerCase();
  final family = _classifyFamily(text);
  final issues = <String>[];
  final warnings = <String>[];

  _require(item.aliases.length >= 3, issues, 'missing_alias_depth');
  _require(
    item.intelligence.receiptPatterns.length >= 6,
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
    item.intelligence.attributeTokens.contains('hvac-core'),
    issues,
    'missing_hvac_core_attribute',
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

  if (!_hasFamilyIdentity(text, family)) {
    warnings.add('missing_family_identity');
  }
  final parserEvidence = _parserEvidenceStatus(text, family);
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

bool _hasFamilyIdentity(String text, String family) {
  return switch (family) {
    'air filters' => _hasAny(text, ['filter', 'merv', 'furnace']),
    'controls and electrical' => _hasAny(text, [
      'capacitor',
      'contactor',
      'thermostat',
      'relay',
      'fuse',
      'transformer',
    ]),
    'condensate' => _hasAny(text, ['condensate', 'drain', 'pump']),
    'tape sealants and duct repair' => _hasAny(text, [
      'tape',
      'mastic',
      'duct',
      'seal',
      'flex',
    ]),
    'ignition and gas heat' => _hasAny(text, [
      'ignitor',
      'flame',
      'gas',
      'sensor',
    ]),
    'motors and blower parts' => _hasAny(text, ['motor', 'blower', 'belt']),
    _ => true,
  };
}

String _parserEvidenceStatus(String text, String family) {
  final terms = _parserEvidenceTerms[family] ?? const <String>[];
  if (terms.any(text.contains)) return 'focused_parser_evidence_present';
  return 'missing_${_safe(family)}_parser_evidence';
}

Map<String, Object?> _summary(List<_ReadinessFinding> findings) {
  final releaseReady = findings
      .where((finding) => finding.status == 'release_ready_candidate')
      .length;
  final metadataReady = findings
      .where((finding) => finding.status != 'needs_work')
      .length;
  final critical = findings
      .where((finding) => finding.severity == 'critical')
      .length;
  return {
    'coreRows': findings.length,
    'releaseReadyItems': releaseReady,
    'metadataReadyCandidates': metadataReady,
    'needsWorkItems': findings.length - metadataReady,
    'criticalItems': critical,
    'readyForMacValidation': releaseReady == findings.length && critical == 0,
  };
}

Map<String, Object?> _actionQueues(List<_ReadinessFinding> findings) {
  List<Map<String, Object?>> rows(bool Function(_ReadinessFinding) test) {
    return findings
        .where(test)
        .take(25)
        .map((finding) => finding.queueJson())
        .toList(growable: false);
  }

  return {
    'finishFirst': rows((finding) => finding.status == 'needs_work'),
    'criticalMetadata': rows((finding) => finding.severity == 'critical'),
    'parserEvidence': rows(
      (finding) => finding.issues.any((issue) => issue.contains('evidence')),
    ),
  };
}

_FamilyReport _familyReport(
  _FamilyContract contract,
  Iterable<_ReadinessFinding> rows,
) {
  final list = rows.toList(growable: false);
  final ready = list
      .where((finding) => finding.status == 'release_ready_candidate')
      .length;
  final critical = list
      .where((finding) => finding.severity == 'critical')
      .length;
  return _FamilyReport(
    family: contract.name,
    required: contract.required,
    itemCount: list.length,
    releaseReady: ready,
    critical: critical,
    status: list.isEmpty
        ? 'missing_family_items'
        : ready == list.length && critical == 0
        ? 'ready'
        : 'needs_work',
  );
}

String _classifyFamily(String text) {
  for (final entry in _familyTerms.entries) {
    if (entry.value.any(text.contains)) return entry.key;
  }
  return 'other hvac core';
}

int _findingSort(_ReadinessFinding left, _ReadinessFinding right) {
  final severity = _severityRank(
    left.severity,
  ).compareTo(_severityRank(right.severity));
  if (severity != 0) return severity;
  return left.item.name.compareTo(right.item.name);
}

int _severityRank(String severity) {
  return switch (severity) {
    'critical' => 0,
    'major' => 1,
    'review' => 2,
    _ => 3,
  };
}

bool _isCriticalIssue(String issue) {
  return issue.contains('attribute') ||
      issue.contains('classification') ||
      issue.contains('version') ||
      issue.contains('evidence');
}

int _score(List<String> issues, List<String> warnings) {
  final score = 100 - (issues.length * 12) - (warnings.length * 4);
  if (score < 0) return 0;
  if (score > 100) return 100;
  return score;
}

String _nextAction(List<String> issues, List<String> warnings) {
  if (issues.isEmpty && warnings.isEmpty) return 'ready';
  if (issues.any((issue) => issue.contains('attribute'))) {
    return 'add HVAC Core metadata attribute tokens';
  }
  if (issues.any((issue) => issue.contains('evidence'))) {
    return 'add focused chaotic receipt parser evidence';
  }
  if (issues.any((issue) => issue.contains('receipt'))) {
    return 'add merchant-style receipt patterns';
  }
  if (warnings.isNotEmpty) return 'review item family identity';
  return 'complete HVAC Core metadata';
}

String _safe(String value) => value.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

bool _hasAny(String text, Iterable<String> terms) => terms.any(text.contains);

const _spanishTerms = [
  'filtro',
  'termostato',
  'bomba',
  'condensado',
  'cinta',
  'conducto',
];

const _familyContracts = [
  _FamilyContract('air filters', true),
  _FamilyContract('controls and electrical', true),
  _FamilyContract('condensate', true),
  _FamilyContract('tape sealants and duct repair', true),
  _FamilyContract('ignition and gas heat', true),
  _FamilyContract('motors and blower parts', false),
];

const _familyTerms = {
  'air filters': ['air filter', 'furnace filter', 'merv filter', 'pleated'],
  'controls and electrical': [
    'capacitor',
    'contactor',
    'thermostat',
    'relay',
    'transformer',
    'fuse',
    'hard start',
  ],
  'condensate': ['condensate', 'drain tab', 'float switch'],
  'tape sealants and duct repair': [
    'foil tape',
    'duct mastic',
    'flex duct',
    'start collar',
    'sheet metal screw',
  ],
  'ignition and gas heat': ['ignitor', 'flame sensor', 'gas valve'],
  'motors and blower parts': ['motor', 'blower', 'belt'],
};

const _parserEvidenceTerms = {
  'air filters': ['merv', 'filter', 'filt'],
  'controls and electrical': [
    'capacitor',
    'contactor',
    'thermostat',
    'tstat',
    'relay',
    'fuse',
    'transformer',
  ],
  'condensate': ['condensate', 'cond ', 'float switch', 'drain tab'],
  'tape sealants and duct repair': [
    'foil',
    'ul181',
    'mastic',
    'flex duct',
    'takeoff',
    'zip screw',
  ],
  'ignition and gas heat': ['flame sensor', 'ignitor', 'hsi'],
  'motors and blower parts': ['motor', 'blower', 'belt'],
};

class _FamilyContract {
  const _FamilyContract(this.name, this.required);

  final String name;
  final bool required;
}

class _FamilyReport {
  const _FamilyReport({
    required this.family,
    required this.required,
    required this.itemCount,
    required this.releaseReady,
    required this.critical,
    required this.status,
  });

  final String family;
  final bool required;
  final int itemCount;
  final int releaseReady;
  final int critical;
  final String status;

  Map<String, Object?> toJson() => {
    'family': family,
    'required': required,
    'itemCount': itemCount,
    'releaseReady': releaseReady,
    'critical': critical,
    'status': status,
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
    'path': item.path,
    'status': status,
    'severity': severity,
    'readinessPercent': readinessPercent,
    'issues': issues,
    'warnings': warnings,
    'nextAction': nextAction,
  };

  Map<String, Object?> queueJson() => {
    'id': item.id,
    'name': item.name,
    'family': family,
    'severity': severity,
    'issues': issues,
    'nextAction': nextAction,
  };
}
