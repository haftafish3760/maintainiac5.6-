import 'package:hive_flutter/hive_flutter.dart';

enum AppBusinessTelemetryEventType {
  adImpression,
  adRevenueEstimate,
  subscriptionRevenue,
  storageUpgradeRevenue,
  aiCreditRevenue,
  firebaseCostEstimate,
  aiCostEstimate,
  storageCostEstimate,
  exportUsed,
  taxRecordGenerated,
}

enum AppBusinessRevenueSource { ads, subscription, storageUpgrade, aiCredits }

enum AppBusinessCostSource { firebase, ai, storage, paymentFees, other }

class AppBusinessTelemetryEvent {
  const AppBusinessTelemetryEvent({
    required this.type,
    this.platform = 'unknown',
    this.appVersion = 'unknown',
    this.planStatus = 'unknown',
    this.revenueSource,
    this.costSource,
    this.amountCents = 0,
    this.impressionCount = 0,
    this.estimatedCpmCents = 0,
    this.metadata = const {},
  });

  final AppBusinessTelemetryEventType type;
  final String platform;
  final String appVersion;
  final String planStatus;
  final AppBusinessRevenueSource? revenueSource;
  final AppBusinessCostSource? costSource;
  final int amountCents;
  final int impressionCount;
  final int estimatedCpmCents;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return {
      'event': type.name,
      'platform': _safeToken(platform),
      'appVersion': _safeToken(appVersion),
      'planStatus': _safeToken(planStatus),
      if (revenueSource != null) 'revenueSource': revenueSource!.name,
      if (costSource != null) 'costSource': costSource!.name,
      if (amountCents > 0) 'amountCents': amountCents,
      if (impressionCount > 0) 'impressionCount': impressionCount,
      if (estimatedCpmCents > 0) 'estimatedCpmCents': estimatedCpmCents,
      if (metadata.isNotEmpty)
        'metadata': AppBusinessTelemetryPolicy.sanitizeMetadata(metadata),
    };
  }
}

class AppBusinessTelemetryPolicy {
  const AppBusinessTelemetryPolicy._();

  static const allowedKeys = <String>{
    'event',
    'platform',
    'appVersion',
    'planStatus',
    'revenueSource',
    'costSource',
    'amountCents',
    'impressionCount',
    'estimatedCpmCents',
    'metadata',
  };

  static const allowedMetadataKeys = <String>{
    'adPlacement',
    'adNetwork',
    'screenArea',
    'exportKind',
    'taxYear',
    'region',
    'billingProvider',
  };

  static const blockedSensitiveKeys = <String>{
    'userName',
    'customerName',
    'email',
    'phone',
    'address',
    'receiptText',
    'invoiceText',
    'cardNumber',
    'bankAccount',
    'taxId',
    'ssn',
    'notes',
    'description',
  };

  static const maxStringLength = 64;
  static final _safeTokenPattern = RegExp(r'^[A-Za-z0-9_.-]+$');

  static Map<String, Object?> sanitize(AppBusinessTelemetryEvent event) {
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
          'Private business content is not allowed in telemetry.',
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
          'Private business content is not allowed in telemetry.',
        );
      }
      if (!allowedMetadataKeys.contains(key)) continue;
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (value == null) return null;
    if (value is int) {
      if (value < 0) throw ArgumentError.value(value, key, 'Must be positive.');
      return value;
    }
    if (value is String) return _sanitizeToken(key, value);
    if (value is Map) {
      return sanitizeMetadata(Map<String, Object?>.from(value));
    }
    throw ArgumentError.value(value, key, 'Unsupported business metric value.');
  }

  static String _sanitizeToken(String key, String value) {
    final token = value.trim();
    if (token.isEmpty ||
        token.length > maxStringLength ||
        !_safeTokenPattern.hasMatch(token)) {
      throw ArgumentError.value(value, key, 'Unsafe business metric token.');
    }
    return token;
  }
}

class AppBusinessTelemetryRecord {
  const AppBusinessTelemetryRecord({
    required this.id,
    required this.queuedAtUtc,
    required this.payload,
    this.uploadedAtUtc,
  });

