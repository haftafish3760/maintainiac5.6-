import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_parity.dart';

void main() {
  test('handoff parity passes when reusable checkpoint and PEH packet agree', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_parity_ok_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeJson('${root.path}/docs/reusable_parsing_qa_checkpoint.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'validatedFloorCommit': 'fc219cc',
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff_packet.json', {
      'reusableBaselineBranch': 'codex/reusable-parsing-qa-foundation',
      'reusableValidatedFloorCommit': 'fc219cc',
      'inventoryExecutionBranch': 'codex/inventory-parser-backup-20260702-2056',
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
    });

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaHandoffParity(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);
    final payload = _extractJsonPayload(stdout.content);
    expect(payload['parityOk'], isTrue);
    expect(payload['findingCount'], 0);
  });

  test('handoff parity fails when packet drifts from reusable checkpoint', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_reusable_handoff_parity_drift_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _writeJson('${root.path}/docs/reusable_parsing_qa_checkpoint.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'validatedFloorCommit': 'fc219cc',
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
    });
    _writeJson('${root.path}/build/parser_qa_pipeline/peh_core_mac_handoff_packet.json', {
      'reusableBaselineBranch': 'codex/reusable-parsing-qa-foundation',
      'reusableValidatedFloorCommit': 'oldfloor1',
      'inventoryExecutionBranch': 'codex/inventory-parser-backup-20260702-2056',
      'readyForMacMeasurementWave': false,
      'readyToClaimNinetyPlus': false,
      'totalRemainingChecked': 12,
      'nextTradesByRemainingGap': ['electrical'],
    });

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runReusableParsingQaHandoffParity(
      ['--root', root.path],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 1);
    expect(stderr.content, isEmpty);
    final payload = _extractJsonPayload(stdout.content);
    expect(payload['parityOk'], isFalse);
    expect(payload['findingCount'], greaterThanOrEqualTo(2));
    expect(payload['findings'].toString(), contains('reusable validated floor mismatch'));
    expect(payload['findings'].toString(), contains('readyForMacMeasurementWave mismatch'));
    expect(payload['findings'].toString(), contains('totalRemainingChecked mismatch'));
    expect(payload['findings'].toString(), contains('nextTradesByRemainingGap mismatch'));
  });
}

Map<String, Object?> _extractJsonPayload(String stdout) {
  const prefix = 'QA_REUSABLE_PARSING_HANDOFF_PARITY ';
  expect(stdout, contains(prefix));
  final start = stdout.indexOf(prefix);
  final jsonText = stdout.substring(start + prefix.length).trim();
  return jsonDecode(jsonText) as Map<String, Object?>;
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
