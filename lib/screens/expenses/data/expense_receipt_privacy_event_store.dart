import 'package:hive_flutter/hive_flutter.dart';

import 'expense_receipt_parser.dart';

class ReceiptPrivacyEventPolicy {
  const ReceiptPrivacyEventPolicy._();

  static const allowedKeys = <String>{
    'event',
    'featureArea',
    'capabilityTier',
    'parserDepth',
    'ocrSeverity',
    'parseQuality',
    'parserTrust',
    'parserReviewCause',
    'totalsMathStatus',
    'fieldReviewKeys',
    'captureMode',
    'captureOutcome',
    'focusBucket',
    'readabilityBucket',
    'errorKind',
    'warningKinds',
    'photoSectionCount',
    'retakeCount',
    'captureDurationMs',
    'attachmentsRead',
    'attachmentsSkipped',
    'rawLineCount',
    'parserLineCount',
    'detectedLineCount',
    'reviewLineCount',
    'materialLineCount',
    'catalogMatchedLineCount',
    'unmatchedMaterialLineCount',
    'negativeLineCount',
    'adjustmentLineCount',
    'pdfPagesRequested',
    'reconciled',
    'taxMathReconciled',
    'explicitTotalsComplete',
    'needsHeavyReview',
    'usedLocalOcr',
    'hadDuplicateOrOverlapText',
  };

  static const maxStringLength = 64;
  static final RegExp _safeTokenPattern = RegExp(r'^[A-Za-z0-9_]+$');

  static Map<String, Object?> sanitize(PrivacySafeReceiptEvent event) {
    return sanitizeMap(event.toMap());
  }

  static Map<String, Object?> sanitizeMap(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (!allowedKeys.contains(key)) continue;
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }

  static bool isSafeMap(Map<String, Object?> source) {
    try {
      sanitizeMap(source);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) {
      if (value < 0) {
        throw ArgumentError.value(value, key, 'Counts must be non-negative.');
      }
      return value;
    }
    if (value is String) return _sanitizeToken(key, value);
    if (value is Iterable) {
      return List<String>.unmodifiable(
        value.map((item) => _sanitizeToken(key, item)),
      );
    }
    throw ArgumentError.value(value, key, 'Unsupported receipt event value.');
  }

  static String _sanitizeToken(String key, Object? value) {
    if (value is! String) {
      throw ArgumentError.value(value, key, 'Expected a safe token.');
    }
    final token = value.trim();
    if (token.isEmpty ||
        token.length > maxStringLength ||
        !_safeTokenPattern.hasMatch(token)) {
      throw ArgumentError.value(value, key, 'Unsafe receipt event token.');
    }
    return token;
  }
}

class PrivacySafeReceiptEventRecord {
  const PrivacySafeReceiptEventRecord({
    required this.id,
    required this.queuedAtUtc,
    required this.payload,
    this.uploadedAtUtc,
  });

  factory PrivacySafeReceiptEventRecord.fromStored(Object? value) {
    if (value is! Map) return PrivacySafeReceiptEventRecord.empty;
    try {
      final payload = value['payload'];
      return PrivacySafeReceiptEventRecord(
        id: _stringValue(value['id']),
        queuedAtUtc:
            DateTime.tryParse(_stringValue(value['queuedAtUtc'])) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        uploadedAtUtc: DateTime.tryParse(_stringValue(value['uploadedAtUtc'])),
        payload: payload is Map
            ? ReceiptPrivacyEventPolicy.sanitizeMap(
                Map<String, Object?>.from(payload),
              )
            : const {},
      );
    } catch (_) {
      return PrivacySafeReceiptEventRecord.empty;
    }
  }

  static final empty = PrivacySafeReceiptEventRecord(
    id: '',
    queuedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    payload: const {},
  );

  final String id;
  final DateTime queuedAtUtc;
  final DateTime? uploadedAtUtc;
  final Map<String, Object?> payload;

  bool get isEmpty => id.isEmpty;
  bool get isPendingUpload => !isEmpty && uploadedAtUtc == null;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'queuedAtUtc': queuedAtUtc.toUtc().toIso8601String(),
      if (uploadedAtUtc != null)
        'uploadedAtUtc': uploadedAtUtc!.toUtc().toIso8601String(),
      'payload': ReceiptPrivacyEventPolicy.sanitizeMap(payload),
    };
  }
}

