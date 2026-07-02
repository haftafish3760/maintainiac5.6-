import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../screens/expenses/data/expense_export_models.dart';
import '../../screens/expenses/data/expense_receipt_item_memory_store.dart';
import '../../screens/expenses/data/expense_receipt_privacy_event_store.dart';
import '../../screens/expenses/data/expense_screen_telemetry.dart';
import '../../screens/work_supplies/data/work_supply_catalog_health_event.dart';
import '../../screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';
import 'maintainiac_firestore_schema.dart';

part 'maintainiac_firestore_ocr_contract_sanitizer.dart';
part 'maintainiac_firestore_expense_telemetry_sanitizer.dart';
part 'maintainiac_firestore_expense_telemetry_redactor.dart';

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
