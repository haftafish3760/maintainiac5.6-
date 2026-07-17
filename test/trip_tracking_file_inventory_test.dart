import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trip tracking implementation has no duplicate source filenames', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.contains('trip_tracking'))
        .map((file) => file.uri.pathSegments.last)
        .toList(growable: false);
    final duplicateNames = _duplicates(files);

    expect(
      duplicateNames,
      isEmpty,
      reason:
          'Trip tracking should extend existing modules instead of creating duplicate source files.',
    );
  });

  test('trip tracking tests have no duplicate test filenames', () {
    final files = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last.contains('trip_tracking'))
        .map((file) => file.uri.pathSegments.last)
        .toList(growable: false);
    final duplicateNames = _duplicates(files);

    expect(
      duplicateNames,
      isEmpty,
      reason:
          'Trip tracking regression tests should add coverage without duplicate test files.',
    );
  });
}

List<String> _duplicates(Iterable<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    if (!seen.add(value)) duplicates.add(value);
  }
  return duplicates.toList(growable: false)..sort();
}