class ReceiptPrivacyEventHealthSnapshot {
  const ReceiptPrivacyEventHealthSnapshot({
    required this.generatedAtUtc,
    required this.totalEventCount,
    required this.pendingUploadCount,
    required this.uploadedEventCount,
    required this.firstEventAtUtc,
    required this.lastEventAtUtc,
    required this.eventCounts,
    required this.featureAreaCounts,
    required this.ocrSeverityCounts,
    required this.parseQualityCounts,
    required this.parserTrustCounts,
    required this.parserReviewCauseCounts,
    required this.totalsMathStatusCounts,
    required this.fieldReviewKeyCounts,
    required this.capabilityTierCounts,
    required this.captureModeCounts,
    required this.captureOutcomeCounts,
    required this.focusBucketCounts,
    required this.readabilityBucketCounts,
    required this.errorKindCounts,
    required this.warningKindCounts,
    required this.reviewOrProblemCount,
    required this.blockedOcrCount,
    required this.totalsMismatchCount,
    required this.taxMathMismatchCount,
    required this.heavyReviewCount,
    required this.catalogWeakMatchCount,
    required this.duplicateOrOverlapCount,
    required this.unmatchedMaterialLineCount,
    required this.catalogMatchedLineCount,
    required this.detectedLineCount,
    required this.parserLineCount,
    required this.pdfPagesRequested,
    required this.photoSectionCount,
    required this.retakeCount,
    required this.captureDurationMs,
  });

