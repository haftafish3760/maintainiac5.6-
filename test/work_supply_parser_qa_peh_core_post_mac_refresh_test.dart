import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart';

void main() {
  test(
    'post Mac refresh rebuilds PEH and reusable handoff artifacts together',
    () {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_peh_post_mac_refresh_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final previous = Directory.current;
      Directory.current = root;
      addTearDown(() => Directory.current = previous);

      Process.runSync('git', ['init']);
      Process.runSync('git', ['config', 'user.email', 'qa@example.com']);
      Process.runSync('git', ['config', 'user.name', 'QA Bot']);
      File('README.txt').writeAsStringSync('post-mac refresh');
      Process.runSync('git', ['add', 'README.txt']);
      Process.runSync('git', ['commit', '-m', 'init']);
      Process.runSync(
        'git',
        ['checkout', '-B', 'codex/inventory-parser-backup-20260702-2056'],
      );

      final headShort =
          Process.runSync('git', ['rev-parse', '--short', 'HEAD']).stdout
              .toString()
              .trim();

      _writeJson('docs/reusable_parsing_qa_mac_handoff_packet.json', {
        'primaryBranch': 'codex/reusable-parsing-qa-foundation',
        'baselineCommit': 'abc1234',
        'baselineCommitFull': 'abc1234full',
        'baselineCommitLabel': 'Reusable parsing QA validated floor',
        'scopeBoundaryPath': 'docs/reusable_parsing_qa_scope_boundary.md',
        'checkpointJsonPath': 'docs/reusable_parsing_qa_checkpoint.json',
        'checkpointMarkdownPath': 'docs/reusable_parsing_qa_checkpoint.md',
        'windowsCheckpointSyncCommand':
            'dart run tool/reusable_parsing_qa_handoff_sync.dart --root .',
        'handoffMarkerPath': 'docs/reusable_parsing_qa_handoff_marker.md',
        'runbookPath': 'docs/reusable_parsing_qa_mac_runbook.md',
      });

      _writeJson('build/parser_qa_pipeline/peh_core_measurement_gap.json', {
        'readyForMacMeasurementWave': true,
        'totalRemainingChecked': 38,
        'nextTradesByRemainingGap': ['hvac'],
        'tradeGaps': [
          {'trade': 'hvac', 'remainingChecked': 38},
        ],
      });
      _writeJson('build/parser_qa_pipeline/peh_core_handoff_readiness.json', {
        'readyForMacMeasurementWave': true,
        'readyToClaimNinetyPlus': false,
        'nextActions': [
          'Keep the branch below a 90-95 percent claim until the hvac remaining measured Mac wave clears.',
        ],
      });
      _writeJson('build/parser_qa_pipeline/peh_core_windows_status_rollup.json', {
        'sampleSizedTradeCount': 1,
        'underTargetTradeCount': 1,
        'readyForMacMeasurementWave': true,
        'readyToClaimNinetyPlus': false,
        'trades': [
          {
            'trade': 'plumbing',
            'checkedTotal': 100,
            'failureCount': 0,
            'passRate': 1.0,
            'readyToClaimNinetyPlus': true,
          },
          {
            'trade': 'electrical',
            'checkedTotal': 50,
            'failureCount': 0,
            'passRate': 1.0,
            'readyToClaimNinetyPlus': true,
          },
        ],
      });
      _writeJson('build/parser_qa_pipeline/peh_core_mac_wave_commands.json', {
        'selectedTrades': ['hvac'],
        'maxCases': 25,
        'minPassRate': 0.90,
        'measurementCommandCount': 2,
        'rollupCommandCount': 1,
        'measurementCommands': [
          {'trade': 'hvac', 'localePackId': 'en-US'},
          {'trade': 'hvac', 'localePackId': 'es-US'},
        ],
        'rollupCommands': [
          {
            'trade': 'hvac',
            'command': [
              'dart',
              'run',
              'tool/work_supply_parser_qa_generated_run_status.dart',
              '--output',
              'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
            ],
          },
        ],
      });
      _writeJson('build/parser_qa_pipeline/peh_core_claim_readiness.json', {
        'readyToClaimNinetyPlus': false,
        'blockingFindings': ['trade_not_ready:hvac', 'mac_wave_not_merge_ready'],
        'nextActions': ['Keep the hvac Mac wave running.'],
      });
      _writeJson('build/parser_qa_pipeline/peh_core_mac_handoff_packet.json', {
        'reusableBaselineBranch': 'codex/reusable-parsing-qa-foundation',
        'reusableValidatedFloorCommit': 'abc1234',
        'inventoryExecutionBranch': 'codex/inventory-parser-backup-20260702-2056',
        'inventoryExecutionCommit': headShort,
        'branch': 'codex/inventory-parser-backup-20260702-2056',
        'commit': headShort,
        'readyForMacMeasurementWave': true,
        'readyToClaimNinetyPlus': false,
        'totalRemainingChecked': 38,
        'nextTradesByRemainingGap': ['hvac'],
        'measurementCommandCount': 2,
        'rollupCommandCount': 1,
        'selectedTrades': ['hvac'],
        'measurementCommands': [
          {'trade': 'hvac', 'command': ['dart', 'run', 'tool/a.dart']},
        ],
        'rollupCommands': [
          {
            'trade': 'hvac',
            'command': [
              'dart',
              'run',
              'tool/work_supply_parser_qa_generated_run_status.dart',
              '--output',
              'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
            ],
          },
        ],
        'expectedOutputs': [
          'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
          'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
          'build/parser_qa_pipeline/peh_core_merged_status_rollup.json',
          'build/parser_qa_pipeline/peh_core_claim_readiness.json',
        ],
      });
      File('build/parser_qa_pipeline/peh_core_mac_handoff.sh')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('''
#!/usr/bin/env bash
# Branch: codex/inventory-parser-backup-20260702-2056
# Commit: $headShort
''');

      _writeStatus(
        'build/parser_qa_pipeline/plumbing_core_generated_run_status.json',
        checkedTotal: 100,
      );
      _writeStatus(
        'build/parser_qa_pipeline/windows_electrical_core_generated_run_status_50.json',
        checkedTotal: 50,
      );
      _writeStatus(
        'build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json',
        checkedTotal: 12,
      );

      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = runWorkSupplyParserQaPehCorePostMacRefresh(
        const ['--root', '.'],
        stdout: stdout,
        stderr: stderr,
      );

      expect(
        exit,
        greaterThan(0),
        reason: 'stdout:\n${stdout.content}\n\nstderr:\n${stderr.content}',
      );
      expect(stdout.content, contains('QA_PEH_CORE_POST_MAC_REFRESH'));

      final payload = _extractJsonPayload(stdout.content);
      expect(
        payload['handoffClean'],
        isTrue,
        reason: 'payload:\n${const JsonEncoder.withIndent('  ').convert(payload)}',
      );
      expect(payload['readyToClaimNinetyPlus'], isFalse);
      expect(payload['totalRemainingChecked'], 38);
      expect(payload['nextTradesByRemainingGap'].toString(), contains('hvac'));
      expect(
        payload['claimBlockingFindings'].toString(),
        contains('trade_not_ready:hvac'),
      );

      final refreshedPacket = _readJson(
        'docs/reusable_parsing_qa_mac_handoff_packet.json',
      );
      final checkpoint = _readJson('docs/reusable_parsing_qa_checkpoint.json');
      final waveStatus = _readJson(
        'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
      );
      final claim = _readJson(
        'build/parser_qa_pipeline/peh_core_claim_readiness.json',
      );

      expect(refreshedPacket['baselineCommit'], 'abc1234');
      expect(checkpoint['totalRemainingChecked'], 38);
      expect(waveStatus['readyToMergeIntoClaim'], isFalse);
      expect(claim['readyToClaimNinetyPlus'], isFalse);
    },
  );
}

