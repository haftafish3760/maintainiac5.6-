import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

const workSupplyLocalEvidenceSchema =
    'maintainiac_work_supply_parser_local_evidence_v1';
const _minimumCasesPerTrade = 100;
const _minimumAccuracy = .92;
const _pehTrades = {'plumbing', 'electrical', 'hvac'};
const _independentSourceTypes = {
  'anonymizedreal',
  'reviewedreal',
  'redactedreal',
};
const _reportExcludes = [
  'rawLine',
  'ocrText',
  'receiptImagePath',
  'sourceImageBytes',
  'cardNumber',
  'customerName',
  'streetAddress',
];

/// Scores a local-only, independently reviewed receipt-line corpus.
///
/// The corpus must live beneath `.external_datasets/` and is intentionally
/// ignored by Git. Its report contains identifiers and aggregate outcomes,
/// never receipt text or image locations.
Map<String, Object?> scoreWorkSupplyLocalEvidence(String configuredPath) {
  if (configuredPath.trim().isEmpty) {
    return _unavailable('corpus_path_not_configured');
  }
  final file = File(configuredPath);
  if (!file.existsSync()) return _unavailable('corpus_file_not_found');
  if (!_isLocalOnlyPath(file)) return _unavailable('corpus_outside_local_root');

  final decoded = _decodeCorpus(file);
  if (decoded is _InvalidCorpus) return _invalid(decoded.errors);
  final cases = decoded as List<Map<String, Object?>>;
  final invalid = <String>[];
  final outcomes = <_Outcome>[];
  for (final entry in cases) {
    final evidence = _EvidenceCase.fromJson(entry);
    final missing = evidence.validationErrors;
    if (missing.isNotEmpty) {
      invalid.add(
        '${evidence.id.isEmpty ? 'unknown' : evidence.id}:${missing.join(',')}',
      );
      continue;
    }
    final match = matchReceiptLineToCatalog(
      evidence.rawLine,
      tradeScope: evidence.tradeScope,
      localePackId: evidence.localePackId,
      maxCandidates: 24,
    );
    outcomes.add(_Outcome.fromMatch(evidence, match));
  }
  if (invalid.isNotEmpty) return _invalid(invalid);

  final byTrade = <String, Object?>{};
  final blockers = <String>[];
  for (final trade in _pehTrades) {
    final summary = _summary(
      outcomes.where((outcome) => outcome.trade == trade),
    );
    byTrade[trade] = summary;
    if ((summary['checked'] as int) < _minimumCasesPerTrade) {
      blockers.add('$trade:sample_size_below_$_minimumCasesPerTrade');
    }
    if ((summary['accuracy'] as double) < _minimumAccuracy) {
      blockers.add(
        '$trade:accuracy_below_${_minimumAccuracy.toStringAsFixed(2)}',
      );
    }
  }
  final sourceTypes = outcomes.map((outcome) => outcome.sourceType).toSet();
  if (!sourceTypes.every(_independentSourceTypes.contains)) {
    blockers.add('non_independent_source_type_present');
  }
  final eligible = blockers.isEmpty;
  return {
    'report': 'work_supply_parser_local_evidence_accuracy',
    'measurementStatus': 'measured',
    'schema': workSupplyLocalEvidenceSchema,
    'privacy': {'corpusLocalOnly': true, 'reportExcludes': _reportExcludes},
    'overall': _summary(outcomes),
    'byTrade': byTrade,
    'sourceTypes': sourceTypes.toList()..sort(),
    'releaseClaimThresholds': {
      'minimumCasesPerTrade': _minimumCasesPerTrade,
      'minimumAccuracyPerTrade': _minimumAccuracy,
      'requiresIndependentReviewedEvidence': true,
    },
    'releaseClaimEligible': eligible,
    'releaseClaimBlockers': blockers,
  };
}

String localEvidenceSummary(Map<String, Object?> report) =>
    'PARSER_LOCAL_EVIDENCE_ACCURACY ${jsonEncode(report)}';

Object _decodeCorpus(File file) {
  try {
    final root = jsonDecode(file.readAsStringSync());
    if (root is! Map) return _InvalidCorpus(['root_must_be_object']);
    if (root['schema'] != workSupplyLocalEvidenceSchema) {
      return _InvalidCorpus(['unsupported_schema']);
    }
    if (root['committedToGit'] != false || root['localOnly'] != true) {
      return _InvalidCorpus(['local_only_policy_missing']);
    }
    if (root['reportExcludes'] is! List ||
        !_reportExcludes.every(
          (field) => (root['reportExcludes'] as List).contains(field),
        )) {
      return _InvalidCorpus(['privacy_exclusions_missing']);
    }
    final cases = root['cases'];
    if (cases is! List || cases.isEmpty)
      return _InvalidCorpus(['cases_missing']);
    final entries = <Map<String, Object?>>[];
    for (final entry in cases) {
      if (entry is! Map) return _InvalidCorpus(['case_must_be_object']);
      entries.add(entry.cast<String, Object?>());
    }
    return entries;
  } on FormatException {
    return _InvalidCorpus(['invalid_json']);
  }
}

bool _isLocalOnlyPath(File file) {
  final root = Directory('.external_datasets').absolute.path;
  final path = file.absolute.path;
  return path == root || path.startsWith('$root${Platform.pathSeparator}');
}

