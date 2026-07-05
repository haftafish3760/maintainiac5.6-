import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../screens/expenses/data/expense_export_models.dart';
import '../../screens/expenses/data/expense_receipt_item_memory_store.dart';
import '../../screens/expenses/data/expense_receipt_privacy_event_store.dart';
import '../../screens/expenses/data/expense_screen_telemetry.dart';
import '../../screens/work_supplies/data/work_supply_catalog_health_event.dart';
import '../../screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';
import 'maintainiac_firestore_schema.dart';

class MaintainiacFirestoreDocumentDraft {
  const MaintainiacFirestoreDocumentDraft({
    required this.path,
    required this.data,
  });

  final String path;
  final Map<String, Object?> data;
}

class MaintainiacFirestoreDocumentBuilder {
  const MaintainiacFirestoreDocumentBuilder._();

  static const parserHealthDocumentId = 'receipt_parser_v1';
  static const _schemaCatalogPack = 'catalog_pack_v1';
  static const _schemaCatalogManifest = 'catalog_pack_manifest_v1';
  static const _schemaCatalogHealth = 'catalog_health_event_v1';
  static const _schemaReceiptDiagnostic = 'receipt_diagnostic_event_v1';
  static const _schemaParserHealth = 'parser_health_snapshot_v1';
  static const _schemaExpenseTelemetrySummary = 'expense_telemetry_summary_v1';
  static const _schemaCorrectionCandidate = 'shared_correction_candidate_v1';

  static MaintainiacFirestoreDocumentDraft catalogPackDocument(
    WorkSupplyHostedCatalogManifest manifest,
  ) {
    return MaintainiacFirestoreDocumentDraft(
      path: MaintainiacFirestoreSchema.catalogPackDocumentPath(manifest.packId),
      data: Map.unmodifiable({
        'schema': _schemaCatalogPack,
        'packId': _safePathToken(manifest.packId),
        'latestVersion': _safePathToken(manifest.packVersion),
        'deliveryMode': 'manifest_storage_chunks',
        'storagePrefix': _safeStoragePath(manifest.storagePrefix),
        'itemCount': manifest.itemCount,
        'tradeCount': manifest.tradeCount,
        'chunkCount': manifest.chunkCount,
        'estimatedCompressedBytes': manifest.estimatedCompressedBytes,
        'firestoreManifestReadCount': manifest.firestoreManifestReadCount,
        'firestoreItemDocumentReadCount':
            manifest.firestoreItemDocumentReadCount,
        'updatedAtUtc': _safeIso(manifest.generatedAtIso),
      }),
    );
  }

  static MaintainiacFirestoreDocumentDraft catalogManifestDocument(
    WorkSupplyHostedCatalogManifest manifest,
  ) {
    return MaintainiacFirestoreDocumentDraft(
      path: MaintainiacFirestoreSchema.catalogPackManifestDocumentPath(
        manifest.packId,
        manifest.packVersion,
      ),
      data: Map.unmodifiable({
        'schema': _schemaCatalogManifest,
        ...manifest.toMap(),
      }),
    );
  }

