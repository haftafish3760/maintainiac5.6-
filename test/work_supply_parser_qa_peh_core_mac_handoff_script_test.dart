import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_mac_handoff_script.dart';

void main() {
  test('PEH Mac handoff script renders measurement, rollup, and refresh commands', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_script_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/packet.json', {
      'branch': 'feature/test',
      'commit': 'abc123',
      'measurementCommands': [
        {
          'trade': 'electrical',
          'localePackId': 'en-US',
          'command': ['dart', 'run', 'tool/foo.dart', '--report-dir', 'tmp/reports'],
        },
      ],
      'rollupCommands': [
        {
          'trade': 'electrical',
          'command': ['dart', 'run', 'tool/bar.dart', '--output', 'tmp/out.json'],
        },
      ],
      'refreshCommand': ['dart', 'run', r'build\tool\refresh.dart'],
    });

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMacHandoffScript(
      const [
        '--packet',
        'build/parser_qa_pipeline/packet.json',
        '--output',
        'build/parser_qa_pipeline/run.sh',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final script = File('build/parser_qa_pipeline/run.sh').readAsStringSync();
    expect(script, contains('feature/test'));
    expect(script, contains("echo \"Measurement: electrical en-US\""));
    expect(script, contains("'dart' 'run' 'tool/foo.dart' '--report-dir' 'tmp/reports'"));
    expect(script, contains("echo \"Rollup: electrical\""));
    expect(script, contains("'dart' 'run' 'build/tool/refresh.dart'"));
    expect(stdout.content, contains('QA_PEH_CORE_MAC_HANDOFF_SCRIPT'));
  });

  test('PEH Mac handoff script rejects missing packet', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_mac_script_missing_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    final stderr = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreMacHandoffScript(
      const ['--packet', 'missing.json'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 66);
    expect(stderr.content, contains('--packet'));
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
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
