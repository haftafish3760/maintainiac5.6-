import 'package:hive_flutter/hive_flutter.dart';

enum ExpenseTelemetryEventType {
  screenOpened,
  screenClosed,
  timeSpentOnScreen,
  addExpenseStarted,
  addExpenseCompleted,
  addExpenseAbandoned,
  manualExpenseCreated,
  receiptExpenseCreated,
  editExpenseOpened,
  editExpenseSaved,
  deleteExpenseRequested,
  deleteExpenseConfirmed,
  categorySelected,
  categoryChanged,
  validationError,
  saveFailure,
  imageAttachSuccess,
  imageAttachFailure,
  ocrStarted,
  ocrCompleted,
  ocrFailed,
  parserStarted,
  parserCompleted,
  parserNeedsReview,
  parserFailed,
  ocrCorrectionOpened,
  appFilledReceiptLineConfirmed,
  appFilledReceiptLineCorrected,
  userCorrectedVendor,
  userCorrectedDate,
  userCorrectedTax,
  userCorrectedTotal,
  userCorrectedCategory,
  storageModeUsed,
  localImageRemoved,
  cloudBackupSuccess,
  cloudBackupFailure,
  syncPending,
  synced,
  syncFailed,
  exportStarted,
  exportCompleted,
  exportBlocked,
  exportFailed,
}

enum ExpenseTelemetryStorageMode { normal, low, ultraLow }

enum ExpenseTelemetryPlanStatus { free, paid, trial, unknown }

enum ExpenseTelemetryConnectionStatus { online, offline, unknown }

enum ExpenseWorkflowStep {
  screenLoad,
  chooseCategory,
  receiptAttachment,
  receiptOcr,
  receiptParser,
  lineReview,
  manualEntry,
  saveExpense,
  calendarEdit,
  deleteExpense,
  export,
  cloudBackup,
  sync,
  materialsBridge,
  maintenanceBridge,
}

enum ExpenseFailureCauseStatus { confirmed, notConfirmed }

class ExpenseFailureDiagnostic {
  const ExpenseFailureDiagnostic({
    required this.workflowStep,
    required this.failedAt,
    required this.confirmedCause,
    required this.causeStatus,
    required this.evidence,
    this.missingEvidence = 'none',
    this.retryCount = 0,
    this.abandoned = false,
  });

  final ExpenseWorkflowStep workflowStep;
  final String failedAt;
  final String confirmedCause;
  final ExpenseFailureCauseStatus causeStatus;
  final String evidence;
  final String missingEvidence;
  final int retryCount;
  final bool abandoned;

  Map<String, Object?> toMap() {
    return {
      'workflowStep': workflowStep.name,
      'failedAt': failedAt,
      'confirmedCause': confirmedCause,
      'causeStatus': causeStatus.name,
      'evidence': evidence,
      if (missingEvidence != 'none') 'missingEvidence': missingEvidence,
      if (retryCount > 0) 'retryCount': retryCount,
      if (abandoned) 'abandoned': true,
    };
  }
}

class ExpenseTelemetryContext {
  const ExpenseTelemetryContext({
    required this.appVersion,
    required this.platform,
    required this.deviceTier,
    required this.profileType,
    required this.storageMode,
    required this.planStatus,
    required this.connectionStatus,
  });

  const ExpenseTelemetryContext.unknown()
    : appVersion = 'unknown',
      platform = 'unknown',
      deviceTier = 'unknown',
      profileType = 'unknown',
      storageMode = ExpenseTelemetryStorageMode.normal,
      planStatus = ExpenseTelemetryPlanStatus.unknown,
      connectionStatus = ExpenseTelemetryConnectionStatus.unknown;

  final String appVersion;
  final String platform;
  final String deviceTier;
  final String profileType;
  final ExpenseTelemetryStorageMode storageMode;
  final ExpenseTelemetryPlanStatus planStatus;
  final ExpenseTelemetryConnectionStatus connectionStatus;

  Map<String, Object?> toMap() {
    return {
      'appVersion': _safeToken(appVersion, fallback: 'unknown'),
      'platform': _safeToken(platform, fallback: 'unknown'),
      'deviceTier': _safeToken(deviceTier, fallback: 'unknown'),
      'profileType': _safeToken(profileType, fallback: 'unknown'),
      'storageMode': storageMode.name,
      'planStatus': planStatus.name,
      'connectionStatus': connectionStatus.name,
    };
  }
}

class ExpenseTelemetryEvent {
  const ExpenseTelemetryEvent({
    required this.type,
    this.context = const ExpenseTelemetryContext.unknown(),
    this.durationMs = 0,
    this.validationErrorKind,
    this.failureKind,
    this.diagnostic,
    this.categoryGroup,
    this.metadata = const {},
  });

  final ExpenseTelemetryEventType type;
  final ExpenseTelemetryContext context;
  final int durationMs;
  final String? validationErrorKind;
  final String? failureKind;
  final ExpenseFailureDiagnostic? diagnostic;
  final String? categoryGroup;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return {
      'event': type.name,
      ...context.toMap(),
      if (durationMs > 0) 'durationMs': durationMs,
      if (validationErrorKind != null)
        'validationErrorKind': validationErrorKind,
      if (failureKind != null) 'failureKind': failureKind,
      if (diagnostic != null) ...diagnostic!.toMap(),
      if (categoryGroup != null) 'categoryGroup': categoryGroup,
      if (metadata.isNotEmpty)
        'metadata': ExpenseTelemetryPolicy.sanitizeMetadata(metadata),
    };
  }
}

class ExpenseTelemetryPolicy {
  const ExpenseTelemetryPolicy._();

  static const allowedKeys = <String>{
    'event',
    'appVersion',
    'platform',
    'deviceTier',
    'profileType',
    'storageMode',
    'planStatus',
    'connectionStatus',
    'durationMs',
    'validationErrorKind',
    'failureKind',
    'workflowStep',
    'failedAt',
    'confirmedCause',
    'causeStatus',
    'evidence',
    'missingEvidence',
    'retryCount',
    'abandoned',
    'categoryGroup',
    'metadata',
  };

  static const allowedMetadataKeys = <String>{
    'source',
    'receiptMode',
    'entryMode',
    'saveDestination',
    'attachmentKind',
    'ocrEngine',
    'parserDepth',
    'syncState',
    'storageAction',
    'errorKind',
    'count',
    'attempt',
    'bytesBucket',
    'durationBucket',
    'exportDestination',
    'rangePreset',
    'receiptCount',
    'lineCount',
    'parsedCategoryBuckets',
    'reviewCategoryBuckets',
    'parserFieldConfidenceBuckets',
    'parseQualityBucket',
    'parserLineReviewCount',
    'parserMatchedMaterialCount',
    'parserUnmatchedMaterialCount',
    'subtotalReconciliationStatus',
    'taxMathStatus',
    'summaryStatus',
    'ocrContractQueued',
    'ocrContractSource',
    'ocrContractSkippedReason',
    'captureFlow',
    'savedProofCount',
    'ocrSourceCount',
    'captureDiagnosticsCount',
    'capturedPhotoMegapixelBuckets',
    'capturedPhotoByteBuckets',
    'capturedPhotoBrightnessBuckets',
    'capturedPhotoSharpnessBuckets',
    'capturedPhotoQualitySignals',
    'capturedPhotoExposureMismatches',
    'capturedPhotoWidthMax',
    'capturedPhotoHeightMax',
    'brightnessBuckets',
    'readabilitySignalBuckets',
    'autoExposureDecisionBuckets',
    'autoExposureBrightnessBuckets',
    'autoExposureCandidateBuckets',
    'autoExposureCandidateFrameTotal',
    'exposureAssistStatuses',
    'framingConfidenceBuckets',
    'perspectiveReadinessBuckets',
    'focusStatusBuckets',
    'autoCaptureStatusBuckets',
    'closeActionBuckets',
    'pendingCloseAfterCaptureCount',
    'closeResultDeliveredCount',
    'autoCaptureAllowedCount',
    'autoCaptureCurrentlyAllowedCount',
    'storageSafetyLevelBuckets',
    'storageSafetyReasonBuckets',
    'storageConstrainedCount',
    'photoEditActions',
    'userEditedPhotoCount',
    'edgeDetectionEnabledCount',
    'edgeOverlayEnabledCount',
    'tapFocusEnabledCount',
    'pinchZoomEnabledCount',
    'brightnessSliderEnabledCount',
    'shadowWarningEnabledCount',
    'textTooSmallWarningEnabledCount',
    'autoCropSuggestionEnabledCount',
    'grayscalePreviewEnabledCount',
    'contrastBoostEnabledCount',
    'shadowReductionEnabledCount',
    'orientationCorrectionEnabledCount',
    'tapFocusTotal',
    'zoomChangeTotal',
    'manualBrightnessChangeTotal',
    'autoCaptureTriggerTotal',
    'scannerCleanupUsedCount',
    'cleanupActionCount',
    'cleanupActions',
    'stitchStatus',
    'stitchFallbackReason',
    'stitchConfidenceBucket',
  };