  static MaintainiacFirestoreDocumentDraft catalogHealthDocument(
    WorkSupplyCatalogHealthEvent event, {
    DateTime? generatedAtUtc,
  }) {
    final generatedAt = (generatedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final data = _sanitizeCatalogHealth(event.toMap());
    final id = [
      data['packId'],
      data['packVersion'],
      generatedAt.microsecondsSinceEpoch,
    ].map((part) => _safePathToken(part.toString())).join('_');
    return MaintainiacFirestoreDocumentDraft(
      path: '${MaintainiacFirestoreSchema.catalogHealth}/$id',
      data: Map.unmodifiable({
        'schema': _schemaCatalogHealth,
        'generatedAtUtc': generatedAt.toIso8601String(),
        ...data,
      }),
    );
  }

  static MaintainiacFirestoreDocumentDraft receiptDiagnosticDocument({
    required String orgId,
    required PrivacySafeReceiptEventRecord record,
  }) {
    final eventId = _safePathToken(record.id);
    return MaintainiacFirestoreDocumentDraft(
      path:
          '${MaintainiacFirestoreSchema.orgCollectionPath(orgId, MaintainiacFirestoreSchema.orgReceiptDiagnostics)}/$eventId',
      data: Map.unmodifiable({
        'schema': _schemaReceiptDiagnostic,
        'eventId': eventId,
        'queuedAtUtc': record.queuedAtUtc.toUtc().toIso8601String(),
        if (record.uploadedAtUtc != null)
          'uploadedAtUtc': record.uploadedAtUtc!.toUtc().toIso8601String(),
        'payload': ReceiptPrivacyEventPolicy.sanitizeMap(record.payload),
      }),
    );
  }

  static MaintainiacFirestoreDocumentDraft parserHealthDocument(
    ReceiptPrivacyEventHealthSnapshot snapshot,
  ) {
    return MaintainiacFirestoreDocumentDraft(
      path:
          '${MaintainiacFirestoreSchema.parserHealth}/$parserHealthDocumentId',
      data: Map.unmodifiable({
        ...snapshot.toCommandCenterMap(),
        'schema': _schemaParserHealth,
      }),
    );
  }

  static MaintainiacFirestoreDocumentDraft expenseTelemetrySummaryDocument({
    required String orgId,
    required ExpenseTelemetryHealthSnapshot snapshot,
    String summaryId = 'latest',
    int maxFailureBreakdowns = 20,
    int maxRecentFailureDetails = 50,
    Map<String, Object?>? commandCenterOcrContract,
  }) {
    final cappedFailures = snapshot.failureBreakdowns
        .take(maxFailureBreakdowns.clamp(0, 50).toInt())
        .map((failure) => _sanitizeExpenseTelemetryMap(failure.toMap()))
        .toList(growable: false);
    final cappedRecentFailures = snapshot.recentFailureDetails
        .take(maxRecentFailureDetails.clamp(0, 100).toInt())
        .map((failure) => _sanitizeExpenseTelemetryMap(failure.toMap()))
        .toList(growable: false);
    final summary = _sanitizeExpenseTelemetryMap(snapshot.toCommandCenterMap());
    final safeOcrContract = commandCenterOcrContract == null
        ? null
        : _sanitizeCommandCenterOcrContract(commandCenterOcrContract);
    return MaintainiacFirestoreDocumentDraft(
      path:
          '${MaintainiacFirestoreSchema.orgCollectionPath(_safePathToken(orgId), MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries)}/${_safePathToken(summaryId)}',
      data: Map.unmodifiable({
        ...summary,
        'schema': _schemaExpenseTelemetrySummary,
        'summaryId': _safePathToken(summaryId),
        'summaryScope': 'expense_screen',
        'uploadShape': 'single_summary_document',
        'rawEventUploadCount': 0,
        'failureBreakdowns': cappedFailures,
        'recentFailureDetails': cappedRecentFailures,
        // ignore: use_null_aware_elements
        if (safeOcrContract != null)
          'commandCenterOcrContract': safeOcrContract,
      }),
    );
  }

  static List<String> expenseTelemetrySummaryOcrContractFindingsFor(
    MaintainiacFirestoreDocumentDraft draft,
  ) {
    return _expenseTelemetrySummaryOcrContractFindingsFor(draft);
  }

  static MaintainiacFirestoreDocumentDraft sharedCorrectionCandidateDocument(
    ExpenseReceiptItemMemory memory, {
    DateTime? submittedAtUtc,
    String source = 'local_opt_in',
  }) {
    final submittedAt = (submittedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final candidateId = _hashParts([
      memory.merchantName,
      memory.normalizedDescription,
      memory.catalogItemId ?? '',
      memory.category,
    ]).substring(0, 32);
    return MaintainiacFirestoreDocumentDraft(
      path:
          '${MaintainiacFirestoreSchema.sharedCorrectionCandidates}/$candidateId',
      data: Map.unmodifiable({
        'schema': _schemaCorrectionCandidate,
        'candidateId': candidateId,
        'submittedAtUtc': submittedAt.toIso8601String(),
        'source': _safeToken(source),
        'merchantHash': _hashText(memory.merchantName),
        'normalizedDescriptionHash': _hashText(memory.normalizedDescription),
        'rawReceiptTextHash': _hashText(memory.rawReceiptText),
        'correctedDescriptionHash': _hashText(memory.correctedDescription),
        'category': _safeToken(memory.category, fallback: 'uncategorized'),
        'useName': _safeToken(memory.useName, fallback: 'business'),
        'unit': _safeToken(memory.unit, fallback: 'each'),
        'hasCatalogMatch': memory.hasCatalogMatch,
        if (memory.catalogItemId != null)
          'catalogItemId': _safeCatalogToken(memory.catalogItemId!),
        if (memory.catalogItemPath != null)
          'catalogItemPathHash': _hashText(memory.catalogItemPath!),
        'parserNeedsReview': memory.parserNeedsReview,
        'reviewAction': _safeToken(memory.reviewAction, fallback: 'saved'),
        'seenCountBucket': _seenCountBucket(memory.seenCount),
        'firstSeenAgeBucket': _ageBucket(memory.firstSeenAt, submittedAt),
      }),
    );
  }
}

Map<String, Object?> _sanitizeCommandCenterOcrContract(
  Map<String, Object?> contract,
) {
  final findings = ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(
    contract,
  );
  if (findings.isNotEmpty) {
    throw ArgumentError.value(
      findings,
      'commandCenterOcrContract',
      'Unsafe expense OCR Command Center contract.',
    );
  }
  return Map.unmodifiable({
    for (final key in ExpenseExportSnapshot.commandCenterOcrAllowedKeys)
      key: _sanitizeCommandCenterOcrValue(key, contract[key]),
  });
}

Object? _sanitizeCommandCenterOcrValue(String key, Object? value) {
  if (value == null || value is bool || value is int) return value;
  if (value is double) {
    return double.parse(value.toStringAsFixed(4));
  }
  if (value is String) {
    if (key == 'rangeStart' || key == 'rangeEnd') {
      return _safeIso(value);
    }
    if (key == 'ocrReadStatus' ||
        key == 'ocrReadSummary' ||
        key == 'ocrTopCheck' ||
        key == 'ocrTopPrimaryIssue' ||
        key == 'ocrTopPrimaryAction') {
      return _ExpenseTelemetryFirestoreRedactor.readableText(value);
    }
    return value;
  }
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries) '${entry.key}': entry.value,
    });
  }
  throw ArgumentError.value(
    value,
    key,
    'Unsupported expense OCR Command Center contract value.',
  );
}

