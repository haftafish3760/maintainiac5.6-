import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void installReceiptNativeCaptureStagingHarness({
  required Directory Function() documentsDirectory,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => switch (call.method) {
          'getApplicationDocumentsDirectory' => documentsDirectory().path,
          _ => null,
        },
      );
}

Future<void> disposeReceiptNativeCaptureStagingHarness({
  required Directory documentsDirectory,
  required Directory hiveDirectory,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
  await Hive.close();
  if (await documentsDirectory.exists()) {
    await documentsDirectory.delete(recursive: true);
  }
  if (await hiveDirectory.exists()) {
    await hiveDirectory.delete(recursive: true);
  }
}
