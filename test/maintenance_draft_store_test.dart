import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/maintenance/maintenance_draft_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_draft_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
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
}
