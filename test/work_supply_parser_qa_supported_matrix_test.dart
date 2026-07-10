import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_supported_matrix.dart';

void main() {
  test('supported matrix reports release-one ready cells only', () {
    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaSupportedMatrix(
      const [],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _extract(stdout.content);
    expect(summary['cellCount'], 24);
    expect(summary['supportedTrades'], ['plumbing', 'electrical', 'hvac']);
    expect(summary['supportedScopes'], ['residential']);
    expect(summary['supportedTiers'], [
      'core',
      'standard',
      'professional',
      'complete',
    ]);
    expect(summary['supportedLocales'], ['en-US', 'es-US']);
    expect(summary['unsupportedPolicy'], 'fail-before-writing-files');
    expect(summary['liveServicesAllowed'], isFalse);
    expect(summary['writesProductionCatalog'], isFalse);
  });

  test('supported matrix can write an artifact for admin tooling', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_supported_matrix_',
    );
    addTearDown(() => output.delete(recursive: true));

    final path = '${output.path}/supported_matrix.json';
    final exit = runWorkSupplyParserQaSupportedMatrix(
      ['--output', path],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final file = File(path);
    expect(file.existsSync(), isTrue);
    final summary = jsonDecode(file.readAsStringSync()) as Map;
    expect(summary['cellCount'], 24);
    expect(summary['cells'].toString(), contains('plumbing'));
    expect(summary['cells'].toString(), contains('electrical'));
    expect(summary['cells'].toString(), contains('standard'));
    expect(summary['cells'].toString(), contains('complete'));
    expect(summary['cells'].toString(), contains('es-US'));
  });
}

Map<String, Object?> _extract(String output) {
  const marker = 'QA_SUPPORTED_MATRIX ';
  final start = output.indexOf(marker);
  expect(start, isNonNegative);
  return jsonDecode(output.substring(start + marker.length))
      as Map<String, Object?>;
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
