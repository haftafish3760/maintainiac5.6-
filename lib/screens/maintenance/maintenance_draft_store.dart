import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/storage/app_storage_guard.dart';

typedef MaintenanceDraftStorageCheck = Future<AppStorageCheck> Function();

class MaintenanceDraftSummary {
  const MaintenanceDraftSummary({
    required this.kind,
    required this.vehicleName,
    required this.title,
    required this.updatedAt,
    this.vehicleId = '',
    this.storageKey = '',
  });

  final String kind;
  final String vehicleName;
  final String title;
  final DateTime updatedAt;
  final String vehicleId;
  final String storageKey;
}

class MaintenanceDraftStore {
  const MaintenanceDraftStore._();

  static const boxName = 'maintenance_drafts';
  static const setupPrefix = 'setup';
  static const logPrefix = 'log';
  static const receiptReviewPrefix = 'receipt_review_v1';
  static const receiptReviewKind = 'receiptReview';
  static Future<void>? _writeTail;
  static int _pendingWrites = 0;
  static MaintenanceDraftStorageCheck _storageCheck = _defaultStorageCheck;

  static void setStorageCheckForTesting(MaintenanceDraftStorageCheck? check) {
    _storageCheck = check ?? _defaultStorageCheck;
  }

  static Future<void> saveSetupDraft({
    required String vehicleName,
    required String itemName,
    required Map<String, Object?> values,
  }) => _enqueue(() async {
    await _ensureStorageForWrite();
    final box = await _openBox();
    final key = _key(setupPrefix, vehicleName, itemName);
    await box.put(key, {
      ...values,
      'vehicleName': vehicleName,
      'itemName': itemName,
      'updatedAt': _nextTimestamp(box.get(key)).toIso8601String(),
    });
  });

