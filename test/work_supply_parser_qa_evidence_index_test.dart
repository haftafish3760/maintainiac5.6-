import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_evidence_index.dart';

void main() {
  test('evidence index lists safe wave summaries', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_index_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeWave(root: root, waveId: 'wave-a');
    _writeWave(root: root, waveId: 'wave-b');
    final output = '${root.path}/index.json';
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaEvidenceIndex(
      ['--root', root.path, '--output', output],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_EVIDENCE_INDEX'));
    final report = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(report['waveCount'], 2);
    expect(report['unsafe'], false);
    expect(report['waves'], isA<List>());
  });

  test('evidence index rejects unsafe wave summaries', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_evidence_index_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    _writeWave(root: root, waveId: 'unsafe-wave', liveServicesAllowed: true);

    final exit = runWorkSupplyParserQaEvidenceIndex(
      ['--root', root.path],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
  });
}

void _writeWave({
  required Directory root,
  required String waveId,
  bool liveServicesAllowed = false,
}) {
  final wave = Directory('${root.path}/$waveId')..createSync();
  File('${wave.path}/wave_summary.json').writeAsStringSync(
    jsonEncode({
      'waveId': waveId,
      'qaLayer': 'generated-fixture-first-round',
      'dryRun': false,
      'queueSummaryPath': '${wave.path}/queue/summary.json',
      'liveServicesAllowed': liveServicesAllowed,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
    }),
  );
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