  factory AppBusinessTelemetryRecord.fromStored(Object? value) {
    if (value is! Map) return AppBusinessTelemetryRecord.empty;
    final payload = value['payload'];
    return AppBusinessTelemetryRecord(
      id: value['id'] as String? ?? '',
      queuedAtUtc:
          DateTime.tryParse(value['queuedAtUtc'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      uploadedAtUtc: DateTime.tryParse(value['uploadedAtUtc'] as String? ?? ''),
      payload: payload is Map
          ? AppBusinessTelemetryPolicy.sanitizeMap(
              Map<String, Object?>.from(payload),
            )
          : const {},
    );
  }

  static final empty = AppBusinessTelemetryRecord(
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
      'payload': AppBusinessTelemetryPolicy.sanitizeMap(payload),
    };
  }
}

class AppBusinessHealthSnapshot {
  const AppBusinessHealthSnapshot({
    required this.generatedAtUtc,
    required this.totalEventCount,
    required this.pendingUploadCount,
    required this.uploadedEventCount,
    required this.adImpressionCount,
    required this.adRevenueCents,
    required this.subscriptionRevenueCents,
    required this.storageUpgradeRevenueCents,
    required this.aiCreditRevenueCents,
    required this.firebaseCostCents,
    required this.aiCostCents,
    required this.storageCostCents,
    required this.exportCount,
    required this.taxRecordGeneratedCount,
    required this.eventCounts,
  });

  factory AppBusinessHealthSnapshot.fromRecords(
    Iterable<AppBusinessTelemetryRecord> records, {
    DateTime? generatedAtUtc,
  }) {
    final eventCounts = <String, int>{};
    var pendingUploadCount = 0;
    var uploadedEventCount = 0;
    var adImpressionCount = 0;
    var adRevenueCents = 0;
    var subscriptionRevenueCents = 0;
    var storageUpgradeRevenueCents = 0;
    var aiCreditRevenueCents = 0;
    var firebaseCostCents = 0;
    var aiCostCents = 0;
    var storageCostCents = 0;
    var exportCount = 0;
    var taxRecordGeneratedCount = 0;

    for (final record in records) {
      final payload = AppBusinessTelemetryPolicy.sanitizeMap(record.payload);
      if (record.isPendingUpload) {
        pendingUploadCount += 1;
      } else {
        uploadedEventCount += 1;
      }
      final event = _stringValue(payload['event']);
      _increment(eventCounts, event);
      final amount = _intValue(payload['amountCents']);
      switch (event) {
        case 'adImpression':
          adImpressionCount += _intValue(
            payload['impressionCount'],
            fallback: 1,
          );
        case 'adRevenueEstimate':
          adRevenueCents += amount;
        case 'subscriptionRevenue':
          subscriptionRevenueCents += amount;
        case 'storageUpgradeRevenue':
          storageUpgradeRevenueCents += amount;
        case 'aiCreditRevenue':
          aiCreditRevenueCents += amount;
        case 'firebaseCostEstimate':
          firebaseCostCents += amount;
        case 'aiCostEstimate':
          aiCostCents += amount;
        case 'storageCostEstimate':
          storageCostCents += amount;
        case 'exportUsed':
          exportCount += 1;
        case 'taxRecordGenerated':
          taxRecordGeneratedCount += 1;
      }
    }

    return AppBusinessHealthSnapshot(
      generatedAtUtc: (generatedAtUtc ?? DateTime.now().toUtc()).toUtc(),
      totalEventCount: records.length,
      pendingUploadCount: pendingUploadCount,
      uploadedEventCount: uploadedEventCount,
      adImpressionCount: adImpressionCount,
      adRevenueCents: adRevenueCents,
      subscriptionRevenueCents: subscriptionRevenueCents,
      storageUpgradeRevenueCents: storageUpgradeRevenueCents,
      aiCreditRevenueCents: aiCreditRevenueCents,
      firebaseCostCents: firebaseCostCents,
      aiCostCents: aiCostCents,
      storageCostCents: storageCostCents,
      exportCount: exportCount,
      taxRecordGeneratedCount: taxRecordGeneratedCount,
      eventCounts: Map.unmodifiable(eventCounts),
    );
  }

  final DateTime generatedAtUtc;
  final int totalEventCount;
  final int pendingUploadCount;
  final int uploadedEventCount;
  final int adImpressionCount;
  final int adRevenueCents;
  final int subscriptionRevenueCents;
  final int storageUpgradeRevenueCents;
  final int aiCreditRevenueCents;
  final int firebaseCostCents;
  final int aiCostCents;
  final int storageCostCents;
  final int exportCount;
  final int taxRecordGeneratedCount;
  final Map<String, int> eventCounts;