  static const blockedSensitiveKeys = <String>{
    'receiptImage',
    'receiptText',
    'ocrText',
    'rawOcrText',
    'customerName',
    'employeeName',
    'merchantName',
    'vendorName',
    'storeName',
    'address',
    'street',
    'phone',
    'email',
    'notes',
    'note',
    'itemDescription',
    'lineDescription',
    'fullItemDescription',
    'description',
    'receiptNumber',
  };

  static const maxStringLength = 64;
  static final _safeTokenPattern = RegExp(r'^[A-Za-z0-9_.-]+$');

  static Map<String, Object?> sanitize(ExpenseTelemetryEvent event) {
    return sanitizeMap(event.toMap());
  }

  static Map<String, Object?> sanitizeMap(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (blockedSensitiveKeys.contains(key)) {
        throw ArgumentError.value(
          key,
          'key',
          'Private expense content is not allowed in telemetry.',
        );
      }
      if (!allowedKeys.contains(key)) continue;
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }

  static Map<String, Object?> sanitizeMetadata(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (blockedSensitiveKeys.contains(key)) {
        throw ArgumentError.value(
          key,
          'metadata',
          'Private expense content is not allowed in telemetry.',
        );
      }
      if (!allowedMetadataKeys.contains(key)) continue;
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
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
    if (value is Map) {
      if (key == 'metadata') {
        return sanitizeMetadata(Map<String, Object?>.from(value));
      }
      return _sanitizeTokenMap(key, Map<String, Object?>.from(value));
    }
    if (value is Iterable) {
      return value
          .map((item) => _sanitizeToken(key, item.toString()))
          .toList(growable: false);
    }
    throw ArgumentError.value(value, key, 'Unsupported telemetry value.');
  }

  static Map<String, Object?> _sanitizeTokenMap(
    String parentKey,
    Map<String, Object?> source,
  ) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = _sanitizeToken(parentKey, entry.key);
      final value = entry.value;
      if (value is bool || value == null) {
        sanitized[key] = value;
      } else if (value is int) {
        if (value < 0) {
          throw ArgumentError.value(value, key, 'Counts must be non-negative.');
        }
        sanitized[key] = value;
      } else if (value is String) {
        sanitized[key] = _sanitizeToken(key, value);
      } else {
        throw ArgumentError.value(value, key, 'Unsupported telemetry value.');
      }
    }
    return Map.unmodifiable(sanitized);
  }

  static String _sanitizeToken(String key, String value) {
    final token = value.trim();
    if (token.isEmpty ||
        token.length > maxStringLength ||
        !_safeTokenPattern.hasMatch(token)) {
      throw ArgumentError.value(value, key, 'Unsafe telemetry token.');
    }
    return token;
  }
}

class ExpenseTelemetryRecord {
  const ExpenseTelemetryRecord({
    required this.id,
    required this.queuedAtUtc,
    required this.payload,
    this.uploadedAtUtc,
  });

  factory ExpenseTelemetryRecord.fromStored(Object? value) {
    if (value is! Map) return ExpenseTelemetryRecord.empty;
    try {
      final payload = value['payload'];
      return ExpenseTelemetryRecord(
        id: _stringValue(value['id']),
        queuedAtUtc:
            DateTime.tryParse(_stringValue(value['queuedAtUtc'])) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        uploadedAtUtc: DateTime.tryParse(_stringValue(value['uploadedAtUtc'])),
        payload: payload is Map
            ? ExpenseTelemetryPolicy.sanitizeMap(
                Map<String, Object?>.from(payload),
              )
            : const {},
      );
    } catch (_) {
      return ExpenseTelemetryRecord.empty;
    }
  }

  static final empty = ExpenseTelemetryRecord(
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
      'payload': ExpenseTelemetryPolicy.sanitizeMap(payload),
    };
  }
}

class ExpenseTelemetryHealthSnapshot {
  const ExpenseTelemetryHealthSnapshot({
    required this.generatedAtUtc,
    required this.totalEventCount,
    required this.pendingUploadCount,
    required this.uploadedEventCount,
    required this.eventCounts,
    required this.platformCounts,
    required this.deviceTierCounts,
    required this.storageModeCounts,
    required this.planStatusCounts,
    required this.connectionStatusCounts,
    required this.screenOpenCount,
    required this.timeSpentEventCount,
    required this.totalTimeSpentMs,
    required this.addExpenseStartedCount,
    required this.addExpenseCompletedCount,
    required this.addExpenseAbandonedCount,
    required this.validationErrorCount,
    required this.saveFailureCount,
    required this.imageAttachSuccessCount,
    required this.imageAttachFailureCount,
    required this.ocrStartedCount,
    required this.ocrCompletedCount,
    required this.ocrFailedCount,
    required this.parserStartedCount,
    required this.parserCompletedCount,
    required this.parserNeedsReviewCount,
    required this.parserFailedCount,
    required this.parserCategoryCounts,
    required this.parserNeedsReviewCategoryCounts,
    required this.parserFailedCategoryCounts,
    required this.parserFieldConfidenceCounts,
    required this.topParserCategory,
    required this.topParserNeedsReviewCategory,
    required this.topParserFailedCategory,
    required this.ocrCorrectionOpenedCount,
    required this.appFilledReceiptLineConfirmedCount,
    required this.appFilledReceiptLineCorrectedCount,
    required this.userCorrectionCount,
    required this.cloudBackupSuccessCount,
    required this.cloudBackupFailureCount,
    required this.syncPendingCount,
    required this.syncedCount,
    required this.syncFailedCount,
    required this.expenseSummaryQueuedCount,
    required this.expenseSummaryOcrContractQueuedCount,
    required this.expenseSummaryOcrContractSkippedCount,
    required this.expenseSummaryOcrContractSourceCounts,
    required this.topExpenseSummaryOcrContractSource,
    required this.expenseSummaryOcrContractSkippedReasonCounts,
    required this.topExpenseSummaryOcrContractSkippedReason,
    required this.exportStartedCount,
    required this.exportCompletedCount,
    required this.exportBlockedCount,
    required this.exportFailedCount,
    required this.ocrFailureCauseCounts,
    required this.topOcrFailureCause,
    required this.ocrFailureSourceCounts,
    required this.topOcrFailureSource,
    required this.ocrFailureStageCounts,
    required this.topOcrFailureStage,
    required this.failureBreakdowns,
    required this.recentFailureDetails,
  });

