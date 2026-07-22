import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duplicate scanner reports exact duplicate code blocks', () async {
    final root = await Directory.systemTemp.createTemp('duplicate_code_scan_');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/one.dart').writeAsString(_source('first'));
    await File('${root.path}/two.dart').writeAsString(_source('second'));

    final result = await Process.run('dart', [
      'tool/duplicate_code_scan.dart',
      '--min-lines=4',
      root.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('Duplicate 4-line block:'));
    expect(result.stdout, contains('one.dart:'));
    expect(result.stdout, contains('two.dart:'));
  });

  test('duplicate scanner can fail a CI gate when duplicates exist', () async {
    final root = await Directory.systemTemp.createTemp('duplicate_code_gate_');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/one.dart').writeAsString(_source('first'));
    await File('${root.path}/two.dart').writeAsString(_source('second'));

    final result = await Process.run('dart', [
      'tool/duplicate_code_scan.dart',
      '--min-lines=4',
      '--fail-on-duplicates',
      root.path,
    ]);

    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
  });

  test('duplicate scanner excludes generated dependency trees', () async {
    final root = await Directory.systemTemp.createTemp('duplicate_code_scan_');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/owned.dart').writeAsString(_source('owned'));
    final generated = File(
      '${root.path}/ios/.symlinks/plugins/dependency.dart',
    );
    await generated.parent.create(recursive: true);
    await generated.writeAsString(_source('dependency'));

    final result = await Process.run('dart', [
      'tool/duplicate_code_scan.dart',
      '--min-lines=4',
      '--report=${root.path}/report.json',
      root.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      await File('${root.path}/report.json').readAsString(),
      contains('"filesScanned":1'),
    );
  });
}

String _source(String label) =>
    '''
void $label() {
  final amount = 42;
  final label = 'same code';
  print('\$label \$amount');
}
''';
