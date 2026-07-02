import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android receipt camera native files stay small and purpose-scoped', () {
    final files =
        Directory('android/app/src/main/kotlin/com/maintainiac')
            .listSync()
            .whereType<File>()
            .where(
              (file) => file.uri.pathSegments.last.startsWith('ReceiptCamera'),
            )
            .where((file) => file.path.endsWith('.kt'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);

    final oversized = <String>[];
    final copiedImportBlocks = <String>[];
    final importPattern = RegExp(r'^import\s+', multiLine: true);

    for (final file in files) {
      final source = file.readAsStringSync();
      final lineCount = '\n'.allMatches(source).length + 1;
      final importCount = importPattern.allMatches(source).length;
      if (lineCount > 500) {
        oversized.add('${file.path}: $lineCount lines');
      }
      if (importCount > 30) {
        copiedImportBlocks.add('${file.path}: $importCount imports');
      }
    }

    expect(
      oversized,
      isEmpty,
      reason: 'Receipt camera Kotlin files must stay under the 500-line rule.',
    );
    expect(
      copiedImportBlocks,
      isEmpty,
      reason:
          'Receipt camera Kotlin helpers must not regain generated import blocks.',
    );
  });
}