  factory ExpenseTelemetryHealthSnapshot.fromRecords(
    Iterable<ExpenseTelemetryRecord> records, {
    DateTime? generatedAtUtc,
  }) {
    final eventCounts = <String, int>{};
    final platformCounts = <String, int>{};
    final deviceTierCounts = <String, int>{};
    final storageModeCounts = <String, int>{};
    final planStatusCounts = <String, int>{};
    final connectionStatusCounts = <String, int>{};
    var pendingUploadCount = 0;
    var uploadedEventCount = 0;
    var screenOpenCount = 0;
    var timeSpentEventCount = 0;
    var totalTimeSpentMs = 0;
    var addExpenseStartedCount = 0;
    var addExpenseCompletedCount = 0;
    var addExpenseAbandonedCount = 0;
    var validationErrorCount = 0;
    var saveFailureCount = 0;
    var imageAttachSuccessCount = 0;
    var imageAttachFailureCount = 0;
    var ocrStartedCount = 0;
    var ocrCompletedCount = 0;
    var ocrFailedCount = 0;
    var parserStartedCount = 0;
    var parserCompletedCount = 0;
    var parserNeedsReviewCount = 0;
    var parserFailedCount = 0;
    final parserCategoryCounts = <String, int>{};
    final parserNeedsReviewCategoryCounts = <String, int>{};
    final parserFailedCategoryCounts = <String, int>{};
    final parserFieldConfidenceCounts = <String, int>{};
    var ocrCorrectionOpenedCount = 0;
    var appFilledReceiptLineConfirmedCount = 0;
    var appFilledReceiptLineCorrectedCount = 0;
    var userCorrectionCount = 0;
    var cloudBackupSuccessCount = 0;
    var cloudBackupFailureCount = 0;
    var syncPendingCount = 0;
    var syncedCount = 0;
    var syncFailedCount = 0;
    var expenseSummaryQueuedCount = 0;
    var expenseSummaryOcrContractQueuedCount = 0;
    var expenseSummaryOcrContractSkippedCount = 0;
    final expenseSummaryOcrContractSourceCounts = <String, int>{};
    final expenseSummaryOcrContractSkippedReasonCounts = <String, int>{};
    var exportStartedCount = 0;
    var exportCompletedCount = 0;
    var exportBlockedCount = 0;
    var exportFailedCount = 0;
    final failureStats = <String, _ExpenseFailureStats>{};
    final recentFailures = <ExpenseFailureEventDetail>[];

    for (final record in records) {
      final payload = ExpenseTelemetryPolicy.sanitizeMap(record.payload);
      if (record.isPendingUpload) {
        pendingUploadCount += 1;
      } else {
        uploadedEventCount += 1;
      }
      final event = _stringValue(payload['event']);
      _increment(eventCounts, event);
      _increment(platformCounts, _stringValue(payload['platform']));
      _increment(deviceTierCounts, _stringValue(payload['deviceTier']));
      _increment(storageModeCounts, _stringValue(payload['storageMode']));
      _increment(planStatusCounts, _stringValue(payload['planStatus']));
      _increment(
        connectionStatusCounts,
        _stringValue(payload['connectionStatus']),
      );

      switch (event) {
        case 'screenOpened':
          screenOpenCount += 1;
        case 'timeSpentOnScreen':
          timeSpentEventCount += 1;
          totalTimeSpentMs += _intValue(payload['durationMs']);
        case 'addExpenseStarted':
          addExpenseStartedCount += 1;
        case 'addExpenseCompleted':
          addExpenseCompletedCount += 1;
        case 'addExpenseAbandoned':
          addExpenseAbandonedCount += 1;
        case 'validationError':
          validationErrorCount += 1;
        case 'saveFailure':
          saveFailureCount += 1;
        case 'imageAttachSuccess':
          imageAttachSuccessCount += 1;
        case 'imageAttachFailure':
          imageAttachFailureCount += 1;
        case 'ocrStarted':
          ocrStartedCount += 1;
        case 'ocrCompleted':
          ocrCompletedCount += 1;
        case 'ocrFailed':
          ocrFailedCount += 1;
        case 'parserStarted':
          parserStartedCount += 1;
        case 'parserCompleted':
          parserCompletedCount += 1;
          final completedMetadata = _metadataValue(payload['metadata']);
          _mergeCountMap(
            parserCategoryCounts,
            _metadataValue(completedMetadata['parsedCategoryBuckets']),
          );
          _mergeCountMap(
            parserFieldConfidenceCounts,
            _metadataValue(completedMetadata['parserFieldConfidenceBuckets']),
          );
        case 'parserNeedsReview':
          parserNeedsReviewCount += 1;
          final reviewMetadata = _metadataValue(payload['metadata']);
          _mergeCountMap(
            parserCategoryCounts,
            _metadataValue(reviewMetadata['parsedCategoryBuckets']),
          );
          _mergeCountMap(
            parserNeedsReviewCategoryCounts,
            _metadataValue(reviewMetadata['reviewCategoryBuckets']),
          );
          _mergeCountMap(
            parserFieldConfidenceCounts,
            _metadataValue(reviewMetadata['parserFieldConfidenceBuckets']),
          );
        case 'parserFailed':
          parserFailedCount += 1;
          final failedMetadata = _metadataValue(payload['metadata']);
          _mergeCountMap(
            parserFailedCategoryCounts,
            _metadataValue(failedMetadata['parsedCategoryBuckets']),
          );
        case 'ocrCorrectionOpened':
          ocrCorrectionOpenedCount += 1;
        case 'appFilledReceiptLineConfirmed':
          appFilledReceiptLineConfirmedCount += 1;
        case 'appFilledReceiptLineCorrected':
          appFilledReceiptLineCorrectedCount += 1;
          userCorrectionCount += 1;
        case 'userCorrectedVendor':
        case 'userCorrectedDate':
        case 'userCorrectedTax':
        case 'userCorrectedTotal':
        case 'userCorrectedCategory':
          userCorrectionCount += 1;
        case 'cloudBackupSuccess':
          cloudBackupSuccessCount += 1;
        case 'cloudBackupFailure':
          cloudBackupFailureCount += 1;
        case 'syncPending':
          syncPendingCount += 1;
          final metadata = _metadataValue(payload['metadata']);
          if (_stringValue(metadata['syncState']) == 'expense_summary_queued') {
            expenseSummaryQueuedCount += 1;
            final source = _stringValue(metadata['ocrContractSource']);
            _increment(expenseSummaryOcrContractSourceCounts, source);
            if (_boolValue(metadata['ocrContractQueued'])) {
              expenseSummaryOcrContractQueuedCount += 1;
            } else {
              expenseSummaryOcrContractSkippedCount += 1;
              _increment(
                expenseSummaryOcrContractSkippedReasonCounts,
                _stringValue(metadata['ocrContractSkippedReason']),
              );
            }
          }
        case 'synced':
          syncedCount += 1;
        case 'syncFailed':
          syncFailedCount += 1;
        case 'exportStarted':
          exportStartedCount += 1;
        case 'exportCompleted':
          exportCompletedCount += 1;
        case 'exportBlocked':
          exportBlockedCount += 1;
        case 'exportFailed':
          exportFailedCount += 1;
      }
      _recordFailureDiagnostic(failureStats, payload);
      final failureDetail = _failureDetailFor(record, payload);
      if (failureDetail != null) recentFailures.add(failureDetail);
    }

    final failureBreakdowns =
        failureStats.values.map((stats) => stats.toBreakdown()).toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    final ocrFailureCauseCounts = <String, int>{};
    final ocrFailureSourceCounts = <String, int>{};
    final ocrFailureStageCounts = <String, int>{};
    for (final failure in failureBreakdowns) {
      if (failure.workflowStep != ExpenseWorkflowStep.receiptOcr.name) {
        continue;
      }
      ocrFailureCauseCounts[failure.confirmedCause] =
          (ocrFailureCauseCounts[failure.confirmedCause] ?? 0) + failure.count;
      final ocrSource = _ocrSourceFromEvidence(failure.evidence);
      ocrFailureSourceCounts[ocrSource] =
          (ocrFailureSourceCounts[ocrSource] ?? 0) + failure.count;
      ocrFailureStageCounts[failure.failedAt] =
          (ocrFailureStageCounts[failure.failedAt] ?? 0) + failure.count;
    }
    final topOcrFailureCause = _topCountKey(ocrFailureCauseCounts);
    final topOcrFailureSource = _topCountKey(ocrFailureSourceCounts);
    final topOcrFailureStage = _topCountKey(ocrFailureStageCounts);
    final topExpenseSummaryOcrContractSource = _topCountKey(
      expenseSummaryOcrContractSourceCounts,
    );
    final topExpenseSummaryOcrContractSkippedReason = _topCountKey(
      expenseSummaryOcrContractSkippedReasonCounts,
    );

    return ExpenseTelemetryHealthSnapshot(
      generatedAtUtc: (generatedAtUtc ?? DateTime.now().toUtc()).toUtc(),
      totalEventCount: records.length,
      pendingUploadCount: pendingUploadCount,
      uploadedEventCount: uploadedEventCount,
      eventCounts: Map.unmodifiable(eventCounts),
      platformCounts: Map.unmodifiable(platformCounts),
      deviceTierCounts: Map.unmodifiable(deviceTierCounts),
      storageModeCounts: Map.unmodifiable(storageModeCounts),
      planStatusCounts: Map.unmodifiable(planStatusCounts),
      connectionStatusCounts: Map.unmodifiable(connectionStatusCounts),
      screenOpenCount: screenOpenCount,
      timeSpentEventCount: timeSpentEventCount,
      totalTimeSpentMs: totalTimeSpentMs,
      addExpenseStartedCount: addExpenseStartedCount,
      addExpenseCompletedCount: addExpenseCompletedCount,
      addExpenseAbandonedCount: addExpenseAbandonedCount,
      validationErrorCount: validationErrorCount,
      saveFailureCount: saveFailureCount,
      imageAttachSuccessCount: imageAttachSuccessCount,
      imageAttachFailureCount: imageAttachFailureCount,
      ocrStartedCount: ocrStartedCount,
      ocrCompletedCount: ocrCompletedCount,
      ocrFailedCount: ocrFailedCount,
      parserStartedCount: parserStartedCount,
      parserCompletedCount: parserCompletedCount,
      parserNeedsReviewCount: parserNeedsReviewCount,
      parserFailedCount: parserFailedCount,
      parserCategoryCounts: Map.unmodifiable(parserCategoryCounts),
      parserNeedsReviewCategoryCounts: Map.unmodifiable(
        parserNeedsReviewCategoryCounts,
      ),
      parserFailedCategoryCounts: Map.unmodifiable(parserFailedCategoryCounts),
      parserFieldConfidenceCounts: Map.unmodifiable(
        parserFieldConfidenceCounts,
      ),
      topParserCategory: _topCountKey(parserCategoryCounts),
      topParserNeedsReviewCategory: _topCountKey(
        parserNeedsReviewCategoryCounts,
      ),
      topParserFailedCategory: _topCountKey(parserFailedCategoryCounts),
      ocrCorrectionOpenedCount: ocrCorrectionOpenedCount,
      appFilledReceiptLineConfirmedCount: appFilledReceiptLineConfirmedCount,
      appFilledReceiptLineCorrectedCount: appFilledReceiptLineCorrectedCount,
      userCorrectionCount: userCorrectionCount,
      cloudBackupSuccessCount: cloudBackupSuccessCount,
      cloudBackupFailureCount: cloudBackupFailureCount,
      syncPendingCount: syncPendingCount,
      syncedCount: syncedCount,
      syncFailedCount: syncFailedCount,
      expenseSummaryQueuedCount: expenseSummaryQueuedCount,
      expenseSummaryOcrContractQueuedCount:
          expenseSummaryOcrContractQueuedCount,
      expenseSummaryOcrContractSkippedCount:
          expenseSummaryOcrContractSkippedCount,
      expenseSummaryOcrContractSourceCounts: Map.unmodifiable(
        expenseSummaryOcrContractSourceCounts,
      ),
      topExpenseSummaryOcrContractSource: topExpenseSummaryOcrContractSource,
      expenseSummaryOcrContractSkippedReasonCounts: Map.unmodifiable(
        expenseSummaryOcrContractSkippedReasonCounts,
      ),
      topExpenseSummaryOcrContractSkippedReason:
          topExpenseSummaryOcrContractSkippedReason,
      exportStartedCount: exportStartedCount,
      exportCompletedCount: exportCompletedCount,
      exportBlockedCount: exportBlockedCount,
      exportFailedCount: exportFailedCount,
      ocrFailureCauseCounts: Map.unmodifiable(ocrFailureCauseCounts),
      topOcrFailureCause: topOcrFailureCause,
      ocrFailureSourceCounts: Map.unmodifiable(ocrFailureSourceCounts),
      topOcrFailureSource: topOcrFailureSource,
      ocrFailureStageCounts: Map.unmodifiable(ocrFailureStageCounts),
      topOcrFailureStage: topOcrFailureStage,
      failureBreakdowns: List.unmodifiable(failureBreakdowns),
      recentFailureDetails: List.unmodifiable(
        recentFailures.reversed.take(100).toList(growable: false),
      ),
    );
  }

