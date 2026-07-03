import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_release_one_commands.dart';

void main() {
  test(
    'release-one command manifest covers all residential priority cells',
    () {
      final stdout = _MemorySink();

      final exit = runWorkSupplyParserQaReleaseOneCommands(
        const ['--limit', '250', '--fixture-run-limit', '25'],
        stdout: stdout,
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final summary = _extract(stdout.content);
      expect(summary['cellCount'], 24);
      expect(summary['priorityCellCount'], 12);
      expect(summary['limit'], 250);
      expect(summary['fixtureRunLimit'], 25);
      expect(summary['liveServicesAllowed'], isFalse);
      expect(summary['writesProductionCatalog'], isFalse);
      expect(summary['firebaseWritesAllowed'], isFalse);
      expect(summary['ocrCameraExpensesTouched'], isFalse);
      final commands = summary['commands'] as List<dynamic>;
      expect(commands.toString(), contains('plumbing.residential.core.en-US'));
      expect(
        commands.toString(),
        contains('electrical.residential.standard.es-US'),
      );
      expect(commands.toString(), contains('hvac.residential.complete.es-US'));
      final priorityCommands = commands
          .where((entry) => (entry as Map)['priorityCell'] == true)
          .toList();
      expect(priorityCommands, hasLength(12));
      expect(
        priorityCommands.toString(),
        contains('plumbing.residential.core.es-US'),
      );
      expect(
        priorityCommands.toString(),
        contains('hvac.residential.standard.en-US'),
      );
      expect(
        commands.every(
          (entry) => (entry as Map)['executeFlagRequired'] == true,
        ),
        isTrue,
      );
    },
  );

  test('release-one command manifest can write an artifact', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_release_one_commands_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final output = '${root.path}/commands.json';

    final exit = runWorkSupplyParserQaReleaseOneCommands(
      ['--output', output],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final file = File(output);
    expect(file.existsSync(), isTrue);
    final summary = jsonDecode(file.readAsStringSync()) as Map;
    expect(summary['cellCount'], 24);
    expect(summary['priorityCellCount'], 12);
    expect(summary['executionPolicy'].toString(), contains('--execute'));
  });
}

Map<String, Object?> _extract(String output) {
  const marker = 'QA_RELEASE_ONE_COMMANDS ';
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
