part of 'expense_screen_telemetry.dart';


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

void _mergeTokenList(Map<String, int> target, Object? source) {
  if (source is! Iterable) return;
  for (final value in source) {
    if (value == null) continue;
    final token = _safeToken(value.toString(), fallback: '');
    if (token.isEmpty) continue;
    target[token] = (target[token] ?? 0) + 1;
  }
}

void _mergeStringValueMap(
  Map<String, int> target,
  Map<String, Object?> source,
) {
  for (final entry in source.entries) {
    final value = entry.value;
    if (value is! String) continue;
    final token = _safeToken(value, fallback: '');
    if (token.isEmpty) continue;
    target[token] = (target[token] ?? 0) + 1;
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

String _topReceiptPhotoCoverageStatusKey(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  const riskOrder = {
    'likelycutoff': 0,
    'likelyCutOff': 0,
    'maybecontinues': 1,
    'maybeContinues': 1,
    'unknown': 2,
    'likelycomplete': 3,
    'likelyComplete': 3,
  };
  final entries = counts.entries.toList()
    ..sort((left, right) {
      final count = right.value.compareTo(left.value);
      if (count != 0) return count;
      final leftRisk = riskOrder[left.key] ?? 99;
      final rightRisk = riskOrder[right.key] ?? 99;
      final risk = leftRisk.compareTo(rightRisk);
      if (risk != 0) return risk;
      return left.key.compareTo(right.key);
    });
  return entries.first.key;
}

String _topReceiptPhotoCoverageReasonKey(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  const riskOrder = {
    'native_cut_off_risk': 0,
    'quality_poor_framing': 1,
    'text_may_be_too_small': 2,
    'weak_receipt_lines': 3,
    'receipt_not_found': 4,
    'coverage_unknown': 5,
    'readable_framed_photo': 6,
    'framing_ok_readable': 7,
  };
  final entries = counts.entries.toList()
    ..sort((left, right) {
      final count = right.value.compareTo(left.value);
      if (count != 0) return count;
      final leftRisk = riskOrder[left.key] ?? 99;
      final rightRisk = riskOrder[right.key] ?? 99;
      final risk = leftRisk.compareTo(rightRisk);
      if (risk != 0) return risk;
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