  final DateTime generatedAtUtc;
  final int totalEventCount;
  final int pendingUploadCount;
  final int uploadedEventCount;
  final Map<String, int> eventCounts;
  final Map<String, int> platformCounts;
  final Map<String, int> deviceTierCounts;
  final Map<String, int> storageModeCounts;
  final Map<String, int> planStatusCounts;
  final Map<String, int> connectionStatusCounts;
  final int screenOpenCount;
  final int timeSpentEventCount;
  final int totalTimeSpentMs;
  final int addExpenseStartedCount;
  final int addExpenseCompletedCount;
  final int addExpenseAbandonedCount;
  final int validationErrorCount;
  final int saveFailureCount;
  final int imageAttachSuccessCount;
  final int imageAttachFailureCount;
  final int ocrStartedCount;
  final int ocrCompletedCount;
  final int ocrFailedCount;
  final int parserStartedCount;
  final int parserCompletedCount;
  final int parserNeedsReviewCount;
  final int parserFailedCount;
  final Map<String, int> parserCategoryCounts;
  final Map<String, int> parserNeedsReviewCategoryCounts;
  final Map<String, int> parserFailedCategoryCounts;
  final Map<String, int> parserFieldConfidenceCounts;
  final String topParserCategory;
  final String topParserNeedsReviewCategory;
  final String topParserFailedCategory;
  final int ocrCorrectionOpenedCount;
  final int appFilledReceiptLineConfirmedCount;
  final int appFilledReceiptLineCorrectedCount;
  final int userCorrectionCount;
  final int cloudBackupSuccessCount;
  final int cloudBackupFailureCount;
  final int syncPendingCount;
  final int syncedCount;
  final int syncFailedCount;
  final int expenseSummaryQueuedCount;
  final int expenseSummaryOcrContractQueuedCount;
  final int expenseSummaryOcrContractSkippedCount;
  final Map<String, int> expenseSummaryOcrContractSourceCounts;
  final String topExpenseSummaryOcrContractSource;
  final Map<String, int> expenseSummaryOcrContractSkippedReasonCounts;
  final String topExpenseSummaryOcrContractSkippedReason;
  final int exportStartedCount;
  final int exportCompletedCount;
  final int exportBlockedCount;
  final int exportFailedCount;
  final Map<String, int> ocrFailureCauseCounts;
  final String topOcrFailureCause;
  final Map<String, int> ocrFailureSourceCounts;
  final String topOcrFailureSource;
  final Map<String, int> ocrFailureStageCounts;
  final String topOcrFailureStage;
  final List<ExpenseFailureBreakdown> failureBreakdowns;
  final List<ExpenseFailureEventDetail> recentFailureDetails;

  double get averageTimeSpentSeconds {
    if (timeSpentEventCount == 0) return 0;
    return (totalTimeSpentMs / timeSpentEventCount) / 1000;
  }

  double get addExpenseCompletionRate {
    if (addExpenseStartedCount == 0) return 0;
    return addExpenseCompletedCount / addExpenseStartedCount;
  }

  double get addExpenseAbandonmentRate {
    if (addExpenseStartedCount == 0) return 0;
    return addExpenseAbandonedCount / addExpenseStartedCount;
  }

  double get imageAttachFailureRate {
    final total = imageAttachSuccessCount + imageAttachFailureCount;
    if (total == 0) return 0;
    return imageAttachFailureCount / total;
  }

  double get ocrSuccessRate {
    if (ocrStartedCount == 0) return 0;
    return ocrCompletedCount / ocrStartedCount;
  }

  double get parserSuccessRate {
    if (parserStartedCount == 0) return 0;
    return parserCompletedCount / parserStartedCount;
  }

  double get parserReviewRate {
    if (parserStartedCount == 0) return 0;
    return parserNeedsReviewCount / parserStartedCount;
  }

  double get parserFailureRate {
    if (parserStartedCount == 0) return 0;
    return parserFailedCount / parserStartedCount;
  }

  double get appFilledReceiptLineCorrectionRate {
    final total =
        appFilledReceiptLineConfirmedCount + appFilledReceiptLineCorrectedCount;
    if (total == 0) return 0;
    return appFilledReceiptLineCorrectedCount / total;
  }

  double get cloudBackupFailureRate {
    final total = cloudBackupSuccessCount + cloudBackupFailureCount;
    if (total == 0) return 0;
    return cloudBackupFailureCount / total;
  }

  double get syncFailureRate {
    final total = syncedCount + syncFailedCount;
    if (total == 0) return 0;
    return syncFailedCount / total;
  }

  double get exportCompletionRate {
    if (exportStartedCount == 0) return 0;
    return exportCompletedCount / exportStartedCount;
  }

  double get exportFailureRate {
    final totalAttempts = exportStartedCount + exportBlockedCount;
    if (totalAttempts == 0) return 0;
    return (exportFailedCount + exportBlockedCount) / totalAttempts;
  }

  bool get needsAttention {
    return saveFailureCount > 0 ||
        validationErrorCount > 0 ||
        addExpenseAbandonmentRate >= .25 ||
        imageAttachFailureRate >= .1 ||
        ocrSuccessRate < .9 && ocrStartedCount > 0 ||
        parserFailureRate >= .05 && parserStartedCount > 0 ||
        parserReviewRate >= .25 && parserStartedCount > 0 ||
        cloudBackupFailureRate >= .1 ||
        syncFailureRate >= .1 ||
        exportFailureRate >= .1 && exportStartedCount > 0;
  }

  String get healthLabel {
    if (totalEventCount == 0) return 'no_data';
    if (saveFailureCount > 0 || syncFailureRate >= .2) {
      return 'needs_attention';
    }
    if (needsAttention) return 'review';
    return 'healthy';
  }

