import 'package:hive_flutter/hive_flutter.dart';

enum AiSecurityEventType {
  aiRequestAllowed,
  aiRequestFlagged,
  aiRequestBlocked,
  jailbreakAttempt,
  promptInjectionAttempt,
  malformedInputAttempt,
  rateLimitApplied,
  accountAiSuspended,
  accountSuspended,
  deviceInstallBanned,
  newAccountBlockedFromDevice,
}

enum AiAbuseReason {
  none,
  promptInjectionPattern,
  jailbreakPattern,
  suspiciousUrlOrMarkup,
  malformedQuotesOrBrackets,
  credentialRequest,
  privateDataExfiltrationAttempt,
  policyBypassAttempt,
  repeatedSuspiciousInput,
  rateLimitExceeded,
  tokenAbuse,
  unknown,
}

enum AiSecurityActionTaken {
  allowed,
  logged,
  warned,
  requestBlocked,
  aiAccessSuspended,
  accountSuspended,
  deviceInstallBanned,
  newAccountBlockedFromDevice,
  deviceRateLimited,
  adminReviewQueued,
}

class AiSecurityIdentityContext {
  const AiSecurityIdentityContext({
    required this.accountId,
    required this.anonymousAnalyticsId,
    required this.deviceInstallId,
    required this.appVersion,
    required this.platform,
    this.deviceIdHash,
    this.ipRoughRegion,
  });

  final String accountId;
  final String anonymousAnalyticsId;
  final String deviceInstallId;
  final String appVersion;
  final String platform;
  final String? deviceIdHash;
  final String? ipRoughRegion;

  Map<String, Object?> toMap() {
    return {
      'accountId': _safeIdentifier(accountId),
      'anonymousAnalyticsId': _safeIdentifier(anonymousAnalyticsId),
      'deviceInstallId': _safeIdentifier(deviceInstallId),
      if (deviceIdHash != null) 'deviceIdHash': _safeIdentifier(deviceIdHash!),
      'appVersion': _safeToken(appVersion),
      'platform': _safeToken(platform),
      if (ipRoughRegion != null) 'ipRoughRegion': _safeRegion(ipRoughRegion!),
    };
  }
}

class AiAbuseSecurityEvent {
  const AiAbuseSecurityEvent({
    required this.eventType,
    required this.identity,
    required this.aiTaskType,
    required this.abuseReason,
    required this.actionTaken,
    required this.clientObservedAtUtc,
    this.serverRequestTimestampUtc,
    this.attemptCount = 1,
    this.riskScore = 0,
    this.metadata = const {},
  });

  final AiSecurityEventType eventType;
  final AiSecurityIdentityContext identity;
  final String aiTaskType;
  final AiAbuseReason abuseReason;
  final AiSecurityActionTaken actionTaken;
  final DateTime clientObservedAtUtc;
  final DateTime? serverRequestTimestampUtc;
  final int attemptCount;
  final int riskScore;
  final Map<String, Object?> metadata;

  Map<String, Object?> toServerRequestMap() {
    return AiAbuseSecurityPolicy.sanitizeMap({
      'eventType': eventType.name,
      ...identity.toMap(),
      'aiTaskType': _safeToken(aiTaskType),
      'abuseReason': abuseReason.name,
      'actionTaken': actionTaken.name,
      'clientObservedAtUtc': clientObservedAtUtc.toUtc().toIso8601String(),
      if (serverRequestTimestampUtc != null)
        'serverRequestTimestampUtc': serverRequestTimestampUtc!
            .toUtc()
            .toIso8601String()
      else
        'serverRequestTimestampRequired': true,
      'attemptCount': attemptCount,
      'riskScore': riskScore,
      if (metadata.isNotEmpty)
        'metadata': AiAbuseSecurityPolicy.sanitizeMetadata(metadata),
    });
  }
}

class AiAbuseSecurityDecision {
  const AiAbuseSecurityDecision({
    required this.eventType,
    required this.primaryReason,
    required this.reasons,
    required this.actionTaken,
    required this.riskScore,
  });

  final AiSecurityEventType eventType;
  final AiAbuseReason primaryReason;
  final List<AiAbuseReason> reasons;
  final AiSecurityActionTaken actionTaken;
  final int riskScore;

