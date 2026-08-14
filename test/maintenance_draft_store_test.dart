import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_review.dart';
import 'package:maintaniac/screens/maintenance/maintenance_draft_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_draft_store_test_',
    );
    Hive.init(hiveDirectory.path);
    MaintenanceDraftStore.setStorageCheckForTesting(_enoughStorage);
  });

  tearDown(() async {
    await Hive.close();
    MaintenanceDraftStore.setStorageCheckForTesting(null);
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test(
    'a queued clear removes a persisted setup draft after restart',
    () async {
      await MaintenanceDraftStore.saveSetupDraft(
        vehicleName: 'Work Truck',
        itemName: 'Oil change',
        values: const {'miles': 1200},
      );
      await Hive.close();
      Hive.init(hiveDirectory.path);

      await MaintenanceDraftStore.clearSetupDraft(
        vehicleName: 'Work Truck',
        itemName: 'Oil change',
      );

      expect(
        await MaintenanceDraftStore.loadSetupDraft(
          vehicleName: 'Work Truck',
          itemName: 'Oil change',
        ),
        isNull,
      );
    },
  );

  test('a queued clear cannot leave behind a racing log draft', () async {
    final save = MaintenanceDraftStore.saveLogDraft(
      vehicleName: 'Work Truck',
      values: const {'notes': 'Replace filter'},
    );
    final clear = MaintenanceDraftStore.clearLogDraft(
      vehicleName: 'Work Truck',
    );

    await Future.wait([save, clear]);

    expect(
      await MaintenanceDraftStore.loadLogDraft(vehicleName: 'Work Truck'),
      isNull,
    );
  });

  test(
    'receipt review draft survives restart and uses stable vehicle identity',
    () async {
      const fingerprint =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      await MaintenanceDraftStore.saveReceiptReviewDraft(
        vehicleId: 'vehicle_1',
        vehicleName: 'Old Truck Name',
        sourceFingerprintSha256: fingerprint,
        review: const {
          'draftSchemaVersion': 1,
          'parserResult': {'merchantName': 'NAPA Auto Parts'},
          'items': <Object?>[],
        },
      );
      await Hive.close();
      Hive.init(hiveDirectory.path);

      final restored = await MaintenanceDraftStore.loadReceiptReviewDraft(
        vehicleId: 'vehicle_1',
        sourceFingerprintSha256: fingerprint,
      );
      expect(restored, isNotNull);
      expect(restored!['draftType'], MaintenanceDraftStore.receiptReviewKind);
      expect(restored['review'], isA<Map>());
      expect('$restored', isNot(contains('sourceText')));

      final summaries = await MaintenanceDraftStore.loadDrafts(
        vehicleId: 'vehicle_1',
        vehicleName: 'Renamed Truck',
      );
      expect(summaries.single.kind, 'Receipt review');
      expect(summaries.single.title, 'NAPA Auto Parts');
      expect(summaries.single.vehicleId, 'vehicle_1');
      expect(summaries.single.storageKey, startsWith('receipt_review_v1|'));
    },
  );

  test('queued receipt review clear wins over an in-flight save', () async {
    const fingerprint =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final save = MaintenanceDraftStore.saveReceiptReviewDraft(
      vehicleId: 'vehicle_1',
      vehicleName: 'Work Truck',
      sourceFingerprintSha256: fingerprint,
      review: const {
        'draftSchemaVersion': 1,
        'parserResult': {'merchantName': 'AutoZone'},
        'items': <Object?>[],
      },
    );
    final clear = MaintenanceDraftStore.clearReceiptReviewDraft(
      vehicleId: 'vehicle_1',
      sourceFingerprintSha256: fingerprint,
    );
    await Future.wait([save, clear]);

    expect(
      await MaintenanceDraftStore.loadReceiptReviewDraft(
        vehicleId: 'vehicle_1',
        sourceFingerprintSha256: fingerprint,
      ),
      isNull,
    );
  });

  test('legacy review fields migrate without overriding explicit clears', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _partsReceipt(),
      currentOdometer: 101250,
    );
    final legacy = Map<String, Object?>.from(source.toDraftJson());
    final legacyItems = (legacy['items']! as List<Object?>).map((raw) {
      return Map<String, Object?>.from(raw! as Map)
        ..remove('setupMode')
        ..remove('intervalMiles')
        ..remove('intervalMonths');
    }).toList();
    legacy['items'] = legacyItems;

    final restored = MaintenanceReceiptReview.fromDraftJson(legacy);
    expect(
      restored.items.map((item) => item.setupMode),
      everyElement(MaintenanceReceiptSetupMode.basic),
    );
    expect(
      restored.items.map((item) => item.effectiveIntervalMiles),
      everyElement(5000),
    );
    expect(
      restored.items.map((item) => item.effectiveIntervalMonths),
      everyElement(6),
    );

    final cleared = Map<String, Object?>.from(legacyItems.first)
      ..['intervalMilesEdited'] = true
      ..['intervalMonthsEdited'] = true;
    legacy['items'] = [cleared, ...legacyItems.skip(1)];
    final restoredClear = MaintenanceReceiptReview.fromDraftJson(legacy);
    expect(restoredClear.items.first.effectiveIntervalMiles, isNull);
    expect(restoredClear.items.first.effectiveIntervalMonths, isNull);
  });

  test('review draft rejects unsupported or mismatched schemas', () {
    final source = createMaintenanceReceiptReview(
      parserResult: _partsReceipt(),
      currentOdometer: 101250,
    );
    final unsupported = Map<String, Object?>.from(source.toDraftJson())
      ..['draftSchemaVersion'] = 999;
    expect(
      () => MaintenanceReceiptReview.fromDraftJson(unsupported),
      throwsFormatException,
    );

    final mismatched = Map<String, Object?>.from(source.toDraftJson())
      ..['items'] = const <Object?>[];
    expect(
      () => MaintenanceReceiptReview.fromDraftJson(mismatched),
      throwsFormatException,
    );
  });
}

MaintenanceReceiptParserResult _partsReceipt() {
  return parseMaintenanceReceipt(
    const MaintenanceReceiptParserInput(
      activeVehicleId: 'vehicle_work_truck_1',
      activeVehicleName: 'Work Truck 1',
      currentOdometer: 101250,
      sourceText: '''
ADVANCE AUTO PARTS
07/23/2026
FULL SYNTHETIC MOTOR OIL 5W-30 34.99
OIL FILTER 12.99
TOTAL 47.98
''',
    ),
  );
}

Future<AppStorageCheck> _enoughStorage() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1024 * 1024,
  requiredBytes: 26 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);