  Map<String, Object?> toCommandCenterMap() {
    return {
      'schema': 'expense_screen_telemetry_health_v1',
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'healthLabel': healthLabel,
      'totalEventCount': totalEventCount,
      'pendingUploadCount': pendingUploadCount,
      'uploadedEventCount': uploadedEventCount,
      'eventCounts': eventCounts,
      'platformCounts': platformCounts,
      'deviceTierCounts': deviceTierCounts,
      'storageModeCounts': storageModeCounts,
      'planStatusCounts': planStatusCounts,
      'connectionStatusCounts': connectionStatusCounts,
      'screenOpenCount': screenOpenCount,
      'averageTimeSpentSeconds': averageTimeSpentSeconds,
      'addExpenseStartedCount': addExpenseStartedCount,
      'addExpenseCompletedCount': addExpenseCompletedCount,
      'addExpenseAbandonedCount': addExpenseAbandonedCount,
      'addExpenseCompletionRate': addExpenseCompletionRate,
      'addExpenseAbandonmentRate': addExpenseAbandonmentRate,
      'validationErrorCount': validationErrorCount,
      'saveFailureCount': saveFailureCount,
      'imageAttachSuccessCount': imageAttachSuccessCount,
      'imageAttachFailureCount': imageAttachFailureCount,
      'imageAttachFailureRate': imageAttachFailureRate,
      'ocrStartedCount': ocrStartedCount,
      'ocrCompletedCount': ocrCompletedCount,
      'ocrFailedCount': ocrFailedCount,
      'ocrSuccessRate': ocrSuccessRate,
      'parserStartedCount': parserStartedCount,
      'parserCompletedCount': parserCompletedCount,
      'parserNeedsReviewCount': parserNeedsReviewCount,
      'parserFailedCount': parserFailedCount,
      'parserSuccessRate': parserSuccessRate,
      'parserReviewRate': parserReviewRate,
      'parserFailureRate': parserFailureRate,
      'parserCategoryCounts': parserCategoryCounts,
      'parserNeedsReviewCategoryCounts': parserNeedsReviewCategoryCounts,
      'parserFailedCategoryCounts': parserFailedCategoryCounts,
      'parserFieldConfidenceCounts': parserFieldConfidenceCounts,
      'topParserCategory': topParserCategory,
      'topParserNeedsReviewCategory': topParserNeedsReviewCategory,
      'topParserFailedCategory': topParserFailedCategory,
      'ocrCorrectionOpenedCount': ocrCorrectionOpenedCount,
      'appFilledReceiptLineConfirmedCount': appFilledReceiptLineConfirmedCount,
      'appFilledReceiptLineCorrectedCount': appFilledReceiptLineCorrectedCount,
      'appFilledReceiptLineCorrectionRate': appFilledReceiptLineCorrectionRate,
      'userCorrectionCount': userCorrectionCount,
      'cloudBackupSuccessCount': cloudBackupSuccessCount,
      'cloudBackupFailureCount': cloudBackupFailureCount,
      'cloudBackupFailureRate': cloudBackupFailureRate,
      'syncPendingCount': syncPendingCount,
      'syncedCount': syncedCount,
      'syncFailedCount': syncFailedCount,
      'syncFailureRate': syncFailureRate,
      'expenseSummaryQueuedCount': expenseSummaryQueuedCount,
      'expenseSummaryOcrContractQueuedCount':
          expenseSummaryOcrContractQueuedCount,
      'expenseSummaryOcrContractSkippedCount':
          expenseSummaryOcrContractSkippedCount,
      'expenseSummaryOcrContractSourceCounts':
          expenseSummaryOcrContractSourceCounts,
      if (topExpenseSummaryOcrContractSource.isNotEmpty)
        'topExpenseSummaryOcrContractSource':
            topExpenseSummaryOcrContractSource,
      'expenseSummaryOcrContractSkippedReasonCounts':
          expenseSummaryOcrContractSkippedReasonCounts,
      if (topExpenseSummaryOcrContractSkippedReason.isNotEmpty)
        'topExpenseSummaryOcrContractSkippedReason':
            topExpenseSummaryOcrContractSkippedReason,
      'exportStartedCount': exportStartedCount,
      'exportCompletedCount': exportCompletedCount,
      'exportBlockedCount': exportBlockedCount,
      'exportFailedCount': exportFailedCount,
      'exportCompletionRate': exportCompletionRate,
      'exportFailureRate': exportFailureRate,
      'ocrFailureCauseCounts': ocrFailureCauseCounts,
      if (topOcrFailureCause.isNotEmpty)
        'topOcrFailureCause': topOcrFailureCause,
      'ocrFailureSourceCounts': ocrFailureSourceCounts,
      if (topOcrFailureSource.isNotEmpty)
        'topOcrFailureSource': topOcrFailureSource,
      if (topOcrFailureSource.isNotEmpty)
        'topOcrFailureSourceAction': _recommendedOcrSourceAction(
          topOcrFailureSource,
        ),
      'ocrFailureStageCounts': ocrFailureStageCounts,
      if (topOcrFailureStage.isNotEmpty)
        'topOcrFailureStage': topOcrFailureStage,
      if (topOcrFailureStage.isNotEmpty)
        'topOcrFailureStageLabel': _safeDiagnosticLabel(topOcrFailureStage),
      'failureBreakdowns': [
        for (final failure in failureBreakdowns) failure.toMap(),
      ],
      'recentFailureDetails': [
        for (final failure in recentFailureDetails) failure.toMap(),
      ],
    };
  }
}

class ExpenseFailureBreakdown {
  const ExpenseFailureBreakdown({
    required this.featureArea,
    required this.featureLabel,
    required this.workflowStep,
    required this.workflowStepLabel,
    required this.failedAt,
    required this.failedAtLabel,
    required this.confirmedCause,
    required this.causeLabel,
    required this.causeStatus,
    required this.causeStatusLabel,
    required this.evidence,
    required this.evidenceLabel,
    required this.missingEvidence,
    required this.missingEvidenceLabel,
    required this.recommendedAction,
    required this.actionSummary,
    required this.ocrFailureSource,
    required this.ocrFailureSourceAction,
    required this.count,
    required this.retryCount,
    required this.abandonedCount,
    required this.platformCounts,
    required this.deviceTierCounts,
    required this.appVersionCounts,
  });

  final String featureArea;
  final String featureLabel;
  final String workflowStep;
  final String workflowStepLabel;
  final String failedAt;
  final String failedAtLabel;
  final String confirmedCause;
  final String causeLabel;
  final String causeStatus;
  final String causeStatusLabel;
  final String evidence;
  final String evidenceLabel;
  final String missingEvidence;
  final String missingEvidenceLabel;
  final String recommendedAction;
  final String actionSummary;
  final String ocrFailureSource;
  final String ocrFailureSourceAction;
  final int count;
  final int retryCount;
  final int abandonedCount;
  final Map<String, int> platformCounts;
  final Map<String, int> deviceTierCounts;
  final Map<String, int> appVersionCounts;

  Map<String, Object?> toMap() {
    return {
      'featureArea': featureArea,
      'featureLabel': featureLabel,
      'workflowStep': workflowStep,
      'workflowStepLabel': workflowStepLabel,
      'failedAt': failedAt,
      'failedAtLabel': failedAtLabel,
      'confirmedCause': confirmedCause,
      'causeLabel': causeLabel,
      'causeStatus': causeStatus,
      'causeStatusLabel': causeStatusLabel,
      'evidence': evidence,
      'evidenceLabel': evidenceLabel,
      'missingEvidence': missingEvidence,
      'missingEvidenceLabel': missingEvidenceLabel,
      'recommendedAction': recommendedAction,
      'actionSummary': actionSummary,
      'ocrFailureSource': ocrFailureSource,
      'ocrFailureSourceAction': ocrFailureSourceAction,
      'count': count,
      'retryCount': retryCount,
      'abandonedCount': abandonedCount,
      'platformCounts': platformCounts,
      'deviceTierCounts': deviceTierCounts,
      'appVersionCounts': appVersionCounts,
    };
  }
}

class ExpenseFailureEventDetail {
  const ExpenseFailureEventDetail({
    required this.eventId,
    required this.queuedAtUtc,
    required this.event,
    required this.featureArea,
    required this.featureLabel,
    required this.workflowStep,
    required this.workflowStepLabel,
    required this.failedAt,
    required this.failedAtLabel,
    required this.confirmedCause,
    required this.causeLabel,
    required this.causeStatus,
    required this.causeStatusLabel,
    required this.evidence,
    required this.evidenceLabel,
    required this.missingEvidence,
    required this.missingEvidenceLabel,
    required this.recommendedAction,
    required this.actionSummary,
    required this.ocrFailureSource,
    required this.ocrFailureSourceAction,
    required this.retryCount,
    required this.abandoned,
    required this.platform,
    required this.deviceTier,
    required this.appVersion,
  });

  final String eventId;
  final DateTime queuedAtUtc;
  final String event;
  final String featureArea;
  final String featureLabel;
  final String workflowStep;
  final String workflowStepLabel;
  final String failedAt;
  final String failedAtLabel;
  final String confirmedCause;
  final String causeLabel;
  final String causeStatus;
  final String causeStatusLabel;
  final String evidence;
  final String evidenceLabel;
  final String missingEvidence;
  final String missingEvidenceLabel;
  final String recommendedAction;
  final String actionSummary;
  final String ocrFailureSource;
  final String ocrFailureSourceAction;
  final int retryCount;
  final bool abandoned;
  final String platform;
  final String deviceTier;
  final String appVersion;

  Map<String, Object?> toMap() {
    return {
      'eventId': eventId,
      'queuedAtUtc': queuedAtUtc.toUtc().toIso8601String(),
      'event': event,
      'featureArea': featureArea,
      'featureLabel': featureLabel,
      'workflowStep': workflowStep,
      'workflowStepLabel': workflowStepLabel,
      'failedAt': failedAt,
      'failedAtLabel': failedAtLabel,
      'confirmedCause': confirmedCause,
      'causeLabel': causeLabel,
      'causeStatus': causeStatus,
      'causeStatusLabel': causeStatusLabel,
      'evidence': evidence,
      'evidenceLabel': evidenceLabel,
      'missingEvidence': missingEvidence,
      'missingEvidenceLabel': missingEvidenceLabel,
      'recommendedAction': recommendedAction,
      'actionSummary': actionSummary,
      'ocrFailureSource': ocrFailureSource,
      'ocrFailureSourceAction': ocrFailureSourceAction,
      'retryCount': retryCount,
      'abandoned': abandoned,
      'platform': platform,
      'deviceTier': deviceTier,
      'appVersion': appVersion,
    };
  }
}