  bool get isAllowed => actionTaken == AiSecurityActionTaken.allowed;
  bool get needsAdminReview =>
      actionTaken == AiSecurityActionTaken.adminReviewQueued ||
      actionTaken == AiSecurityActionTaken.deviceRateLimited ||
      actionTaken == AiSecurityActionTaken.aiAccessSuspended;
}

class AiAbuseSecurityPolicy {
  const AiAbuseSecurityPolicy._();

  static const allowedKeys = <String>{
    'eventType',
    'accountId',
    'anonymousAnalyticsId',
    'deviceInstallId',
    'deviceIdHash',
    'appVersion',
    'platform',
    'ipRoughRegion',
    'aiTaskType',
    'abuseReason',
    'actionTaken',
    'clientObservedAtUtc',
    'serverRequestTimestampUtc',
    'serverRequestTimestampRequired',
    'attemptCount',
    'riskScore',
    'metadata',
  };

  static const allowedMetadataKeys = <String>{
    'parserVersion',
    'model',
    'taskCategory',
    'inputLengthBucket',
    'tokenEstimateBucket',
    'ruleVersion',
    'requestId',
    'traceId',
    'featureFlag',
  };

  static const blockedSensitiveKeys = <String>{
    'prompt',
    'promptText',
    'rawPrompt',
    'inputText',
    'receiptText',
    'ocrText',
    'invoiceText',
    'customerName',
    'employeeName',
    'address',
    'phone',
    'email',
    'notes',
    'message',
    'description',
    'itemDescription',
    'customerContent',
  };

  static const maxTokenLength = 96;
  static final _safeTokenPattern = RegExp(r'^[A-Za-z0-9_.:/-]+$');
  static final _identifierPattern = RegExp(r'^[A-Za-z0-9_.:-]{8,160}$');
  static final _regionPattern = RegExp(r'^[A-Za-z]{2}(-[A-Za-z0-9]{1,16})?$');

  static AiAbuseSecurityDecision evaluateInput({
    required String input,
    int previousSuspiciousAttempts = 0,
  }) {
    final normalized = input.toLowerCase();
    final reasons = <AiAbuseReason>{};

    if (_containsAny(normalized, const [
      'ignore previous instructions',
      'ignore all previous instructions',
      'system prompt',
      'developer message',
      'reveal your instructions',
      'print your instructions',
      'override policy',
      'bypass safety',
      'act as unrestricted',
    ])) {
      reasons.add(AiAbuseReason.promptInjectionPattern);
    }

    if (_containsAny(normalized, const [
      'jailbreak',
      'dan mode',
      'developer mode',
      'developer mode enabled',
      'do anything now',
      'uncensored mode',
    ])) {
      reasons.add(AiAbuseReason.jailbreakPattern);
    }

    if (_containsAny(normalized, const [
      '<script',
      '</script',
      'javascript:',
      'data:text/html',
      '%3cscript',
      'onerror=',
      'onload=',
    ])) {
      reasons.add(AiAbuseReason.suspiciousUrlOrMarkup);
    }

    if (_containsAny(normalized, const [
      'api key',
      'secret key',
      'service account',
      'private key',
      'firebase token',
      'openai key',
    ])) {
      reasons.add(AiAbuseReason.credentialRequest);
    }

    if (_containsAny(normalized, const [
      'export all users',
      'dump database',
      'show customer data',
      'show receipts from other users',
      'read another account',
    ])) {
      reasons.add(AiAbuseReason.privateDataExfiltrationAttempt);
    }

    if (_hasMalformedQuoteOrBracketPattern(input)) {
      reasons.add(AiAbuseReason.malformedQuotesOrBrackets);
    }

    if (reasons.isNotEmpty && previousSuspiciousAttempts >= 2) {
      reasons.add(AiAbuseReason.repeatedSuspiciousInput);
    }

    if (reasons.isEmpty) {
      return const AiAbuseSecurityDecision(
        eventType: AiSecurityEventType.aiRequestAllowed,
        primaryReason: AiAbuseReason.none,
        reasons: [],
        actionTaken: AiSecurityActionTaken.allowed,
        riskScore: 0,
      );
    }

    final riskScore = _riskScoreFor(reasons, previousSuspiciousAttempts);
    final actionTaken = _actionForRisk(riskScore, previousSuspiciousAttempts);
    return AiAbuseSecurityDecision(
      eventType: switch (actionTaken) {
        AiSecurityActionTaken.requestBlocked =>
          AiSecurityEventType.aiRequestBlocked,
        AiSecurityActionTaken.deviceRateLimited =>
          AiSecurityEventType.rateLimitApplied,
        AiSecurityActionTaken.aiAccessSuspended =>
          AiSecurityEventType.accountAiSuspended,
        _ => AiSecurityEventType.aiRequestFlagged,
      },
      primaryReason: reasons.first,
      reasons: List.unmodifiable(reasons),
      actionTaken: actionTaken,
      riskScore: riskScore,
    );
  }