  static Future<Map<String, dynamic>?> loadSetupDraft({
    required String vehicleName,
    required String itemName,
  }) async {
    final box = await _openBox();
    final value = box.get(_key(setupPrefix, vehicleName, itemName));
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> saveLogDraft({
    required String vehicleName,
    required Map<String, Object?> values,
  }) => _enqueue(() async {
    await _ensureStorageForWrite();
    final box = await _openBox();
    final key = _key(logPrefix, vehicleName, 'active');
    await box.put(key, {
      ...values,
      'vehicleName': vehicleName,
      'updatedAt': _nextTimestamp(box.get(key)).toIso8601String(),
    });
  });

  static Future<Map<String, dynamic>?> loadLogDraft({
    required String vehicleName,
  }) async {
    final box = await _openBox();
    final value = box.get(_key(logPrefix, vehicleName, 'active'));
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> clearSetupDraft({
    required String vehicleName,
    required String itemName,
  }) => _enqueue(() async {
    final box = await _openBox();
    await box.delete(_key(setupPrefix, vehicleName, itemName));
  });

  static Future<void> clearLogDraft({required String vehicleName}) =>
      _enqueue(() async {
        final box = await _openBox();
        await box.delete(_key(logPrefix, vehicleName, 'active'));
      });

  static Future<void> saveReceiptReviewDraft({
    required String vehicleId,
    required String vehicleName,
    required String sourceFingerprintSha256,
    required Map<String, Object?> review,
  }) => _enqueue(() async {
    final stableVehicleId = vehicleId.trim();
    final fingerprint = sourceFingerprintSha256.trim().toLowerCase();
    if (stableVehicleId.isEmpty ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(fingerprint)) {
      throw const FormatException('Receipt review draft identity is invalid.');
    }
    await _ensureStorageForWrite();
    final box = await _openBox();
    final key = _receiptReviewKey(stableVehicleId, fingerprint);
    final parser = review['parserResult'];
    final merchant = parser is Map
        ? '${parser['merchantName'] ?? ''}'.trim()
        : '';
    await box.put(key, {
      'draftType': receiptReviewKind,
      'vehicleId': stableVehicleId,
      'vehicleName': vehicleName.trim(),
      'sourceFingerprintSha256': fingerprint,
      'title': merchant.isEmpty ? 'Maintenance receipt' : merchant,
      'review': review,
      'updatedAt': _nextTimestamp(box.get(key)).toIso8601String(),
    });
  });

  static Future<Map<String, dynamic>?> loadReceiptReviewDraft({
    required String vehicleId,
    required String sourceFingerprintSha256,
  }) {
    return loadReceiptReviewDraftByKey(
      _receiptReviewKey(
        vehicleId.trim(),
        sourceFingerprintSha256.trim().toLowerCase(),
      ),
    );
  }

  static Future<Map<String, dynamic>?> loadReceiptReviewDraftByKey(
    String storageKey,
  ) async {
    if (!storageKey.startsWith('$receiptReviewPrefix|')) return null;
    final box = await _openBox();
    final value = box.get(storageKey);
    if (value is! Map || value['draftType'] != receiptReviewKind) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> clearReceiptReviewDraft({
    required String vehicleId,
    required String sourceFingerprintSha256,
  }) => _enqueue(() async {
    final box = await _openBox();
    await box.delete(
      _receiptReviewKey(
        vehicleId.trim(),
        sourceFingerprintSha256.trim().toLowerCase(),
      ),
    );
  });

  static Future<List<MaintenanceDraftSummary>> loadDrafts({
    String? vehicleName,
    String? vehicleId,
  }) async {
    final box = await _openBox();
    final normalizedVehicle = vehicleName?.trim().toLowerCase();
    final stableVehicleId = vehicleId?.trim();
    final drafts = <MaintenanceDraftSummary>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is! Map) continue;
      final draftVehicle = value['vehicleName']?.toString() ?? '';
      if (value['draftType'] == receiptReviewKind) {
        final draftVehicleId = '${value['vehicleId'] ?? ''}'.trim();
        if (stableVehicleId != null &&
            stableVehicleId.isNotEmpty &&
            draftVehicleId != stableVehicleId) {
          continue;
        }
        final updatedAt =
            DateTime.tryParse(value['updatedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        drafts.add(
          MaintenanceDraftSummary(
            kind: 'Receipt review',
            vehicleId: draftVehicleId,
            vehicleName: draftVehicle,
            title: '${value['title'] ?? 'Maintenance receipt'}'.trim(),
            updatedAt: updatedAt,
            storageKey: '$key',
          ),
        );
        continue;
      }
      if (normalizedVehicle != null &&
          draftVehicle.trim().toLowerCase() != normalizedVehicle) {
        continue;
      }
      final itemName = value['itemName']?.toString();
      final selectedItems = value['selectedItems'];
      final updatedAt =
          DateTime.tryParse(value['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (itemName != null && itemName.trim().isNotEmpty) {
        drafts.add(
          MaintenanceDraftSummary(
            kind: 'Setup draft',
            vehicleName: draftVehicle,
            title: itemName,
            updatedAt: updatedAt,
          ),
        );
        continue;
      }
      final title = selectedItems is Iterable && selectedItems.isNotEmpty
          ? selectedItems.map((item) => item.toString()).join(', ')
          : 'Maintenance service log';
      drafts.add(
        MaintenanceDraftSummary(
          kind: 'Log draft',
          vehicleName: draftVehicle,
          title: title,
          updatedAt: updatedAt,
        ),
      );
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  static String _key(String prefix, String vehicleName, String itemName) {
    return [
      prefix,
      vehicleName.trim().toLowerCase(),
      itemName.trim().toLowerCase(),
    ].join('|');
  }

  static String _receiptReviewKey(String vehicleId, String fingerprint) {
    return [
      receiptReviewPrefix,
      vehicleId.trim().toLowerCase(),
      fingerprint.trim().toLowerCase(),
    ].join('|');
  }

  static Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<dynamic>(boxName);
    return Hive.openBox<dynamic>(boxName);
  }

  static Future<void> _ensureStorageForWrite() async {
    final storage = await _storageCheck();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);

  static Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previous = _writeTail;
    final release = Completer<void>();
    _writeTail = release.future;
    _pendingWrites++;

    Future<T> run() async {
      try {
        return await operation();
      } finally {
        release.complete();
        _pendingWrites--;
        if (_pendingWrites == 0) _writeTail = null;
      }
    }

    return previous == null ? run() : previous.then((_) => run());
  }

  static DateTime _nextTimestamp(Object? existing) {
    final previous = existing is Map
        ? DateTime.tryParse(existing['updatedAt']?.toString() ?? '')?.toUtc()
        : null;
    final now = DateTime.now().toUtc();
    if (previous == null || !now.isBefore(previous)) return now;
    return previous;
  }
}
