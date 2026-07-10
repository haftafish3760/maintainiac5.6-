import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_claim_readiness.dart '
    '[--windows-status build/parser_qa_pipeline/peh_core_windows_status_rollup.json] '
    '[--mac-wave-status build/parser_qa_pipeline/peh_core_mac_wave_status.json] '
    '[--output build/parser_qa_pipeline/peh_core_claim_readiness.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreClaimReadiness(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreClaimReadiness(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final windowsStatusPath = _value(
    args,
    'windows-status',
    'build/parser_qa_pipeline/peh_core_windows_status_rollup.json',
  );
  final macWaveStatusPath = _value(
    args,
    'mac-wave-status',
    'build/parser_qa_pipeline/peh_core_mac_wave_status.json',
  );
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_claim_readiness.json',
  );

  final windowsFile = File(windowsStatusPath);
  final macWaveStatusFile = File(macWaveStatusPath);
  if (!windowsFile.existsSync() || !macWaveStatusFile.existsSync()) {
    stderr.writeln('--windows-status and --mac-wave-status must both exist.');
    return 66;
  }

  final windows =
      jsonDecode(windowsFile.readAsStringSync()) as Map<String, Object?>;
  final macWaveStatus =
      jsonDecode(macWaveStatusFile.readAsStringSync()) as Map<String, Object?>;

  final blockingFindings = <String>[];
  final nextActions = <String>[];

  final windowsTrades =
      (windows['trades'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => entry.cast<String, Object?>())
          .toList();
  Map<String, Object?>? windowsTrade(String tradeName) =>
      windowsTrades.where((trade) => trade['trade'] == tradeName).firstOrNull;
  final plumbing = windowsTrade('plumbing');
  if (plumbing == null) {
    blockingFindings.add('missing_plumbing_windows_trade');
  }

  final macTrades =
      (macWaveStatus['tradeStatuses'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => entry.cast<String, Object?>())
          .toList();
  Map<String, Object?>? macTrade(String tradeName) =>
      macTrades.where((trade) => trade['trade'] == tradeName).firstOrNull;

  final tradeClaims = <Map<String, Object?>>[];

  bool addWindowsTradeClaim(String tradeName, Map<String, Object?>? trade) {
    if (trade == null) return false;
    final ready = trade['readyToClaimNinetyPlus'] == true;
    if (!ready) {
      blockingFindings.add('trade_not_ready:$tradeName');
      nextActions.add(
        'Keep expanding or repairing $tradeName evidence until the Windows PEH rollup marks it readyToClaimNinetyPlus.',
      );
    }
    tradeClaims.add({
      'trade': tradeName,
      'source': 'windows_rollup',
      'checkedTotal': (trade['checkedTotal'] as int?) ?? 0,
      'failureCount': (trade['failureCount'] as int?) ?? 0,
      'passRate': (trade['passRate'] as num?)?.toDouble() ?? 0.0,
      'readyToClaimNinetyPlus': ready,
    });
    return ready;
  }

  bool addMacTradeClaim(String tradeName, Map<String, Object?>? trade) {
    if (trade == null) {
      blockingFindings.add('missing_mac_trade_status:$tradeName');
      nextActions.add(
        'Generate the $tradeName Mac wave rollup and refresh peh_core_mac_wave_status.json before attempting a PEH claim.',
      );
      return false;
    }
    final ready = trade['readyToMerge'] == true;
    if (!ready) {
      blockingFindings.add('trade_not_ready:$tradeName');
      nextActions.add(
        'Keep the $tradeName Mac wave running until peh_core_mac_wave_status.json marks it readyToMerge.',
      );
    }
    tradeClaims.add({
      'trade': tradeName,
      'source': 'mac_wave_status',
      'checkedTotal': (trade['checkedTotal'] as int?) ?? 0,
      'failureCount': (trade['failureCount'] as int?) ?? 0,
      'passRate': (trade['passRate'] as num?)?.toDouble() ?? 0.0,
      'readyToClaimNinetyPlus': ready,
    });
    return ready;
  }

  bool addPreferredTradeClaim(String tradeName) {
    final windowsTradeStatus = windowsTrade(tradeName);
    if (windowsTradeStatus != null &&
        windowsTradeStatus['readyToClaimNinetyPlus'] == true) {
      return addWindowsTradeClaim(tradeName, windowsTradeStatus);
    }
    return addMacTradeClaim(tradeName, macTrade(tradeName));
  }

  final plumbingReady = addWindowsTradeClaim('plumbing', plumbing);
  final electricalReady = addPreferredTradeClaim('electrical');
  final hvacReady = addPreferredTradeClaim('hvac');

  final usesMacWave = tradeClaims.any(
    (claim) => claim['source'] == 'mac_wave_status',
  );
  if (usesMacWave && macWaveStatus['readyToMergeIntoClaim'] != true) {
    blockingFindings.add('mac_wave_not_merge_ready');
    nextActions.add(
      'Do not claim PEH 90-95 percent readiness until peh_core_mac_wave_status.json reports readyToMergeIntoClaim=true.',
    );
  }

  final readyToClaimNinetyPlus =
      plumbingReady &&
      electricalReady &&
      hvacReady &&
      (!usesMacWave || macWaveStatus['readyToMergeIntoClaim'] == true);

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_claim_readiness',
    'windowsStatusPath': windowsStatusPath,
    'macWaveStatusPath': macWaveStatusPath,
    'tradeClaimCount': tradeClaims.length,
    'readyToClaimNinetyPlus': readyToClaimNinetyPlus,
    'readyToClaimNinetyFive': false,
    'tradeClaims': tradeClaims,
    'blockingFindings': blockingFindings.toSet().toList(),
    'nextActions': nextActions.toSet().toList(),
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_CLAIM_READINESS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_PEH_CORE_CLAIM_READINESS_ARTIFACT json=${outputFile.path}',
  );
  return readyToClaimNinetyPlus ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

extension on Iterable<Map<String, Object?>> {
  Map<String, Object?>? get firstOrNull => isEmpty ? null : first;
}
