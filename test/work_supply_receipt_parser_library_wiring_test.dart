import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt parser part files are registered by their parent library', () {
    const parentPath =
        'lib/screens/work_supplies/data/work_supply_receipt_parser.dart';
    final parent = File(parentPath).readAsStringSync();
    final directory = Directory('lib/screens/work_supplies/data');
    final partFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => RegExp(
            r"part of '.*work_supply_receipt_parser\.dart';",
          ).hasMatch(file.readAsStringSync()),
        )
        .toList(growable: false);

    for (final partFile in partFiles) {
      final relativePath = partFile.path
          .substring(directory.path.length + 1)
          .replaceAll('\\', '/');
      expect(parent, contains("part '$relativePath';"), reason: relativePath);
    }
  });
}
