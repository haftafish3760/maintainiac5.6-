import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/reusable_parsing_qa_handoff_checkpoint.dart';
import '../tool/reusable_parsing_qa_handoff_refresh.dart';
import '../tool/work_supply_parser_qa_finalize_live_handoff.dart';

void main() {
  test('finalize live handoff runs restamp, sync, and summary together', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_finalize_live_handoff_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    Process.runSync('git', ['init']);
    Process.runSync('git', ['config', 'user.email', 'qa@example.com']);
    Process.runSync('git', ['config', 'user.name', 'QA Bot']);
    File('README.txt').writeAsStringSync('finalize');
    Process.runSync('git', ['add', 'README.txt']);
    Process.runSync('git', ['commit', '-m', 'init']);
    Process.runSync(
      'git',
      ['checkout', '-B', 'codex/inventory-parser-backup-20260702-2056'],
    );

    _writeJson('docs/reusable_parsing_qa_checkpoint.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'validatedFloorCommit': '8e9771d',
      'validatedFloorLabel':
          'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
    });
    File('docs/reusable_parsing_qa_checkpoint.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('# checkpoint');
    File('docs/reusable_parsing_qa_handoff_marker.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('# marker');
    File('docs/reusable_parsing_qa_scope_boundary.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('# boundary');
    File('docs/reusable_parsing_qa_mac_runbook.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('# runbook');
    _writeJson('docs/reusable_parsing_qa_mac_handoff_packet.json', {
      'primaryBranch': 'codex/reusable-parsing-qa-foundation',
      'baselineCommit': '8e9771d',
      'baselineCommitLabel':
          'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
      'windowsWorkingBranch': 'codex/inventory-parser-backup-20260702-2056',
      'currentMeasurementState': {
        'nextTradesByRemainingGap': ['hvac'],
        'totalRemainingChecked': 38,
      },
      'claimBlockingFindings': ['trade_not_ready:hvac'],
      'claimNextActions': ['Keep the hvac Mac wave running.'],
    });

    _writeJson('build/parser_qa_pipeline/peh_core_mac_wave_commands.json', {
      'selectedTrades': ['hvac'],
      'measurementCommandCount': 2,
      'rollupCommandCount': 1,
      'measurementCommands': [
        {
          'trade': 'hvac',
          'localePackId': 'en-US',
          'command': ['dart', 'run', 'tool/foo.dart', '--report-dir', 'tmp/en'],
        },
        {
          'trade': 'hvac',
          'localePackId': 'es-US',
          'command': ['dart', 'run', 'tool/foo.dart', '--report-dir', 'tmp/es'],
        },
      ],
      'rollupCommands': [
        {
          'trade': 'hvac',
          'command': ['dart', 'run', 'tool/bar.dart', '--output', 'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json'],
        },
      ],
    });
    _writeJson('build/parser_qa_pipeline/peh_core_windows_status_rollup.json', {
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'tradeCount': 3,
      'sampleSizedTradeCount': 1,
      'underTargetTradeCount': 1,
    });
    _writeJson('build/parser_qa_pipeline/peh_core_measurement_gap.json', {
      'totalRemainingChecked': 38,
      'nextTradesByRemainingGap': ['hvac'],
      'tradeGaps': [
        {'trade': 'hvac', 'remainingChecked': 38},
      ],
    });
    _writeJson('build/parser_qa_pipeline/peh_core_claim_readiness.json', {
      'blockingFindings': ['trade_not_ready:hvac', 'mac_wave_not_merge_ready'],
      'nextActions': [
        'Keep the hvac Mac wave running until peh_core_mac_wave_status.json marks it readyToMerge.',
      ],
    });
    _writeJson('build/parser_qa_pipeline/peh_core_handoff_readiness.json', {
      'readyForMacMeasurementWave': true,
      'readyToClaimNinetyPlus': false,
      'nextActions': [
        'Keep the branch below a 90-95 percent claim until the hvac remaining measured Mac wave clears.',
      ],
    });

    final refreshExit = runReusableParsingQaHandoffRefresh(
      const [
        '--root',
        '.',
        '--branch',
        'codex/reusable-parsing-qa-foundation',
        '--commit',
        '8e9771d',
        '--commit-full',
        '8e9771d922e67927cf5dc9efacfe213a542202cb',
        '--label',
        'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
        '--updated-at',
        '2026-07-09 11:58 PM EDT',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );
    expect(refreshExit, 0);

    final checkpointExit = runReusableParsingQaHandoffCheckpoint(
      const ['--root', '.'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );
    expect(checkpointExit, 0);

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = runWorkSupplyParserQaFinalizeLiveHandoff(
      const [
        '--root',
        '.',
        '--branch',
        'codex/reusable-parsing-qa-foundation',
        '--commit',
        '8e9771d',
        '--commit-full',
        '8e9771d922e67927cf5dc9efacfe213a542202cb',
        '--label',
        'Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion',
        '--updated-at',
        '2026-07-09 11:58 PM EDT',
      ],
      stdout: stdout,
      stderr: stderr,
    );

    expect(exit, 0);
    expect(stderr.content, isEmpty);
    expect(stdout.content, contains('QA_PARSER_LIVE_HANDOFF_FINALIZE'));

    final payload = _extractJsonPayload(stdout.content);
    expect(payload['restampExit'], 0);
    expect(payload['syncExit'], 0);
    expect(payload['summaryExit'], 0);
    expect(payload['handoffClean'], isTrue);
    expect(payload['packetExecutionHeadAligned'], isTrue);
    expect(payload['scriptExecutionHeadAligned'], isTrue);
    expect(payload['expectedLocalDocsRefreshDirty'], isA<bool>());
    expect(
      payload['localModifiedFiles'].toString(),
      contains('docs/'),
    );
  });
}

Map<String, Object?> _extractJsonPayload(String stdout) {
  const prefix = 'QA_PARSER_LIVE_HANDOFF_FINALIZE ';
  expect(stdout, contains(prefix));
  final start = stdout.indexOf(prefix);
  final jsonText = stdout.substring(start + prefix.length).trim();
  return jsonDecode(jsonText) as Map<String, Object?>;
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
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
