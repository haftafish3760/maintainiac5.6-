import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_peh_core_claim_readiness.dart';

void main() {
  test('PEH claim readiness passes when plumbing and Mac trade evidence are ready', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_claim_ready_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
      'trades': [
        {
          'trade': 'plumbing',
          'checkedTotal': 100,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToClaimNinetyPlus': true,
        },
      ],
    });
    _writeJson('build/parser_qa_pipeline/mac_wave_status.json', {
      'readyToMergeIntoClaim': true,
      'tradeStatuses': [
        {
          'trade': 'electrical',
          'checkedTotal': 50,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToMerge': true,
        },
        {
          'trade': 'hvac',
          'checkedTotal': 50,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToMerge': true,
        },
      ],
    });

    final stdout = _MemorySink();
    final exit = runWorkSupplyParserQaPehCoreClaimReadiness(
      const [
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--mac-wave-status',
        'build/parser_qa_pipeline/mac_wave_status.json',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_claim_readiness.json',
    );
    expect(summary['readyToClaimNinetyPlus'], isTrue);
    expect(summary['tradeClaimCount'], 3);
    expect(summary['blockingFindings'], isEmpty);
    expect(stdout.content, contains('QA_PEH_CORE_CLAIM_READINESS'));
  });

  test('PEH claim readiness prefers Windows trade proof before Mac fallback', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_claim_windows_preferred_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
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
    _writeJson('build/parser_qa_pipeline/mac_wave_status.json', {
      'readyToMergeIntoClaim': true,
      'tradeStatuses': [
        {
          'trade': 'electrical',
          'checkedTotal': 0,
          'failureCount': 0,
          'passRate': 0.0,
          'readyToMerge': false,
        },
        {
          'trade': 'hvac',
          'checkedTotal': 50,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToMerge': true,
        },
      ],
    });

    final exit = runWorkSupplyParserQaPehCoreClaimReadiness(
      const [
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--mac-wave-status',
        'build/parser_qa_pipeline/mac_wave_status.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_claim_readiness.json',
    );
    expect(summary['readyToClaimNinetyPlus'], isTrue);
    expect(summary['blockingFindings'], isEmpty);
    expect(summary['tradeClaims'].toString(), contains('windows_rollup'));
    expect(summary['tradeClaims'].toString(), contains('mac_wave_status'));
  });

  test('PEH claim readiness blocks missing or incomplete trade evidence', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_peh_claim_blocked_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeJson('build/parser_qa_pipeline/windows.json', {
      'trades': [
        {
          'trade': 'plumbing',
          'checkedTotal': 100,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToClaimNinetyPlus': false,
        },
      ],
    });
    _writeJson('build/parser_qa_pipeline/mac_wave_status.json', {
      'readyToMergeIntoClaim': false,
      'tradeStatuses': [
        {
          'trade': 'electrical',
          'checkedTotal': 25,
          'failureCount': 0,
          'passRate': 1.0,
          'readyToMerge': false,
        },
      ],
    });

    final exit = runWorkSupplyParserQaPehCoreClaimReadiness(
      const [
        '--windows-status',
        'build/parser_qa_pipeline/windows.json',
        '--mac-wave-status',
        'build/parser_qa_pipeline/mac_wave_status.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    final summary = _readJson(
      'build/parser_qa_pipeline/peh_core_claim_readiness.json',
    );
    expect(summary['readyToClaimNinetyPlus'], isFalse);
    expect(
      summary['blockingFindings'].toString(),
      contains('trade_not_ready:plumbing'),
    );
    expect(
      summary['blockingFindings'].toString(),
      contains('trade_not_ready:electrical'),
    );
    expect(
      summary['blockingFindings'].toString(),
      contains('missing_mac_trade_status:hvac'),
    );
    expect(
      summary['blockingFindings'].toString(),
      contains('mac_wave_not_merge_ready'),
    );
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
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
