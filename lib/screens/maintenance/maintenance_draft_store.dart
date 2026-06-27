import 'package:hive_flutter/hive_flutter.dart';

class MaintenanceDraftStore {
  const MaintenanceDraftStore._();

  static const boxName = 'maintenance_drafts';
  static const setupPrefix = 'setup';
  static const logPrefix = 'log';

  static Future<void> saveSetupDraft({
    required String vehicleName,
    required String itemName,
    required Map<String, Object?> values,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.put(_key(setupPrefix, vehicleName, itemName), {
      ...values,
      'vehicleName': vehicleName,
      'itemName': itemName,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> saveLogDraft({
    required String vehicleName,
    required Map<String, Object?> values,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.put(_key(logPrefix, vehicleName, 'active'), {
      ...values,
      'vehicleName': vehicleName,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> clearSetupDraft({
    required String vehicleName,
    required String itemName,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.delete(_key(setupPrefix, vehicleName, itemName));
  }

  static Future<void> clearLogDraft({required String vehicleName}) async {
    final box = await Hive.openBox<dynamic>(boxName);
    await box.delete(_key(logPrefix, vehicleName, 'active'));
  }

  static String _key(String prefix, String vehicleName, String itemName) {
    return [
      prefix,
      vehicleName.trim().toLowerCase(),
      itemName.trim().toLowerCase(),
    ].join('|');
  }
}