Map<String, Object?> _extractJsonPayload(String stdout) {
  const prefix = 'QA_PEH_CORE_POST_MAC_REFRESH ';
  expect(stdout, contains(prefix));
  final start = stdout.indexOf(prefix);
  final jsonText = stdout.substring(start + prefix.length).trim();
  return jsonDecode(jsonText) as Map<String, Object?>;
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
}

void _writeStatus(
  String path, {
  required int checkedTotal,
  int failureCount = 0,
  double passRate = 1.0,
  int parserCalls = 12,
  bool liveServicesAllowed = false,
  bool writesProductionCatalog = false,
  bool firebaseWritesAllowed = false,
  bool ocrCameraExpensesTouched = false,
  int unsafeCells = 0,
  int underMinCheckedCells = 0,
  int underMinPassRateCells = 0,
}) {
  _writeJson(path, {
    'checkedTotal': checkedTotal,
    'failureCount': failureCount,
    'passRate': passRate,
    'parserCalls': parserCalls,
    'unsafeCells': unsafeCells,
    'underMinCheckedCells': underMinCheckedCells,
    'underMinPassRateCells': underMinPassRateCells,
    'liveServicesAllowed': liveServicesAllowed,
    'writesProductionCatalog': writesProductionCatalog,
    'firebaseWritesAllowed': firebaseWritesAllowed,
    'ocrCameraExpensesTouched': ocrCameraExpensesTouched,
  });
}

Map<String, Object?> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
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