  factory ReceiptPrivacyEventHealthSnapshot.fromRecords(
    Iterable<PrivacySafeReceiptEventRecord> records, {
    DateTime? generatedAtUtc,
  }) {
    final sorted = records.toList(growable: false)
      ..sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    final eventCounts = <String, int>{};
    final featureAreaCounts = <String, int>{};
    final ocrSeverityCounts = <String, int>{};
    final parseQualityCounts = <String, int>{};
    final parserTrustCounts = <String, int>{};
    final parserReviewCauseCounts = <String, int>{};
    final totalsMathStatusCounts = <String, int>{};
    final fieldReviewKeyCounts = <String, int>{};
    final capabilityTierCounts = <String, int>{};
    final captureModeCounts = <String, int>{};
    final captureOutcomeCounts = <String, int>{};
    final focusBucketCounts = <String, int>{};
    final readabilityBucketCounts = <String, int>{};
    final errorKindCounts = <String, int>{};
    final warningKindCounts = <String, int>{};
    var pendingUploadCount = 0;
    var uploadedEventCount = 0;
    var reviewOrProblemCount = 0;
    var blockedOcrCount = 0;
    var totalsMismatchCount = 0;
    var taxMathMismatchCount = 0;
    var heavyReviewCount = 0;
    var catalogWeakMatchCount = 0;
    var duplicateOrOverlapCount = 0;
    var unmatchedMaterialLineCount = 0;
    var catalogMatchedLineCount = 0;
    var detectedLineCount = 0;
    var parserLineCount = 0;
    var pdfPagesRequested = 0;
    var photoSectionCount = 0;
    var retakeCount = 0;
    var captureDurationMs = 0;

    for (final record in sorted) {
      final payload = ReceiptPrivacyEventPolicy.sanitizeMap(record.payload);
      if (record.isPendingUpload) {
        pendingUploadCount += 1;
      } else {
        uploadedEventCount += 1;
      }
      final event = _stringValue(payload['event']);
      _increment(eventCounts, event);
      _increment(featureAreaCounts, _stringValue(payload['featureArea']));
      _increment(ocrSeverityCounts, _stringValue(payload['ocrSeverity']));
      _increment(parseQualityCounts, _stringValue(payload['parseQuality']));
      _increment(parserTrustCounts, _stringValue(payload['parserTrust']));
      _increment(
        parserReviewCauseCounts,
        _stringValue(payload['parserReviewCause']),
      );
      _increment(
        totalsMathStatusCounts,
        _stringValue(payload['totalsMathStatus']),
      );
      for (final fieldKey in _stringListValue(payload['fieldReviewKeys'])) {
        _increment(fieldReviewKeyCounts, fieldKey);
      }
      _increment(capabilityTierCounts, _stringValue(payload['capabilityTier']));
      _increment(captureModeCounts, _stringValue(payload['captureMode']));
      _increment(captureOutcomeCounts, _stringValue(payload['captureOutcome']));
      _increment(focusBucketCounts, _stringValue(payload['focusBucket']));
      _increment(
        readabilityBucketCounts,
        _stringValue(payload['readabilityBucket']),
      );
      _increment(errorKindCounts, _stringValue(payload['errorKind']));
      for (final warning in _stringListValue(payload['warningKinds'])) {
        _increment(warningKindCounts, warning);
      }
      final ocrSeverity = _stringValue(payload['ocrSeverity']);
      final parseQuality = _stringValue(payload['parseQuality']);
      if (event.contains('Review') ||
          event.contains('Poor') ||
          event.contains('Blocked') ||
          event.contains('Mismatch') ||
          event.contains('Weak') ||
          ocrSeverity == 'review' ||
          ocrSeverity == 'partial' ||
          ocrSeverity == 'blocked' ||
          parseQuality == 'medium' ||
          parseQuality == 'low' ||
          _boolValue(payload['needsHeavyReview'])) {
        reviewOrProblemCount += 1;
      }
      if (event == PrivacySafeReceiptEventType.receiptOcrBlocked.name) {
        blockedOcrCount += 1;
      }
      if (event == PrivacySafeReceiptEventType.receiptTotalsMismatch.name) {
        totalsMismatchCount += 1;
      }
      if (_boolValue(payload['explicitTotalsComplete']) &&
          !_boolValue(payload['taxMathReconciled'])) {
        taxMathMismatchCount += 1;
      }
      if (_boolValue(payload['needsHeavyReview'])) {
        heavyReviewCount += 1;
      }
      if (event == PrivacySafeReceiptEventType.inventoryCatalogMatchWeak.name) {
        catalogWeakMatchCount += 1;
      }
      if (_boolValue(payload['hadDuplicateOrOverlapText'])) {
        duplicateOrOverlapCount += 1;
      }
      unmatchedMaterialLineCount += _intValue(
        payload['unmatchedMaterialLineCount'],
      );
      catalogMatchedLineCount += _intValue(payload['catalogMatchedLineCount']);
      detectedLineCount += _intValue(payload['detectedLineCount']);
      parserLineCount += _intValue(payload['parserLineCount']);
      pdfPagesRequested += _intValue(payload['pdfPagesRequested']);
      photoSectionCount += _intValue(payload['photoSectionCount']);
      retakeCount += _intValue(payload['retakeCount']);
      captureDurationMs += _intValue(payload['captureDurationMs']);
    }

    return ReceiptPrivacyEventHealthSnapshot(
      generatedAtUtc: (generatedAtUtc ?? DateTime.now().toUtc()).toUtc(),
      totalEventCount: sorted.length,
      pendingUploadCount: pendingUploadCount,
      uploadedEventCount: uploadedEventCount,
      firstEventAtUtc: sorted.isEmpty ? null : sorted.first.queuedAtUtc.toUtc(),
      lastEventAtUtc: sorted.isEmpty ? null : sorted.last.queuedAtUtc.toUtc(),
      eventCounts: Map.unmodifiable(eventCounts),
      featureAreaCounts: Map.unmodifiable(featureAreaCounts),
      ocrSeverityCounts: Map.unmodifiable(ocrSeverityCounts),
      parseQualityCounts: Map.unmodifiable(parseQualityCounts),
      parserTrustCounts: Map.unmodifiable(parserTrustCounts),
      parserReviewCauseCounts: Map.unmodifiable(parserReviewCauseCounts),
      totalsMathStatusCounts: Map.unmodifiable(totalsMathStatusCounts),
      fieldReviewKeyCounts: Map.unmodifiable(fieldReviewKeyCounts),
      capabilityTierCounts: Map.unmodifiable(capabilityTierCounts),
      captureModeCounts: Map.unmodifiable(captureModeCounts),
      captureOutcomeCounts: Map.unmodifiable(captureOutcomeCounts),
      focusBucketCounts: Map.unmodifiable(focusBucketCounts),
      readabilityBucketCounts: Map.unmodifiable(readabilityBucketCounts),
      errorKindCounts: Map.unmodifiable(errorKindCounts),
      warningKindCounts: Map.unmodifiable(warningKindCounts),
      reviewOrProblemCount: reviewOrProblemCount,
      blockedOcrCount: blockedOcrCount,
      totalsMismatchCount: totalsMismatchCount,
      taxMathMismatchCount: taxMathMismatchCount,
      heavyReviewCount: heavyReviewCount,
      catalogWeakMatchCount: catalogWeakMatchCount,
      duplicateOrOverlapCount: duplicateOrOverlapCount,
      unmatchedMaterialLineCount: unmatchedMaterialLineCount,
      catalogMatchedLineCount: catalogMatchedLineCount,
      detectedLineCount: detectedLineCount,
      parserLineCount: parserLineCount,
      pdfPagesRequested: pdfPagesRequested,
      photoSectionCount: photoSectionCount,
      retakeCount: retakeCount,
      captureDurationMs: captureDurationMs,
    );
  }