List<String> _expenseTelemetrySummaryOcrContractFindingsFor(
  MaintainiacFirestoreDocumentDraft draft,
) {
  final findings = <String>[];
  final path = draft.path;
  final data = draft.data;
  if (!RegExp(r'^orgs/[^/]+/expenseTelemetrySummaries/[^/]+$').hasMatch(path)) {
    findings.add('invalid_path:$path');
  }
  if (data['uploadShape'] != 'single_summary_document') {
    findings.add('invalid_upload_shape:${data['uploadShape']}');
  }
  if (data['rawEventUploadCount'] != 0) {
    findings.add('raw_event_upload_count:${data['rawEventUploadCount']}');
  }
  for (final forbidden in _expenseTelemetrySummaryForbiddenOcrKeys) {
    if (data.containsKey(forbidden)) {
      findings.add('forbidden_top_level_key:$forbidden');
    }
  }
  final contract = data['commandCenterOcrContract'];
  if (contract == null) {
    return List.unmodifiable(findings);
  }
  if (contract is! Map) {
    findings.add('invalid_ocr_contract_shape');
    return List.unmodifiable(findings);
  }
  final typedContract = Map<String, Object?>.from(contract);
  findings.addAll(
    ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(
      typedContract,
    ).map((finding) => 'ocr_contract:$finding'),
  );
  if (typedContract.containsKey('uploadShape')) {
    findings.add('ocr_contract_forbidden_upload_shape');
  }
  if (typedContract.containsKey('rawEventUploadCount')) {
    findings.add('ocr_contract_forbidden_raw_event_upload_count');
  }
  return List.unmodifiable(findings);
}

const _expenseTelemetrySummaryForbiddenOcrKeys = <String>{
  'merchantName',
  'merchantNames',
  'receiptImage',
  'receiptImagePath',
  'receiptImages',
  'receiptText',
  'rawOcrText',
  'importedReceiptText',
  'itemDescription',
  'itemDescriptions',
  'lineDescriptions',
  'proofPath',
  'proofPaths',
  'localFilePath',
  'localProofPath',
};

