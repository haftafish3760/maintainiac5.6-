part of 'expense_screen_telemetry.dart';

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