  final DateTime generatedAtUtc;
  final int totalEventCount;
  final int pendingUploadCount;
  final int uploadedEventCount;
  final DateTime? firstEventAtUtc;
  final DateTime? lastEventAtUtc;
  final Map<String, int> eventCounts;
  final Map<String, int> featureAreaCounts;
  final Map<String, int> ocrSeverityCounts;
  final Map<String, int> parseQualityCounts;
  final Map<String, int> parserTrustCounts;
  final Map<String, int> parserReviewCauseCounts;
  final Map<String, int> totalsMathStatusCounts;
  final Map<String, int> fieldReviewKeyCounts;
  final Map<String, int> capabilityTierCounts;
  final Map<String, int> captureModeCounts;
  final Map<String, int> captureOutcomeCounts;
  final Map<String, int> focusBucketCounts;
  final Map<String, int> readabilityBucketCounts;
  final Map<String, int> errorKindCounts;
  final Map<String, int> warningKindCounts;
  final int reviewOrProblemCount;
  final int blockedOcrCount;
  final int totalsMismatchCount;
  final int taxMathMismatchCount;
  final int heavyReviewCount;
  final int catalogWeakMatchCount;
  final int duplicateOrOverlapCount;
  final int unmatchedMaterialLineCount;
  final int catalogMatchedLineCount;
  final int detectedLineCount;
  final int parserLineCount;
  final int pdfPagesRequested;
  final int photoSectionCount;
  final int retakeCount;
  final int captureDurationMs;

  bool get hasEvents => totalEventCount > 0;
  bool get needsAttention => reviewOrProblemCount > 0;

  double get reviewRate {
    if (totalEventCount == 0) return 0;
    return reviewOrProblemCount / totalEventCount;
  }