Map<String, Object?> _sanitizeCatalogHealth(Map<String, Object?> source) {
  const allowed = {
    'event',
    'featureArea',
    'packId',
    'packVersion',
    'status',
    'isReady',
    'chunkCount',
    'itemCount',
    'issueCount',
    'firestoreManifestReadCount',
    'firestoreItemDocumentReadCount',
  };
  return {
    for (final entry in source.entries)
      if (allowed.contains(entry.key)) entry.key: _sanitizeHealthValue(entry),
  };
}

Map<String, Object?> _sanitizeExpenseTelemetryMap(Map<String, Object?> source) {
  const allowed = {
    'schema',
    'summaryId',
    'summaryScope',
    'uploadShape',
    'rawEventUploadCount',
    'generatedAtUtc',
    'healthLabel',
    'totalEventCount',
    'pendingUploadCount',
    'uploadedEventCount',
    'eventCounts',
    'platformCounts',
    'deviceTierCounts',
    'storageModeCounts',
    'planStatusCounts',
    'connectionStatusCounts',
    'screenOpenCount',
    'averageTimeSpentSeconds',
    'addExpenseStartedCount',
    'addExpenseCompletedCount',
    'addExpenseAbandonedCount',
    'addExpenseCompletionRate',
    'addExpenseAbandonmentRate',
    'validationErrorCount',
    'saveFailureCount',
    'imageAttachSuccessCount',
    'imageAttachFailureCount',
    'imageAttachFailureRate',
    'ocrStartedCount',
    'ocrCompletedCount',
    'ocrFailedCount',
    'ocrSuccessRate',
    'parserStartedCount',
    'parserCompletedCount',
    'parserNeedsReviewCount',
    'parserFailedCount',
    'parserSuccessRate',
    'parserReviewRate',
    'parserFailureRate',
    'parserCategoryCounts',
    'parserNeedsReviewCategoryCounts',
    'parserFailedCategoryCounts',
    'parserFieldConfidenceCounts',
    'topParserCategory',
    'topParserNeedsReviewCategory',
    'topParserFailedCategory',
    'ocrCorrectionOpenedCount',
    'appFilledReceiptLineConfirmedCount',
    'appFilledReceiptLineCorrectedCount',
    'appFilledReceiptLineCorrectionRate',
    'userCorrectionCount',
    'cloudBackupSuccessCount',
    'cloudBackupFailureCount',
    'cloudBackupFailureRate',
    'syncPendingCount',
    'syncedCount',
    'syncFailedCount',
    'syncFailureRate',
    'expenseSummaryQueuedCount',
    'expenseSummaryOcrContractQueuedCount',
    'expenseSummaryOcrContractSkippedCount',
    'expenseSummaryOcrContractSourceCounts',
    'topExpenseSummaryOcrContractSource',
    'expenseSummaryOcrContractSkippedReasonCounts',
    'topExpenseSummaryOcrContractSkippedReason',
    'exportStartedCount',
    'exportCompletedCount',
    'exportBlockedCount',
    'exportFailedCount',
    'exportCompletionRate',
    'exportFailureRate',
    'ocrFailureCauseCounts',
    'topOcrFailureCause',
    'ocrFailureSourceCounts',
    'topOcrFailureSource',
    'topOcrFailureSourceAction',
    'ocrFailureStageCounts',
    'topOcrFailureStage',
    'topOcrFailureStageLabel',
    'failureBreakdowns',
    'recentFailureDetails',
    'eventId',
    'queuedAtUtc',
    'event',
    'featureArea',
    'featureLabel',
    'workflowStep',
    'workflowStepLabel',
    'failedAt',
    'failedAtLabel',
    'confirmedCause',
    'causeLabel',
    'causeStatus',
    'causeStatusLabel',
    'evidence',
    'evidenceLabel',
    'missingEvidence',
    'missingEvidenceLabel',
    'recommendedAction',
    'actionSummary',
    'ocrFailureSource',
    'ocrFailureSourceAction',
    'count',
    'retryCount',
    'abandoned',
    'abandonedCount',
    'platform',
    'deviceTier',
    'appVersion',
    'appVersionCounts',
  };
  return {
    for (final entry in source.entries)
      if (allowed.contains(entry.key))
        entry.key: _sanitizeExpenseTelemetryValue(entry.key, entry.value),
  };
}

