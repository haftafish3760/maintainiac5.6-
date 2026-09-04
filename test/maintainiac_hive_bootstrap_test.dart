import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/storage/maintainiac_hive_bootstrap.dart';

void main() {
  test('copies private legacy Hive databases without lock files', () async {
    final root = await Directory.systemTemp.createTemp('maintainiac-hive-');
    addTearDown(() => root.delete(recursive: true));
    final source = Directory('${root.path}/source')..createSync();
    final destination = Directory('${root.path}/destination')..createSync();
    File('${source.path}/known.hive').writeAsBytesSync([1, 2, 3]);
    File('${source.path}/known.lock').writeAsBytesSync(const []);

    final copied = await MaintainiacHiveBootstrap.migrateLegacyMacOsBoxes(
      sourceDirectory: source,
      destinationDirectory: destination,
      sourceIsPrivateAppContainer: true,
    );

    expect(copied, ['known']);
    expect(File('${destination.path}/known.hive').readAsBytesSync(), [1, 2, 3]);
    expect(File('${destination.path}/known.lock').existsSync(), isFalse);
    expect(File('${source.path}/known.hive').existsSync(), isTrue);
  });

  test('never overwrites an existing destination database', () async {
    final root = await Directory.systemTemp.createTemp('maintainiac-hive-');
    addTearDown(() => root.delete(recursive: true));
    final source = Directory('${root.path}/source')..createSync();
    final destination = Directory('${root.path}/destination')..createSync();
    File('${source.path}/known.hive').writeAsBytesSync([1]);
    File('${destination.path}/known.hive').writeAsBytesSync([9]);

    final copied = await MaintainiacHiveBootstrap.migrateLegacyMacOsBoxes(
      sourceDirectory: source,
      destinationDirectory: destination,
      sourceIsPrivateAppContainer: true,
    );

    expect(copied, isEmpty);
    expect(File('${destination.path}/known.hive').readAsBytesSync(), [9]);
  });

  test('global Documents migration ignores unrecognized Hive files', () async {
    final root = await Directory.systemTemp.createTemp('maintainiac-hive-');
    addTearDown(() => root.delete(recursive: true));
    final source = Directory('${root.path}/source')..createSync();
    final destination = Directory('${root.path}/destination')..createSync();
    File('${source.path}/operational_context_v1.hive').writeAsBytesSync([1]);
    File('${source.path}/another_apps_data.hive').writeAsBytesSync([2]);

    final copied = await MaintainiacHiveBootstrap.migrateLegacyMacOsBoxes(
      sourceDirectory: source,
      destinationDirectory: destination,
      sourceIsPrivateAppContainer: false,
    );

    expect(copied, ['operational_context_v1']);
    expect(
      File('${destination.path}/operational_context_v1.hive').existsSync(),
      isTrue,
    );
    expect(
      File('${destination.path}/another_apps_data.hive').existsSync(),
      isFalse,
    );
  });
}