  int get ocrAttemptCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptOcrGood) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrPartial) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrBlocked);
  }

  int get captureAttemptCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptCaptureStarted) +
        _eventCount(PrivacySafeReceiptEventType.receiptCaptureCompleted) +
        _eventCount(PrivacySafeReceiptEventType.receiptCaptureAbandoned) +
        _eventCount(PrivacySafeReceiptEventType.receiptCaptureFailed);
  }

  int get captureCompletedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptCaptureCompleted);

  int get captureFailedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptCaptureFailed);

  int get captureAbandonedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptCaptureAbandoned);

  double get captureSuccessRate {
    final completedOrProblem =
        captureCompletedCount + captureFailedCount + captureAbandonedCount;
    if (completedOrProblem == 0) return 0;
    return captureCompletedCount / completedOrProblem;
  }

  double get averageCaptureDurationMs {
    if (captureCompletedCount == 0) return 0;
    return captureDurationMs / captureCompletedCount;
  }

  int get ocrGoodCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptOcrGood);

  int get ocrReadableCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptOcrGood) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrPartial);
  }

  int get ocrFailedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptOcrBlocked);

  double get ocrGoodRate {
    if (ocrAttemptCount == 0) return 0;
    return ocrGoodCount / ocrAttemptCount;
  }

  double get ocrReadableRate {
    if (ocrAttemptCount == 0) return 0;
    return ocrReadableCount / ocrAttemptCount;
  }

  double get ocrFailRate {
    if (ocrAttemptCount == 0) return 0;
    return ocrFailedCount / ocrAttemptCount;
  }

  int get parserAttemptCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptParserGood) +
        _eventCount(PrivacySafeReceiptEventType.receiptParserReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptParserPoor) +
        _eventCount(PrivacySafeReceiptEventType.receiptTotalsMismatch) +
        _eventCount(PrivacySafeReceiptEventType.inventoryCatalogMatchWeak);
  }

  int get parserGoodCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptParserGood);

  int get parserProblemCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptParserReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptParserPoor) +
        _eventCount(PrivacySafeReceiptEventType.receiptTotalsMismatch) +
        _eventCount(PrivacySafeReceiptEventType.inventoryCatalogMatchWeak);
  }

  double get parserSuccessRate {
    if (parserAttemptCount == 0) return 0;
    return parserGoodCount / parserAttemptCount;
  }

  double get parserProblemRate {
    if (parserAttemptCount == 0) return 0;
    return parserProblemCount / parserAttemptCount;
  }

  double get catalogMatchRate {
    final total = catalogMatchedLineCount + unmatchedMaterialLineCount;
    if (total == 0) return 0;
    return catalogMatchedLineCount / total;
  }

  String get healthLabel {
    if (totalEventCount == 0) return 'no_data';
    if (blockedOcrCount > 0 ||
        taxMathMismatchCount > 0 ||
        heavyReviewCount > 0 ||
        reviewRate >= .35) {
      return 'needs_attention';
    }
    if (reviewRate >= .12 || catalogWeakMatchCount > 0) return 'watch';
    return 'healthy';
  }

  Map<String, Object?> toCommandCenterMap() {
    return {
      'schema': 'receipt_privacy_health_v1',
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'healthLabel': healthLabel,
      'totalEventCount': totalEventCount,
      'pendingUploadCount': pendingUploadCount,
      'uploadedEventCount': uploadedEventCount,
      if (firstEventAtUtc != null)
        'firstEventAtUtc': firstEventAtUtc!.toUtc().toIso8601String(),
      if (lastEventAtUtc != null)
        'lastEventAtUtc': lastEventAtUtc!.toUtc().toIso8601String(),
      'eventCounts': eventCounts,
      'featureAreaCounts': featureAreaCounts,
      'ocrSeverityCounts': ocrSeverityCounts,
      'parseQualityCounts': parseQualityCounts,
      'parserTrustCounts': parserTrustCounts,
      'parserReviewCauseCounts': parserReviewCauseCounts,
      'totalsMathStatusCounts': totalsMathStatusCounts,
      'fieldReviewKeyCounts': fieldReviewKeyCounts,
      'capabilityTierCounts': capabilityTierCounts,
      'captureModeCounts': captureModeCounts,
      'captureOutcomeCounts': captureOutcomeCounts,
      'focusBucketCounts': focusBucketCounts,
      'readabilityBucketCounts': readabilityBucketCounts,
      'errorKindCounts': errorKindCounts,
      'warningKindCounts': warningKindCounts,
      'reviewOrProblemCount': reviewOrProblemCount,
      'blockedOcrCount': blockedOcrCount,
      'totalsMismatchCount': totalsMismatchCount,
      'taxMathMismatchCount': taxMathMismatchCount,
      'heavyReviewCount': heavyReviewCount,
      'catalogWeakMatchCount': catalogWeakMatchCount,
      'duplicateOrOverlapCount': duplicateOrOverlapCount,
      'unmatchedMaterialLineCount': unmatchedMaterialLineCount,
      'catalogMatchedLineCount': catalogMatchedLineCount,
      'detectedLineCount': detectedLineCount,
      'parserLineCount': parserLineCount,
      'pdfPagesRequested': pdfPagesRequested,
      'photoSectionCount': photoSectionCount,
      'retakeCount': retakeCount,
      'captureDurationMs': captureDurationMs,
      'captureAttemptCount': captureAttemptCount,
      'captureCompletedCount': captureCompletedCount,
      'captureFailedCount': captureFailedCount,
      'captureAbandonedCount': captureAbandonedCount,
      'captureSuccessRate': captureSuccessRate,
      'averageCaptureDurationMs': averageCaptureDurationMs,
      'reviewRate': reviewRate,
      'ocrAttemptCount': ocrAttemptCount,
      'ocrGoodCount': ocrGoodCount,
      'ocrReadableCount': ocrReadableCount,
      'ocrFailedCount': ocrFailedCount,
      'ocrGoodRate': ocrGoodRate,
      'ocrReadableRate': ocrReadableRate,
      'ocrFailRate': ocrFailRate,
      'parserAttemptCount': parserAttemptCount,
      'parserGoodCount': parserGoodCount,
      'parserProblemCount': parserProblemCount,
      'parserSuccessRate': parserSuccessRate,
      'parserProblemRate': parserProblemRate,
      'catalogMatchRate': catalogMatchRate,
    };
  }

  int _eventCount(PrivacySafeReceiptEventType type) {
    return eventCounts[type.name] ?? 0;
  }
}

