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
      return sanitizeMetadata(Map<String, Object?>.from(value));
    }
    throw ArgumentError.value(value, key, 'Unsupported telemetry value.');
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
    required this.ocrCorrectionOpenedCount,
    required this.userCorrectionCount,
    required this.cloudBackupSuccessCount,
    required this.cloudBackupFailureCount,
    required this.syncPendingCount,
    required this.syncedCount,
    required this.syncFailedCount,
    required this.exportStartedCount,
    required this.exportCompletedCount,
    required this.exportBlockedCount,
    required this.exportFailedCount,
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
    var ocrCorrectionOpenedCount = 0;
    var userCorrectionCount = 0;
    var cloudBackupSuccessCount = 0;
    var cloudBackupFailureCount = 0;
    var syncPendingCount = 0;
    var syncedCount = 0;
    var syncFailedCount = 0;
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
        case 'parserNeedsReview':
          parserNeedsReviewCount += 1;
        case 'parserFailed':
          parserFailedCount += 1;
        case 'ocrCorrectionOpened':
          ocrCorrectionOpenedCount += 1;
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
      ocrCorrectionOpenedCount: ocrCorrectionOpenedCount,
      userCorrectionCount: userCorrectionCount,
      cloudBackupSuccessCount: cloudBackupSuccessCount,
      cloudBackupFailureCount: cloudBackupFailureCount,
      syncPendingCount: syncPendingCount,
      syncedCount: syncedCount,
      syncFailedCount: syncFailedCount,
      exportStartedCount: exportStartedCount,
      exportCompletedCount: exportCompletedCount,
      exportBlockedCount: exportBlockedCount,
      exportFailedCount: exportFailedCount,
      failureBreakdowns: List.unmodifiable(
        failureStats.values.map((stats) => stats.toBreakdown()).toList()
          ..sort((a, b) => b.count.compareTo(a.count)),
      ),
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
  final int ocrCorrectionOpenedCount;
  final int userCorrectionCount;
  final int cloudBackupSuccessCount;
  final int cloudBackupFailureCount;
  final int syncPendingCount;
  final int syncedCount;
  final int syncFailedCount;
  final int exportStartedCount;
  final int exportCompletedCount;
  final int exportBlockedCount;
  final int exportFailedCount;
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
      'ocrCorrectionOpenedCount': ocrCorrectionOpenedCount,
      'userCorrectionCount': userCorrectionCount,
      'cloudBackupSuccessCount': cloudBackupSuccessCount,
      'cloudBackupFailureCount': cloudBackupFailureCount,
      'cloudBackupFailureRate': cloudBackupFailureRate,
      'syncPendingCount': syncPendingCount,
      'syncedCount': syncedCount,
      'syncFailedCount': syncFailedCount,
      'syncFailureRate': syncFailureRate,
      'exportStartedCount': exportStartedCount,
      'exportCompletedCount': exportCompletedCount,
      'exportBlockedCount': exportBlockedCount,
      'exportFailedCount': exportFailedCount,
      'exportCompletionRate': exportCompletionRate,
      'exportFailureRate': exportFailureRate,
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
      if (missingEvidence != 'none') 'missingEvidence': missingEvidence,
      'missingEvidenceLabel': missingEvidenceLabel,
      'recommendedAction': recommendedAction,
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
      if (missingEvidence != 'none') 'missingEvidence': missingEvidence,
      'missingEvidenceLabel': missingEvidenceLabel,
      'recommendedAction': recommendedAction,
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
    return ExpenseFailureBreakdown(
      featureArea: 'expenses',
      featureLabel: 'Expenses',
      workflowStep: workflowStep,
      workflowStepLabel: _humanizeToken(workflowStep),
      failedAt: failedAt,
      failedAtLabel: _humanizeToken(failedAt),
      confirmedCause: confirmedCause,
      causeLabel: _humanizeToken(confirmedCause),
      causeStatus: causeStatus,
      causeStatusLabel: _causeStatusLabel(causeStatus),
      evidence: evidence,
      evidenceLabel: _humanizeToken(evidence),
      missingEvidence: missingEvidence,
      missingEvidenceLabel: _missingEvidenceLabel(missingEvidence),
      recommendedAction: _recommendedActionFor(
        workflowStep: workflowStep,
        confirmedCause: confirmedCause,
        causeStatus: causeStatus,
        missingEvidence: missingEvidence,
      ),
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
  return ExpenseFailureEventDetail(
    eventId: record.id,
    queuedAtUtc: record.queuedAtUtc,
    event: event,
    featureArea: 'expenses',
    featureLabel: 'Expenses',
    workflowStep: resolved.workflowStep,
    workflowStepLabel: _humanizeToken(resolved.workflowStep),
    failedAt: resolved.failedAt,
    failedAtLabel: _humanizeToken(resolved.failedAt),
    confirmedCause: resolved.confirmedCause,
    causeLabel: _humanizeToken(resolved.confirmedCause),
    causeStatus: resolved.causeStatus,
    causeStatusLabel: _causeStatusLabel(resolved.causeStatus),
    evidence: resolved.evidence,
    evidenceLabel: _humanizeToken(resolved.evidence),
    missingEvidence: resolved.missingEvidence,
    missingEvidenceLabel: _missingEvidenceLabel(resolved.missingEvidence),
    recommendedAction: _recommendedActionFor(
      workflowStep: resolved.workflowStep,
      confirmedCause: resolved.confirmedCause,
      causeStatus: resolved.causeStatus,
      missingEvidence: resolved.missingEvidence,
    ),
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
  return 'Missing evidence: ${_humanizeToken(missingEvidence)}';
}

String _recommendedActionFor({
  required String workflowStep,
  required String confirmedCause,
  required String causeStatus,
  required String missingEvidence,
}) {
  if (causeStatus != ExpenseFailureCauseStatus.confirmed.name) {
    return 'Collect ${_humanizeToken(missingEvidence).toLowerCase()} so the app can confirm the cause.';
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
    'duplicate_receipt_text' || 'receipt_photo_overlap' =>
      'Review duplicate and overlap suppression so repeated long-receipt sections do not create duplicate charges.',
    'missing_receipt_attachment' =>
      'Ask the user to attach a receipt photo, PDF, or pasted receipt text before starting OCR.',
    'no_readable_text' =>
      'Check whether the attachment was blank, cropped, dark, or not a receipt, then ask for another section or manual entry.',
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

int _intValue(Object? value) => value is int ? value : 0;