Map<String, Object?> _unavailable(String reason) => {
  'report': 'work_supply_parser_local_evidence_accuracy',
  'measurementStatus': 'unavailable',
  'reason': reason,
  'releaseClaimEligible': false,
  'releaseClaimBlockers': ['independent_local_corpus_not_measured'],
};

Map<String, Object?> _invalid(List<String> errors) => {
  'report': 'work_supply_parser_local_evidence_accuracy',
  'measurementStatus': 'invalid_corpus',
  'errors': errors,
  'releaseClaimEligible': false,
  'releaseClaimBlockers': ['invalid_local_corpus'],
};

class _InvalidCorpus {
  const _InvalidCorpus(this.errors);
  final List<String> errors;
}

class _EvidenceCase {
  const _EvidenceCase({
    required this.id,
    required this.rawLine,
    required this.trade,
    required this.expectedStatus,
    required this.expectedCandidateId,
    required this.tradeScope,
    required this.localePackId,
    required this.sourceType,
    required this.reviewStatus,
  });

  final String id;
  final String rawLine;
  final String trade;
  final String expectedStatus;
  final String expectedCandidateId;
  final String? tradeScope;
  final String localePackId;
  final String sourceType;
  final String reviewStatus;

  factory _EvidenceCase.fromJson(Map<String, Object?> json) => _EvidenceCase(
    id: json['id'] as String? ?? '',
    rawLine: json['rawLine'] as String? ?? '',
    trade: (json['trade'] as String? ?? '').toLowerCase(),
    expectedStatus: (json['expectedStatus'] as String? ?? '').toLowerCase(),
    expectedCandidateId: json['expectedCandidateId'] as String? ?? '',
    tradeScope: json['tradeScope'] as String?,
    localePackId: json['localePackId'] as String? ?? 'en-US',
    sourceType: (json['sourceType'] as String? ?? '').toLowerCase(),
    reviewStatus: (json['reviewStatus'] as String? ?? '').toLowerCase(),
  );

  List<String> get validationErrors => [
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) 'opaque_id_required',
    if (rawLine.trim().isEmpty) 'raw_line_required',
    if (!_pehTrades.contains(trade)) 'peh_trade_required',
    if (!{'matched', 'needsreview', 'unknown'}.contains(expectedStatus))
      'expected_status_invalid',
    if (expectedStatus == 'matched' && expectedCandidateId.trim().isEmpty)
      'expected_candidate_required',
    if (!_independentSourceTypes.contains(sourceType))
      'independent_source_required',
    if (reviewStatus != 'reviewed') 'reviewed_label_required',
  ];
}

class _Outcome {
  const _Outcome({
    required this.id,
    required this.trade,
    required this.sourceType,
    required this.correct,
    required this.reason,
  });
  final String id;
  final String trade;
  final String sourceType;
  final bool correct;
  final String reason;

  factory _Outcome.fromMatch(_EvidenceCase evidence, ReceiptLineMatch? match) {
    if (evidence.expectedStatus == 'unknown') {
      return _Outcome(
        id: evidence.id,
        trade: evidence.trade,
        sourceType: evidence.sourceType,
        correct: match == null,
        reason: match == null ? 'correct_unknown' : 'false_positive',
      );
    }
    if (evidence.expectedStatus == 'needsreview') {
      return _Outcome(
        id: evidence.id,
        trade: evidence.trade,
        sourceType: evidence.sourceType,
        correct: match == null || match.needsReview,
        reason: match == null ? 'safe_no_match' : 'review_required',
      );
    }
    final actual = match == null
        ? ''
        : '${match.item.id} ${match.item.name} ${match.item.searchableText}';
    final correct =
        match != null &&
        _semanticIdMatches(evidence.expectedCandidateId, actual);
    return _Outcome(
      id: evidence.id,
      trade: evidence.trade,
      sourceType: evidence.sourceType,
      correct: correct,
      reason: correct
          ? 'correct_match'
          : match == null
          ? 'missing_match'
          : 'wrong_candidate_family',
    );
  }
}

Map<String, Object?> _summary(Iterable<_Outcome> selected) {
  final values = selected.toList();
  final correct = values.where((outcome) => outcome.correct).length;
  final total = values.length;
  return {
    'checked': total,
    'correct': correct,
    'accuracy': total == 0 ? 0.0 : correct / total,
    'failureReasons': _countBy(
      values.where((outcome) => !outcome.correct),
      (outcome) => outcome.reason,
    ),
    'failures': [
      for (final outcome in values)
        if (!outcome.correct) {'id': outcome.id, 'reason': outcome.reason},
    ],
  };
}

Map<String, int> _countBy<T>(Iterable<T> values, String Function(T) keyOf) {
  final counts = <String, int>{};
  for (final value in values) {
    counts.update(keyOf(value), (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

bool _semanticIdMatches(String expected, String actual) {
  final expectedTokens = _normalized(
    expected,
  ).split(' ').where((token) => token.length >= 3).toSet();
  final actualTokens = _normalized(actual).split(' ').toSet();
  return expectedTokens.isNotEmpty &&
      expectedTokens.every(actualTokens.contains);
}

String _normalized(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');