  int get totalRevenueCents =>
      adRevenueCents +
      subscriptionRevenueCents +
      storageUpgradeRevenueCents +
      aiCreditRevenueCents;
  int get totalCostCents => firebaseCostCents + aiCostCents + storageCostCents;
  int get estimatedProfitCents => totalRevenueCents - totalCostCents;

  double get averageAdCpmCents {
    if (adImpressionCount == 0) return 0;
    return adRevenueCents / adImpressionCount * 1000;
  }

  Map<String, Object?> toCommandCenterMap() {
    return {
      'schema': 'app_business_health_v1',
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'totalEventCount': totalEventCount,
      'pendingUploadCount': pendingUploadCount,
      'uploadedEventCount': uploadedEventCount,
      'adImpressionCount': adImpressionCount,
      'adRevenueCents': adRevenueCents,
      'averageAdCpmCents': averageAdCpmCents,
      'subscriptionRevenueCents': subscriptionRevenueCents,
      'storageUpgradeRevenueCents': storageUpgradeRevenueCents,
      'aiCreditRevenueCents': aiCreditRevenueCents,
      'totalRevenueCents': totalRevenueCents,
      'firebaseCostCents': firebaseCostCents,
      'aiCostCents': aiCostCents,
      'storageCostCents': storageCostCents,
      'totalCostCents': totalCostCents,
      'estimatedProfitCents': estimatedProfitCents,
      'exportCount': exportCount,
      'taxRecordGeneratedCount': taxRecordGeneratedCount,
      'eventCounts': eventCounts,
    };
  }
}

class AppBusinessTelemetryStore {
  AppBusinessTelemetryStore._(this._box);

  static const boxName = 'app_business_telemetry_events';
  static const maxStoredEvents = 500;

  final Box<dynamic> _box;

  static Future<AppBusinessTelemetryStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return AppBusinessTelemetryStore._(box);
  }

  List<AppBusinessTelemetryRecord> get records {
    final loaded = <AppBusinessTelemetryRecord>[];
    for (final value in _box.values) {
      final record = AppBusinessTelemetryRecord.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  List<AppBusinessTelemetryRecord> get pendingUploadRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  Future<AppBusinessTelemetryRecord> enqueue(
    AppBusinessTelemetryEvent event, {
    DateTime? queuedAtUtc,
  }) async {
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = AppBusinessTelemetryRecord(
      id: _eventIdFor(queuedAt),
      queuedAtUtc: queuedAt,
      payload: AppBusinessTelemetryPolicy.sanitize(event),
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  AppBusinessHealthSnapshot buildHealthSnapshot({DateTime? nowUtc}) {
    return AppBusinessHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: nowUtc,
    );
  }

  List<Map<String, Object?>> pendingUploadPayloads({int limit = 50}) {
    final cappedLimit = limit.clamp(0, maxStoredEvents).toInt();
    return [
      for (final record in pendingUploadRecords.take(cappedLimit))
        Map<String, Object?>.unmodifiable({
          'eventId': record.id,
          'queuedAtUtc': record.queuedAtUtc.toUtc().toIso8601String(),
          'payload': AppBusinessTelemetryPolicy.sanitizeMap(record.payload),
        }),
    ];
  }

  Future<void> markUploaded(
    Iterable<String> eventIds, {
    DateTime? nowUtc,
  }) async {
    final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final id in eventIds) {
      final record = AppBusinessTelemetryRecord.fromStored(_box.get(id));
      if (record.isEmpty) continue;
      await _box.put(
        id,
        AppBusinessTelemetryRecord(
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

String _safeToken(String value) {
  final safe = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return 'unknown';
  return safe.length > AppBusinessTelemetryPolicy.maxStringLength
      ? safe.substring(0, AppBusinessTelemetryPolicy.maxStringLength)
      : safe;
}

void _increment(Map<String, int> counts, String value) {
  if (value.isEmpty) return;
  counts[value] = (counts[value] ?? 0) + 1;
}

String _stringValue(Object? value) => value is String ? value : '';

int _intValue(Object? value, {int fallback = 0}) {
  return value is int ? value : fallback;
}