Object? _sanitizeExpenseTelemetryValue(String key, Object? value) {
  if (value == null || value is bool) return value;
  if (value is int) {
    if (value < 0) {
      throw ArgumentError.value(value, key, 'Counts must be positive.');
    }
    return value;
  }
  if (value is double) {
    if (value.isNaN || value.isInfinite || value < 0) {
      throw ArgumentError.value(value, key, 'Rates must be finite.');
    }
    return double.parse(value.toStringAsFixed(4));
  }
  if (value is String) {
    if (key == 'generatedAtUtc' || key == 'queuedAtUtc') {
      return _safeIso(value);
    }
    if (key.endsWith('Label') ||
        key == 'recommendedAction' ||
        key == 'actionSummary') {
      return _ExpenseTelemetryFirestoreRedactor.readableText(value);
    }
    return _ExpenseTelemetryFirestoreRedactor.tokenFor(key, value);
  }
  if (value is Map) {
    final sanitized = <String, Object?>{};
    for (final entry in value.entries) {
      final countKey = _ExpenseTelemetryFirestoreRedactor.mapKeyFor(
        key,
        entry.key.toString(),
      );
      final countValue = entry.value;
      if (countValue is int && countValue >= 0) {
        sanitized[countKey] = countValue;
      }
    }
    return Map.unmodifiable(sanitized);
  }
  if (value is Iterable) {
    return [
      for (final item in value)
        if (item is Map)
          _sanitizeExpenseTelemetryMap(Map<String, Object?>.from(item)),
    ];
  }
  throw ArgumentError.value(value, key, 'Unsupported telemetry summary value.');
}

class _ExpenseTelemetryFirestoreRedactor {
  const _ExpenseTelemetryFirestoreRedactor._();

  static const privateReceiptHintTokenFields = {
    'failedAt',
    'confirmedCause',
    'evidence',
    'missingEvidence',
    'topOcrFailureCause',
    'topOcrFailureStage',
  };

  static const privateReceiptHintMapFields = {
    'ocrFailureCauseCounts',
    'ocrFailureStageCounts',
    'expenseSummaryOcrContractSkippedReasonCounts',
    'parserCategoryCounts',
    'parserNeedsReviewCategoryCounts',
    'parserFailedCategoryCounts',
    'parserFieldConfidenceCounts',
  };

  static final _knownMerchantPattern = RegExp(
    r"\b(?:lowe\s*s|lowe'?s|walmart|target|home depot|costco|sam\s*s club|sam'?s club|shell|exxon|mobil|chevron|marathon|sheetz|wawa|speedway|circle k|bp|sunoco|pilot|flying j|love\s*s|love'?s|casey\s*s|casey'?s|kwik trip|kum\s*(?:and|&)?\s*go|quicktrip|qt|racetrac|raceway|royal farms|murphy usa|valero|phillips 66|citgo|sinclair|mapco|getgo|thorntons|travelcenters of america|petro|jiffy lube|valvoline|take 5|midas|pep boys|firestone|discount tire|les schwab|goodyear|ntb|autozone|advance auto|oreilly|o'?reilly|napa|carquest|tractor supply|harbor freight|menards|ace hardware|true value|rural king|fleet farm|blain\s*s farm fleet|blain'?s farm fleet)\b",
    caseSensitive: false,
  );
  static final _knownLocationPattern = RegExp(
    r'\b(?:austin|atlanta|baltimore|charlotte|chicago|columbus|dallas|denver|detroit|houston|indianapolis|jacksonville|knoxville|las vegas|los angeles|louisville|memphis|miami|nashville|new york|orlando|philadelphia|phoenix|raleigh|richmond|san antonio|san diego|san francisco|seattle|tampa|washington)\b',
    caseSensitive: false,
  );
  static final _privateReferencePattern = RegExp(
    r'\b(?:auth(?:code)?|approval|barcode|card|customer|client|employee|driver|email|invoice|member|name|note|notes|order|phone|sale|store|terminal|transaction|trans|user)\s+(?!(?:number|amount|merchant|location|unknown|private|reference)\b)[a-z0-9]+\b',
    caseSensitive: false,
  );
  static final _privateNotePattern = RegExp(
    r'\b(?:user|customer|client|employee|driver)?\s*(?:note|notes|name)\s+(?:[a-z0-9]+\s+){0,3}[a-z0-9]+\b',
    caseSensitive: false,
  );
  static final _unknownSourceLabelPattern = RegExp(
    r'\bsource\s+(?!(?:photo|camera|image|capture|pdf|document|text|imported\s+text|pasted\s+text|mixed|combined|multiple|none|missing|unknown)\b)[a-z0-9]+(?:\s+[a-z0-9]+){0,1}',
    caseSensitive: false,
  );