  static Map<String, Object?> sanitize(AiAbuseSecurityEvent event) {
    return event.toServerRequestMap();
  }

  static Map<String, Object?> sanitizeMap(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (blockedSensitiveKeys.contains(key)) {
        throw ArgumentError.value(
          key,
          'key',
          'Private AI prompt, receipt, customer, or message content is not allowed in abuse telemetry.',
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
          'Private AI prompt, receipt, customer, or message content is not allowed in abuse telemetry.',
        );
      }
      if (!allowedMetadataKeys.contains(key)) continue;
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }

  static bool _containsAny(String input, List<String> terms) {
    return terms.any(input.contains);
  }

  static bool _hasMalformedQuoteOrBracketPattern(String input) {
    final suspiciousPunctuationRuns = RegExp(
      r'''(['"`<>{}\[\]();]){5,}''',
    ).hasMatch(input);
    final sqlishOrShellishTail = RegExp(
      r'''(--|/\*|\*/|\|\||&&|\$\(|`[^`]{0,64}`)''',
    ).hasMatch(input);
    final repeatedEscapedMarkup = RegExp(
      r'''(&lt;|&gt;|%3c|%3e).{0,32}(&lt;|&gt;|%3c|%3e)''',
      caseSensitive: false,
    ).hasMatch(input);
    return suspiciousPunctuationRuns ||
        sqlishOrShellishTail ||
        repeatedEscapedMarkup;
  }

  static int _riskScoreFor(
    Set<AiAbuseReason> reasons,
    int previousSuspiciousAttempts,
  ) {
    var score = reasons.length * 25;
    if (reasons.contains(AiAbuseReason.credentialRequest)) score += 25;
    if (reasons.contains(AiAbuseReason.privateDataExfiltrationAttempt)) {
      score += 35;
    }
    if (reasons.contains(AiAbuseReason.repeatedSuspiciousInput)) score += 30;
    score += previousSuspiciousAttempts * 10;
    return score.clamp(0, 100);
  }

  static AiSecurityActionTaken _actionForRisk(
    int riskScore,
    int previousSuspiciousAttempts,
  ) {
    if (previousSuspiciousAttempts >= 5) {
      return AiSecurityActionTaken.aiAccessSuspended;
    }
    if (riskScore >= 80 || previousSuspiciousAttempts >= 3) {
      return AiSecurityActionTaken.deviceRateLimited;
    }
    if (riskScore >= 55) return AiSecurityActionTaken.requestBlocked;
    if (riskScore >= 35) return AiSecurityActionTaken.adminReviewQueued;
    return AiSecurityActionTaken.warned;
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) {
      if (value < 0) throw ArgumentError.value(value, key, 'Must be positive.');
      return value;
    }
    if (value is String) {
      if (key == 'accountId' ||
          key == 'anonymousAnalyticsId' ||
          key == 'deviceInstallId' ||
          key == 'deviceIdHash') {
        return _safeIdentifier(value);
      }
      if (key == 'ipRoughRegion') return _safeRegion(value);
      if (key.endsWith('AtUtc')) {
        final parsed = DateTime.tryParse(value);
        if (parsed == null) {
          throw ArgumentError.value(value, key, 'Must be an ISO timestamp.');
        }
        return parsed.toUtc().toIso8601String();
      }
      return _safeToken(value);
    }
    if (value is Map) {
      return sanitizeMetadata(Map<String, Object?>.from(value));
    }
    throw ArgumentError.value(value, key, 'Unsupported AI security value.');
  }
}