class _ExpenseFailureStats {
  _ExpenseFailureStats({
    required this.workflowStep,
    required this.failedAt,
    required this.confirmedCause,
    required this.causeStatus,
    required this.evidence,
    required this.missingEvidence,
  });

  final String workflowStep;
  final String failedAt;
  final String confirmedCause;
  final String causeStatus;
  final String evidence;
  final String missingEvidence;
  int count = 0;
  int retryCount = 0;
  int abandonedCount = 0;
  final platformCounts = <String, int>{};
  final deviceTierCounts = <String, int>{};
  final appVersionCounts = <String, int>{};

  void add(Map<String, Object?> payload) {
    count += 1;
    retryCount += _intValue(payload['retryCount']);
    if (payload['abandoned'] == true) abandonedCount += 1;
    _increment(platformCounts, _stringValue(payload['platform']));
    _increment(deviceTierCounts, _stringValue(payload['deviceTier']));
    _increment(appVersionCounts, _stringValue(payload['appVersion']));
  }

  ExpenseFailureBreakdown toBreakdown() {
    final ocrFailureSource = _ocrFailureSourceFor(
      workflowStep: workflowStep,
      evidence: evidence,
    );
    final recommendedAction = _recommendedActionFor(
      workflowStep: workflowStep,
      confirmedCause: confirmedCause,
      causeStatus: causeStatus,
      missingEvidence: missingEvidence,
    );
    return ExpenseFailureBreakdown(
      featureArea: 'expenses',
      featureLabel: 'Expenses',
      workflowStep: workflowStep,
      workflowStepLabel: _humanizeToken(workflowStep),
      failedAt: failedAt,
      failedAtLabel: _safeDiagnosticLabel(failedAt),
      confirmedCause: confirmedCause,
      causeLabel: _safeDiagnosticLabel(confirmedCause),
      causeStatus: causeStatus,
      causeStatusLabel: _causeStatusLabel(causeStatus),
      evidence: evidence,
      evidenceLabel: _evidenceLabel(evidence),
      missingEvidence: missingEvidence,
      missingEvidenceLabel: _missingEvidenceLabel(missingEvidence),
      recommendedAction: recommendedAction,
      actionSummary: _failureActionSummary(
        workflowStep: workflowStep,
        confirmedCause: confirmedCause,
        causeStatus: causeStatus,
        missingEvidence: missingEvidence,
        recommendedAction: recommendedAction,
        ocrFailureSource: ocrFailureSource,
      ),
      ocrFailureSource: ocrFailureSource,
      ocrFailureSourceAction: _recommendedOcrSourceAction(ocrFailureSource),
      count: count,
      retryCount: retryCount,
      abandonedCount: abandonedCount,
      platformCounts: Map.unmodifiable(platformCounts),
      deviceTierCounts: Map.unmodifiable(deviceTierCounts),
      appVersionCounts: Map.unmodifiable(appVersionCounts),
    );
  }
}

class ExpenseTelemetryStore {
  ExpenseTelemetryStore._(this._box);

  static const boxName = 'expense_screen_telemetry_events';
  static const maxStoredEvents = 500;

  final Box<dynamic> _box;

