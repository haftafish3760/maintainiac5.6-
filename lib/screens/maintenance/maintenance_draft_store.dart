import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/storage/app_storage_guard.dart';

class MaintenanceDraftSummary {
  const MaintenanceDraftSummary({
    required this.kind,
    required this.vehicleName,
    required this.title,
    required this.updatedAt,
  });

  final String kind;
  final String vehicleName;
  final String title;
  final DateTime updatedAt;
}

class MaintenanceDraftStore {
  const MaintenanceDraftStore._();

  static const boxName = 'maintenance_drafts';
  static const setupPrefix = 'setup';
  static const logPrefix = 'log';
  static Future<void> _writeTail = Future<void>.value();

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

  static Future<List<MaintenanceDraftSummary>> loadDrafts({
    String? vehicleName,
  }) async {
    final box = await _openBox();
    final normalizedVehicle = vehicleName?.trim().toLowerCase();
    final drafts = <MaintenanceDraftSummary>[];
    for (final value in box.values) {
      if (value is! Map) continue;
      final draftVehicle = value['vehicleName']?.toString() ?? '';
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

  static Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<dynamic>(boxName);
    return Hive.openBox<dynamic>(boxName);
  }

  static Future<void> _ensureStorageForWrite() async {
    final storage = await AppStorageGuard.check(
      AppStoragePurpose.smallRecordWrite,
    );
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  static Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
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