  static String readableText(String value) {
    final safe = redactPrivateReceiptHints(value)
        .replaceAll(RegExp(r'\bMerchant\b'), 'merchant')
        .replaceAll(RegExp(r'[^A-Za-z0-9 .,;:/()%-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (safe.isEmpty) return 'Unknown';
    return safe.length > 180 ? safe.substring(0, 180) : safe;
  }

  static String tokenFor(String key, String value) {
    final tokenValue = privateReceiptHintTokenFields.contains(key)
        ? redactPrivateReceiptHints(value)
        : value;
    return _safeToken(tokenValue);
  }

  static String mapKeyFor(String key, String value) {
    final tokenValue = privateReceiptHintMapFields.contains(key)
        ? redactPrivateReceiptHints(value)
        : value;
    return _safeToken(tokenValue);
  }

  static String redactPrivateReceiptHints(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\$+\s*\d+(?:[._\s]\d+)?'), 'amount')
        .replaceAll(RegExp(r'\d+[._]\d{2,}'), 'amount')
        .replaceAll(RegExp(r'\b\d+\s+\d{2,}\b'), 'amount')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(_unknownSourceLabelPattern, 'source unknown')
        .replaceAll(RegExp(r'(?<![A-Za-z0-9])\d{3,}(?![A-Za-z0-9])'), 'number')
        .replaceAll(_privateNotePattern, 'private reference')
        .replaceAll(_knownMerchantPattern, 'merchant')
        .replaceAll(_knownLocationPattern, 'location')
        .replaceAll(_privateReferencePattern, 'private reference');
  }
}

Object? _sanitizeHealthValue(MapEntry<String, Object?> entry) {
  final value = entry.value;
  if (value == null || value is bool) return value;
  if (value is int) {
    if (value < 0) {
      throw ArgumentError.value(value, entry.key, 'Counts must be positive.');
    }
    return value;
  }
  if (value is String) return _safeToken(value);
  throw ArgumentError.value(value, entry.key, 'Unsupported health value.');
}

String _safePathToken(String value) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return 'unknown';
  return safe;
}

String _safeStoragePath(String value) {
  final clean = value.trim().replaceAll(RegExp(r'/+'), '/');
  if (clean.isEmpty || clean.startsWith('/') || clean.contains('..')) {
    throw ArgumentError.value(value, 'storagePrefix', 'Unsafe storage path.');
  }
  return clean;
}

String _safeIso(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
  }
  return parsed.toUtc().toIso8601String();
}

String _safeToken(String value, {String fallback = 'unknown'}) {
  final safe = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) {
    return fallback;
  }
  return safe.length > 64 ? safe.substring(0, 64) : safe;
}

String _safeCatalogToken(String value) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_.:-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return 'unknown';
  return safe.length > 96 ? safe.substring(0, 96) : safe;
}

String _hashText(String value) => _hashParts([value.trim().toLowerCase()]);

String _hashParts(Iterable<String> parts) {
  final encoded = utf8.encode(parts.join('\u001f'));
  return sha256.convert(encoded).toString();
}

String _seenCountBucket(int seenCount) {
  if (seenCount <= 1) return '1';
  if (seenCount <= 3) return '2_3';
  if (seenCount <= 9) return '4_9';
  return '10_plus';
}

String _ageBucket(DateTime firstSeenAt, DateTime submittedAt) {
  final days = submittedAt.difference(firstSeenAt.toUtc()).inDays;
  if (days <= 0) return 'same_day';
  if (days <= 7) return 'week';
  if (days <= 31) return 'month';
  return 'older';
}