class PrivacySafeReceiptEventStore {
  PrivacySafeReceiptEventStore._(this._box);

  static const boxName = 'privacy_safe_receipt_events';
  static const maxStoredEvents = 250;

  final Box<dynamic> _box;

  static Future<PrivacySafeReceiptEventStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return PrivacySafeReceiptEventStore._(box);
  }

  List<PrivacySafeReceiptEventRecord> get records {
    final loaded = <PrivacySafeReceiptEventRecord>[];
    for (final value in _box.values) {
      final record = PrivacySafeReceiptEventRecord.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  List<PrivacySafeReceiptEventRecord> get pendingUploadRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  ReceiptPrivacyEventHealthSnapshot buildHealthSnapshot({DateTime? nowUtc}) {
    return ReceiptPrivacyEventHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: nowUtc,
    );
  }

  Future<PrivacySafeReceiptEventRecord> enqueue(
    PrivacySafeReceiptEvent event, {
    DateTime? queuedAtUtc,
  }) async {
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = PrivacySafeReceiptEventRecord(
      id: _eventIdFor(queuedAt),
      queuedAtUtc: queuedAt,
      payload: ReceiptPrivacyEventPolicy.sanitize(event),
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  List<Map<String, Object?>> pendingUploadPayloads({int limit = 50}) {
    final cappedLimit = limit.clamp(0, maxStoredEvents).toInt();
    return [
      for (final record in pendingUploadRecords.take(cappedLimit))
        Map<String, Object?>.unmodifiable({
          'eventId': record.id,
          'queuedAtUtc': record.queuedAtUtc.toUtc().toIso8601String(),
          'payload': ReceiptPrivacyEventPolicy.sanitizeMap(record.payload),
        }),
    ];
  }

  Future<void> markUploaded(
    Iterable<String> eventIds, {
    DateTime? nowUtc,
  }) async {
    final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final id in eventIds) {
      final record = PrivacySafeReceiptEventRecord.fromStored(_box.get(id));
      if (record.isEmpty) continue;
      await _box.put(
        id,
        PrivacySafeReceiptEventRecord(
          id: record.id,
          queuedAtUtc: record.queuedAtUtc,
          uploadedAtUtc: uploadedAt,
          payload: record.payload,
        ).toMap(),
      );
    }
  }

  Future<void> clearUploaded() async {
    for (final record in records) {
      if (record.uploadedAtUtc != null) {
        await _box.delete(record.id);
      }
    }
  }

  Future<void> clearAll() => _box.clear();

  Future<void> _trimOldestIfNeeded() async {
    final extraCount = records.length - maxStoredEvents;
    if (extraCount <= 0) return;
    for (final record in records.take(extraCount)) {
      await _box.delete(record.id);
    }
  }

  String _eventIdFor(DateTime queuedAtUtc) {
    final base = queuedAtUtc.microsecondsSinceEpoch.toString();
    var id = base;
    var suffix = 1;
    while (_box.containsKey(id)) {
      id = '$base-$suffix';
      suffix += 1;
    }
    return id;
  }
}

void _increment(Map<String, int> counts, String value) {
  if (value.isEmpty) return;
  counts[value] = (counts[value] ?? 0) + 1;
}

String _stringValue(Object? value) => value is String ? value : '';

List<String> _stringListValue(Object? value) {
  if (value is! Iterable) return const [];
  return [
    for (final item in value)
      if (item is String && item.isNotEmpty) item,
  ];
}

int _intValue(Object? value) => value is int ? value : 0;

bool _boolValue(Object? value) => value is bool && value;
