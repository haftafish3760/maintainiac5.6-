part of 'expense_screen_telemetry.dart';

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