  static Future<ExpenseTelemetryStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseTelemetryStore._(box);
  }

  List<ExpenseTelemetryRecord> get records {
    final loaded = <ExpenseTelemetryRecord>[];
    for (final value in _box.values) {
      final record = ExpenseTelemetryRecord.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  List<ExpenseTelemetryRecord> get pendingUploadRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  ExpenseTelemetryHealthSnapshot buildHealthSnapshot({DateTime? nowUtc}) {
    return ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: nowUtc,
    );
  }

  Future<ExpenseTelemetryRecord> enqueue(
    ExpenseTelemetryEvent event, {
    DateTime? queuedAtUtc,
  }) async {
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = ExpenseTelemetryRecord(
      id: _eventIdFor(queuedAt),
      queuedAtUtc: queuedAt,
      payload: ExpenseTelemetryPolicy.sanitize(event),
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
          'payload': ExpenseTelemetryPolicy.sanitizeMap(record.payload),
        }),
    ];
  }

  Future<void> markUploaded(
    Iterable<String> eventIds, {
    DateTime? nowUtc,
  }) async {
    final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final id in eventIds) {
      final record = ExpenseTelemetryRecord.fromStored(_box.get(id));
      if (record.isEmpty) continue;
      await _box.put(
        id,
        ExpenseTelemetryRecord(
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

String _safeToken(String value, {String fallback = 'unknown'}) {
  final safe = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return fallback;
  return safe.length > ExpenseTelemetryPolicy.maxStringLength
      ? safe.substring(0, ExpenseTelemetryPolicy.maxStringLength)
      : safe;
}

void _increment(Map<String, int> counts, String value) {
  if (value.isEmpty) return;
  counts[value] = (counts[value] ?? 0) + 1;
}

void _mergeCountMap(Map<String, int> target, Map<String, Object?> source) {
  for (final entry in source.entries) {
    final key = _safeToken(entry.key, fallback: '');
    if (key.isEmpty) continue;
    final count = _intValue(entry.value);
    if (count <= 0) continue;
    target[key] = (target[key] ?? 0) + count;
  }
}

String _topCountKey(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final entries = counts.entries.toList()
    ..sort((left, right) {
      final count = right.value.compareTo(left.value);
      if (count != 0) return count;
      return left.key.compareTo(right.key);
    });
  return entries.first.key;
}

String _ocrSourceFromEvidence(String evidence) {
  final safeEvidence = _safeToken(evidence, fallback: 'unknown');
  if (RegExp(
    r'(?:^|_)source_(?:photo|camera|image|capture)(?:_|$)',
  ).hasMatch(safeEvidence)) {
    return 'photo';
  }
  if (RegExp(r'(?:^|_)source_(?:pdf|document)(?:_|$)').hasMatch(safeEvidence)) {
    return 'pdf';
  }
  if (RegExp(
    r'(?:^|_)source_(?:importedtext|imported_text|text|pastedtext|pasted_text)(?:_|$)',
  ).hasMatch(safeEvidence)) {
    return 'importedtext';
  }
  if (RegExp(
    r'(?:^|_)source_(?:mixed|combined|multiple)(?:_|$)',
  ).hasMatch(safeEvidence)) {
    return 'mixed';
  }
  if (RegExp(r'(?:^|_)source_(?:none|missing)(?:_|$)').hasMatch(safeEvidence)) {
    return 'none';
  }
  return 'unknown';
}

String _ocrFailureSourceFor({
  required String workflowStep,
  required String evidence,
}) {
  if (workflowStep != ExpenseWorkflowStep.receiptOcr.name) return 'not_ocr';
  return _ocrSourceFromEvidence(evidence);
}

String _recommendedOcrSourceAction(String source) {
  return switch (source) {
    'photo' =>
      'Investigate receipt camera focus, exposure, crop coverage, long-receipt section order, and image decode failures.',
    'pdf' =>
      'Investigate PDF safety checks, file size limits, render failures, page extraction, and PDF-to-image conversion.',
    'importedtext' || 'text' =>
      'Investigate pasted/imported receipt text cleanup and whether the text source was empty or malformed.',
    'mixed' =>
      'Investigate mixed receipt sources, section order, duplicate text suppression, stitched-photo fallback, and whether the cleanest source was selected.',
    'none' =>
      'Investigate why OCR started without a usable receipt photo, PDF, or pasted text source.',
    'not_ocr' =>
      'Use the failure workflow, confirmed cause, evidence summary, and recommended action for this non-OCR failure; do not treat it as a receipt camera/PDF OCR source problem.',
    'unknown' =>
      'Investigate source tagging in OCR diagnostics; keep the raw receipt private and add a safe source bucket when the failure path is identified.',
    _ =>
      'Inspect OCR diagnostics evidence and add a source-specific action once this source is identified.',
  };
}

String _failureActionSummary({
  required String workflowStep,
  required String confirmedCause,
  required String causeStatus,
  required String missingEvidence,
  required String recommendedAction,
  required String ocrFailureSource,
}) {
  final workflow = _humanizeToken(workflowStep);
  final cause = _compactReadableText(
    _privacySafeFailurePhrase(confirmedCause),
    52,
  );
  if (causeStatus != ExpenseFailureCauseStatus.confirmed.name) {
    final missing = _compactReadableText(
      _privacySafeFailurePhrase(missingEvidence),
      72,
    );
    return '$workflow failed, but the cause is not confirmed yet. Capture $missing before deciding what to fix next.';
  }
  final sourceContext = switch (ocrFailureSource) {
    'photo' => 'photo capture or image readability',
    'pdf' => 'PDF safety, size, rendering, or page extraction',
    'importedtext' || 'text' => 'imported receipt text cleanup',
    'mixed' => 'mixed receipt source order or duplicate suppression',
    'none' => 'missing receipt proof',
    'not_ocr' => 'the failed workflow, not OCR',
    'unknown' => 'safe OCR source tagging',
    _ => 'the recorded workflow evidence',
  };
  final firstSentence = recommendedAction.split(RegExp(r'[.!?]')).first.trim();
  final nextStep = firstSentence.isEmpty
      ? 'Use the recommended action for this failure.'
      : _compactReadableText(firstSentence, 72);
  return '$workflow failed from $cause. Check $sourceContext. $nextStep.';
}

void _recordFailureDiagnostic(
  Map<String, _ExpenseFailureStats> stats,
  Map<String, Object?> payload,
) {
  final event = _stringValue(payload['event']);
  if (!_isFailureEvent(event)) return;

  final resolved = _resolvedFailureFor(event: event, payload: payload);

  final key = [
    resolved.workflowStep,
    resolved.failedAt,
    resolved.confirmedCause,
    resolved.causeStatus,
  ].join('|');
  final entry = stats.putIfAbsent(
    key,
    () => _ExpenseFailureStats(
      workflowStep: resolved.workflowStep,
      failedAt: resolved.failedAt,
      confirmedCause: resolved.confirmedCause,
      causeStatus: resolved.causeStatus,
      evidence: resolved.evidence,
      missingEvidence: resolved.missingEvidence,
    ),
  );
  entry.add(payload);
}

ExpenseFailureEventDetail? _failureDetailFor(
  ExpenseTelemetryRecord record,
  Map<String, Object?> payload,
) {
  final event = _stringValue(payload['event']);
  if (!_isFailureEvent(event)) return null;
  final resolved = _resolvedFailureFor(event: event, payload: payload);
  final ocrFailureSource = _ocrFailureSourceFor(
    workflowStep: resolved.workflowStep,
    evidence: resolved.evidence,
  );
  final recommendedAction = _recommendedActionFor(
    workflowStep: resolved.workflowStep,
    confirmedCause: resolved.confirmedCause,
    causeStatus: resolved.causeStatus,
    missingEvidence: resolved.missingEvidence,
  );
  return ExpenseFailureEventDetail(
    eventId: record.id,
    queuedAtUtc: record.queuedAtUtc,
    event: event,
    featureArea: 'expenses',
    featureLabel: 'Expenses',
    workflowStep: resolved.workflowStep,
    workflowStepLabel: _humanizeToken(resolved.workflowStep),
    failedAt: resolved.failedAt,
    failedAtLabel: _safeDiagnosticLabel(resolved.failedAt),
    confirmedCause: resolved.confirmedCause,
    causeLabel: _safeDiagnosticLabel(resolved.confirmedCause),
    causeStatus: resolved.causeStatus,
    causeStatusLabel: _causeStatusLabel(resolved.causeStatus),
    evidence: resolved.evidence,
    evidenceLabel: _evidenceLabel(resolved.evidence),
    missingEvidence: resolved.missingEvidence,
    missingEvidenceLabel: _missingEvidenceLabel(resolved.missingEvidence),
    recommendedAction: recommendedAction,
    actionSummary: _failureActionSummary(
      workflowStep: resolved.workflowStep,
      confirmedCause: resolved.confirmedCause,
      causeStatus: resolved.causeStatus,
      missingEvidence: resolved.missingEvidence,
      recommendedAction: recommendedAction,
      ocrFailureSource: ocrFailureSource,
    ),
    ocrFailureSource: ocrFailureSource,
    ocrFailureSourceAction: _recommendedOcrSourceAction(ocrFailureSource),
    retryCount: _intValue(payload['retryCount']),
    abandoned: payload['abandoned'] == true,
    platform: _stringValue(payload['platform']),
    deviceTier: _stringValue(payload['deviceTier']),
    appVersion: _stringValue(payload['appVersion']),
  );
}

bool _isFailureEvent(String event) {
  return event.endsWith('Failed') ||
      event == 'saveFailure' ||
      event == 'validationError' ||
      event == 'addExpenseAbandoned' ||
      event == 'imageAttachFailure' ||
      event == 'parserNeedsReview' ||
      event == 'cloudBackupFailure' ||
      event == 'syncFailed' ||
      event == 'exportBlocked' ||
      event == 'exportFailed';
}

_ResolvedExpenseFailure _resolvedFailureFor({
  required String event,
  required Map<String, Object?> payload,
}) {
  final workflowStep = _stringValue(payload['workflowStep']);
  final failureKind = _stringValue(payload['failureKind']);
  final validationKind = _stringValue(payload['validationErrorKind']);
  final failedAt = _stringValue(payload['failedAt']);
  final confirmedCause = _stringValue(payload['confirmedCause']);
  final causeStatus = _stringValue(payload['causeStatus']);
  final evidence = _stringValue(payload['evidence']);
  final missingEvidence = _stringValue(payload['missingEvidence']);

  final fallbackCause = failureKind.isNotEmpty
      ? failureKind
      : validationKind.isNotEmpty
      ? validationKind
      : event;
  final resolvedCause = confirmedCause.isNotEmpty
      ? confirmedCause
      : 'cause_not_confirmed_$fallbackCause';
  final resolvedStatus = causeStatus.isNotEmpty
      ? causeStatus
      : ExpenseFailureCauseStatus.notConfirmed.name;
  return _ResolvedExpenseFailure(
    workflowStep: workflowStep.isNotEmpty
        ? workflowStep
        : _fallbackWorkflowStepFor(event),
    failedAt: failedAt.isNotEmpty ? failedAt : _fallbackFailedAtFor(event),
    confirmedCause: resolvedCause,
    causeStatus: resolvedStatus,
    evidence: evidence.isNotEmpty ? evidence : 'event_$event',
    missingEvidence: missingEvidence.isNotEmpty
        ? missingEvidence
        : resolvedStatus == ExpenseFailureCauseStatus.confirmed.name
        ? 'none'
        : 'diagnostic_context',
  );
}

class _ResolvedExpenseFailure {
  const _ResolvedExpenseFailure({
    required this.workflowStep,
    required this.failedAt,
    required this.confirmedCause,
    required this.causeStatus,
    required this.evidence,
    required this.missingEvidence,
  });

  final String workflowStep;
  final String failedAt;
  final String confirmedCause;
  final String causeStatus;
  final String evidence;
  final String missingEvidence;
}

String _humanizeToken(String value) {
  final clean = value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .trim();
  if (clean.isEmpty) return 'Unknown';
  final words = clean.split(RegExp(r'\s+'));
  return words
      .asMap()
      .entries
      .map((entry) {
        final lower = entry.value.toLowerCase();
        if (lower == 'ocr') return 'OCR';
        if (lower == 'pdf') return 'PDF';
        if (lower == 'hive') return 'Hive';
        if (entry.key == 0) {
          return entry.value[0].toUpperCase() + entry.value.substring(1);
        }
        return lower;
      })
      .join(' ');
}

String _causeStatusLabel(String status) {
  return status == ExpenseFailureCauseStatus.confirmed.name
      ? 'Confirmed cause'
      : 'Cause not confirmed';
}

String _missingEvidenceLabel(String missingEvidence) {
  if (missingEvidence == 'none') return 'No missing evidence';
  return 'Missing evidence: ${_compactReadableText(_privacySafeFailurePhrase(missingEvidence), 96)}';
}

String _evidenceLabel(String evidence) {
  return _compactReadableText(_privacySafeFailurePhrase(evidence), 96);
}

String _safeDiagnosticLabel(String value) {
  final safePhrase = _compactReadableText(_privacySafeFailurePhrase(value), 96);
  return _displayKnownAcronyms(safePhrase);
}

String _recommendedActionFor({
  required String workflowStep,
  required String confirmedCause,
  required String causeStatus,
  required String missingEvidence,
}) {
  if (causeStatus != ExpenseFailureCauseStatus.confirmed.name) {
    return 'Collect ${_privacySafeFailurePhrase(missingEvidence)} so the app can confirm the cause.';
  }
  final causeAction = switch (confirmedCause) {
    'receipt_photo_quality_needs_review' =>
      'Have the user retake the receipt with better focus, lighting, and full-page coverage before trusting OCR.',
    'receipt_photo_read_failed' =>
      'Check photo file access and image decoding, then ask for a retake or manual entry if the file is damaged.',
    'pdf_safety_blocked' =>
      'Keep the PDF as proof only, block text extraction, and ask for a safe copy or receipt photo.',
    'pdf_too_large' =>
      'Ask for fewer PDF pages, a smaller file, or receipt photos split into readable sections.',
    'pdf_unreadable' || 'pdf_read_failed' =>
      'Check PDF rendering and file validity, then ask for a readable PDF, receipt photo, or pasted text.',
    'ocr_plugin_unavailable' =>
      'Confirm the OCR plugin is bundled for this build and route the user to manual entry until it is available.',
    'receipt_source_skipped' =>
      'Check device capability limits and whether the skipped attachment was saved as proof only.',
    'possible_missing_receipt_section' =>
      'Ask the user to add the missing middle receipt section, then verify line order from top to bottom before saving.',
    'receipt_photo_overlap' =>
      'Review the stitch overlap area and adjust duplicate suppression so charges are not missed or counted twice.',
    'duplicate_receipt_text' =>
      'Review duplicate suppression for the overlap area so repeated long-receipt sections do not create duplicate charges.',
    'missing_receipt_attachment' =>
      'Ask the user to attach a receipt photo, PDF, or pasted receipt text before starting OCR.',
    'no_readable_text' =>
      'Check whether the attachment was blank, cropped, dark, or not a receipt, then ask for another section or manual entry.',
    'ocr_unknown_failure' =>
      'Open the OCR warning diagnostics, capture the warning kind, source, and device tier, then add a specific detector for this failure.',
    'receipt_parser_no_usable_fields' =>
      'Review OCR text quality and parser rules because no safe merchant, date, total, or line data could be filled.',
    'receipt_line_total_mismatch' =>
      'Add this receipt shape to parser tests and inspect missing, duplicated, return, discount, fee, or skipped long-receipt lines.',
    'receipt_subtotal_tax_total_mismatch' =>
      'Inspect subtotal, tax, fees, discounts, and total extraction before allowing the parsed totals to be trusted.',
    'receipt_totals_only_no_line_items' =>
      'Keep the receipt reviewable, but improve line detection for this vendor or device tier before expecting item-level detail.',
    'receipt_total_missing' =>
      'Inspect total-label detection and receipt bottom-section coverage; long receipts may be missing their final photo/PDF page.',
    'receipt_date_missing' =>
      'Inspect date-format parsing for this vendor and region.',
    'receipt_merchant_missing' =>
      'Add vendor aliases or header parsing coverage for this receipt shape.',
    'inventory_catalog_match_weak' =>
      'Review material aliases and catalog terms for this trade pack before expanding catalog volume.',
    'receipt_lines_need_review' =>
      'Inspect low-confidence line classification and add parser fixtures for the repeated receipt pattern.',
    'receipt_parser_low_confidence' =>
      'Review parser confidence reasons and add focused fixtures before trusting automatic fill for this receipt shape.',
    _ => '',
  };
  if (causeAction.isNotEmpty) return causeAction;
  return switch (workflowStep) {
    'receiptAttachment' =>
      'Review receipt proof capture, file access, and photo/PDF storage for this step.',
    'receiptOcr' =>
      'Review receipt image quality, OCR source limits, and whether the user should retake or add another section.',
    'receiptParser' =>
      'Add or adjust parser tests for this receipt shape before changing user-facing behavior.',
    'lineReview' =>
      'Check the receipt review flow and whether the user had enough guidance to finish.',
    'saveExpense' =>
      'Inspect local ledger save, Hive state, duplicate handling, and receipt proof promotion.',
    'export' =>
      'Inspect export limits, file creation, and handoff/share behavior.',
    'sync' || 'cloudBackup' || 'materialsBridge' =>
      'Inspect local queue state, retry behavior, and hosted sync handoff.',
    _ =>
      'Review the workflow step and add a more specific diagnostic if needed.',
  };
}

String _privacySafeFailurePhrase(String value) {
  final withoutAmounts = value
      .replaceAll(RegExp(r'\$+\s*\d+(?:[._\s]\d+)?'), ' amount ')
      .replaceAll(RegExp(r'\d+[._]\d{2,}'), ' amount ')
      .replaceAll(RegExp(r'\b\d+\s+\d{2,}\b'), ' amount ')
      .replaceAll(RegExp(r'(?<![A-Za-z0-9])\d{3,}(?![A-Za-z0-9])'), ' number ')
      .replaceAll(RegExp(r'[_\-.]+'), ' ');
  final generic = withoutAmounts
      .replaceAll(_privateReceiptNotePattern, ' private reference ')
      .replaceAll(_knownReceiptMerchantPattern, ' merchant ')
      .replaceAll(_knownReceiptLocationPattern, ' location ')
      .replaceAll(
        RegExp(r'\breceipt\s+number\b', caseSensitive: false),
        ' private reference ',
      )
      .replaceAll(_privateReceiptIdentifierPattern, ' private reference ')
      .replaceAll(
        RegExp(
          r'\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b',
          caseSensitive: false,
        ),
        ' email ',
      )
      .replaceAll(
        RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
        ' phone ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final humanized = _humanizeToken(generic).toLowerCase();
  return humanized.isEmpty ? 'diagnostic context' : humanized;
}

String _compactReadableText(String value, int maxChars) {
  final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.length <= maxChars) return clean;
  final hardCut = clean.substring(0, maxChars).trimRight();
  final lastSpace = hardCut.lastIndexOf(' ');
  if (lastSpace >= (maxChars * 0.65).floor()) {
    return hardCut.substring(0, lastSpace).trimRight();
  }
  return hardCut;
}

String _displayKnownAcronyms(String value) {
  final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) return 'Unknown';
  final words = clean.split(' ');
  return words
      .asMap()
      .entries
      .map((entry) {
        final word = entry.value.toLowerCase();
        if (word == 'ocr') return 'OCR';
        if (word == 'pdf') return 'PDF';
        if (word == 'hive') return 'Hive';
        if (entry.key == 0) return word[0].toUpperCase() + word.substring(1);
        return word;
      })
      .join(' ');
}

final RegExp _knownReceiptMerchantPattern = RegExp(
  r"\b(?:lowe\s*s|lowe'?s|walmart|target|home depot|costco|sam\s*s club|sam'?s club|shell|exxon|mobil|chevron|marathon|sheetz|wawa|speedway|circle k|bp|sunoco|pilot|flying j|love\s*s|love'?s|casey\s*s|casey'?s|kwik trip|kum\s*(?:and|&)?\s*go|quicktrip|qt|racetrac|raceway|royal farms|murphy usa|valero|phillips 66|citgo|sinclair|mapco|getgo|thorntons|travelcenters of america|petro|jiffy lube|valvoline|take 5|midas|pep boys|firestone|discount tire|les schwab|goodyear|ntb|autozone|advance auto|oreilly|o'?reilly|napa|carquest|tractor supply|harbor freight|menards|ace hardware|true value|rural king|fleet farm|blain\s*s farm fleet|blain'?s farm fleet)\b",
  caseSensitive: false,
);

final RegExp _knownReceiptLocationPattern = RegExp(
  r'\b(?:austin|atlanta|baltimore|charlotte|chicago|columbus|dallas|denver|detroit|houston|indianapolis|jacksonville|knoxville|las vegas|los angeles|louisville|memphis|miami|nashville|new york|orlando|philadelphia|phoenix|raleigh|richmond|san antonio|san diego|san francisco|seattle|tampa|washington)\b',
  caseSensitive: false,
);

final RegExp _privateReceiptIdentifierPattern = RegExp(
  r'\b(?:auth(?:code)?|approval|barcode|card|customer|client|employee|driver|email|invoice|member|name|note|notes|order|phone|sale|store|terminal|transaction|trans|user)\s+[a-z0-9]+\b',
  caseSensitive: false,
);

final RegExp _privateReceiptNotePattern = RegExp(
  r'\b(?:user|customer|client|employee|driver)?\s*(?:note|notes|name)\s+(?:[a-z0-9]+\s+){0,3}[a-z0-9]+\b',
  caseSensitive: false,
);

String _fallbackWorkflowStepFor(String event) {
  return switch (event) {
    'validationError' => ExpenseWorkflowStep.lineReview.name,
    'saveFailure' => ExpenseWorkflowStep.saveExpense.name,
    'imageAttachFailure' => ExpenseWorkflowStep.receiptAttachment.name,
    'ocrFailed' => ExpenseWorkflowStep.receiptOcr.name,
    'parserFailed' => ExpenseWorkflowStep.receiptParser.name,
    'parserNeedsReview' => ExpenseWorkflowStep.receiptParser.name,
    'cloudBackupFailure' => ExpenseWorkflowStep.cloudBackup.name,
    'syncFailed' => ExpenseWorkflowStep.sync.name,
    'exportBlocked' => ExpenseWorkflowStep.export.name,
    'exportFailed' => ExpenseWorkflowStep.export.name,
    'addExpenseAbandoned' => ExpenseWorkflowStep.lineReview.name,
    _ => ExpenseWorkflowStep.screenLoad.name,
  };
}

String _fallbackFailedAtFor(String event) {
  return switch (event) {
    'validationError' => 'before_save_validation',
    'saveFailure' => 'expense_save',
    'imageAttachFailure' => 'receipt_attachment_save',
    'ocrFailed' => 'receipt_ocr',
    'parserFailed' => 'receipt_parser',
    'parserNeedsReview' => 'receipt_parser_review',
    'cloudBackupFailure' => 'cloud_backup',
    'syncFailed' => 'hosted_sync',
    'exportBlocked' => 'before_export_file_write',
    'exportFailed' => 'expense_export',
    'addExpenseAbandoned' => 'before_expense_save',
    _ => 'unknown_step',
  };
}

String _stringValue(Object? value) => value is String ? value : '';

bool _boolValue(Object? value) => value is bool && value;

int _intValue(Object? value) => value is int ? value : 0;

Map<String, Object?> _metadataValue(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}
