import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

void installExpenseTelemetryHiveLifecycle(String tempPrefix) {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(tempPrefix);
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });
}

ExpenseTelemetryContext expenseTelemetryContextFixture() {
  return const ExpenseTelemetryContext(
    appVersion: '0.6.9',
    platform: 'android',
    deviceTier: 'heavy',
    profileType: 'contractor',
    storageMode: ExpenseTelemetryStorageMode.low,
    planStatus: ExpenseTelemetryPlanStatus.free,
    connectionStatus: ExpenseTelemetryConnectionStatus.online,
  );
}