class AiAbuseSecurityRecord {
  const AiAbuseSecurityRecord({
    required this.id,
    required this.queuedAtUtc,
    required this.payload,
    this.uploadedAtUtc,
  });

  factory AiAbuseSecurityRecord.fromStored(Object? value) {
    if (value is! Map) return AiAbuseSecurityRecord.empty;
    final payload = value['payload'];
    return AiAbuseSecurityRecord(
      id: value['id'] as String? ?? '',
      queuedAtUtc:
          DateTime.tryParse(value['queuedAtUtc'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      uploadedAtUtc: DateTime.tryParse(value['uploadedAtUtc'] as String? ?? ''),
      payload: payload is Map
          ? AiAbuseSecurityPolicy.sanitizeMap(
              Map<String, Object?>.from(payload),
            )
          : const {},
    );
  }

  static final empty = AiAbuseSecurityRecord(
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
      'payload': AiAbuseSecurityPolicy.sanitizeMap(payload),
    };
  }
}

class AiAbuseSecurityEventStore {
  AiAbuseSecurityEventStore._(this._box, this._now);

  static const boxName = 'ai_abuse_security_events_v1';
  static const maxPendingRecords = 500;

  final Box<Object?> _box;
  final DateTime Function() _now;

  static Future<AiAbuseSecurityEventStore> create({
    DateTime Function()? now,
  }) async {
    final box = await Hive.openBox<Object?>(boxName);
    return AiAbuseSecurityEventStore._(box, now ?? DateTime.now);
  }

  Future<AiAbuseSecurityRecord> queue(AiAbuseSecurityEvent event) async {
    final queuedAt = _now().toUtc();
    final id = '${queuedAt.microsecondsSinceEpoch}_${event.eventType.name}';
    final record = AiAbuseSecurityRecord(
      id: id,
      queuedAtUtc: queuedAt,
      payload: event.toServerRequestMap(),
    );
    await _box.put(id, record.toMap());
    await _trimPendingRecords();
    return record;
  }

  Future<List<AiAbuseSecurityRecord>> pendingUpload() async {
    final records =
        _box.values
            .map(AiAbuseSecurityRecord.fromStored)
            .where((record) => record.isPendingUpload)
            .toList()
          ..sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return records;
  }

  Future<void> markUploaded(String id, {DateTime? uploadedAtUtc}) async {
    final record = AiAbuseSecurityRecord.fromStored(_box.get(id));
    if (record.isEmpty) return;
    await _box.put(
      id,
      AiAbuseSecurityRecord(
        id: record.id,
        queuedAtUtc: record.queuedAtUtc,
        uploadedAtUtc: (uploadedAtUtc ?? _now()).toUtc(),
        payload: record.payload,
      ).toMap(),
    );
  }

  Future<void> _trimPendingRecords() async {
    final records = await pendingUpload();
    if (records.length <= maxPendingRecords) return;
    final overflow = records.length - maxPendingRecords;
    for (final record in records.take(overflow)) {
      await _box.delete(record.id);
    }
  }
}

String _safeToken(String value) {
  final token = value.trim();
  if (token.isEmpty ||
      token.length > AiAbuseSecurityPolicy.maxTokenLength ||
      !AiAbuseSecurityPolicy._safeTokenPattern.hasMatch(token)) {
    throw ArgumentError.value(value, 'token', 'Unsafe AI security token.');
  }
  return token;
}

String _safeIdentifier(String value) {
  final token = value.trim();
  if (!AiAbuseSecurityPolicy._identifierPattern.hasMatch(token)) {
    throw ArgumentError.value(
      value,
      'identifier',
      'Unsafe AI security identifier.',
    );
  }
  return token;
}

String _safeRegion(String value) {
  final token = value.trim();
  if (!AiAbuseSecurityPolicy._regionPattern.hasMatch(token)) {
    throw ArgumentError.value(value, 'region', 'Unsafe rough region token.');
  }
  return token;
}
