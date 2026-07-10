import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_supported_matrix.dart '
    '[--output build/parser_qa_pipeline/supported_matrix.json]';

const _supportedTrades = ['plumbing', 'electrical', 'hvac'];
const _supportedScopes = ['residential'];
const _supportedTiers = ['core', 'standard', 'professional', 'complete'];
const _supportedLocales = ['en-US', 'es-US'];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaSupportedMatrix(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaSupportedMatrix(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final output = _value(args, 'output');
  final cells = [
    for (final cell in _supportedCells())
      for (final locale in _supportedLocales)
        {
          'trade': cell.trade,
          'marketScope': cell.scope,
          'tier': cell.tier,
          'localePackId': locale,
          'generatorReady': true,
          'fixtureReady': true,
          'parserRunReady': true,
          'writesProductionCatalog': false,
          'liveServicesAllowed': false,
        },
  ];
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_supported_matrix',
    'cellCount': cells.length,
    'supportedTrades': _supportedTrades,
    'supportedScopes': _supportedScopes,
    'supportedTiers': _supportedTiers,
    'supportedLocales': _supportedLocales,
    'unsupportedPolicy': 'fail-before-writing-files',
    'releaseOneCoverage':
        'residential-top-three-trades-all-tiers-en-US-es-US',
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'cells': cells,
  };
  final json = const JsonEncoder.withIndent('  ').convert(summary);
  if (output.isNotEmpty) {
    final file = File(output)..parent.createSync(recursive: true);
    file.writeAsStringSync(json, flush: true);
  }
  stdout.writeln('QA_SUPPORTED_MATRIX $json');
  return 0;
}

List<({String trade, String scope, String tier})> _supportedCells() {
  return const [
    (trade: 'plumbing', scope: 'residential', tier: 'core'),
    (trade: 'plumbing', scope: 'residential', tier: 'standard'),
    (trade: 'plumbing', scope: 'residential', tier: 'professional'),
    (trade: 'plumbing', scope: 'residential', tier: 'complete'),
    (trade: 'electrical', scope: 'residential', tier: 'core'),
    (trade: 'electrical', scope: 'residential', tier: 'standard'),
    (trade: 'electrical', scope: 'residential', tier: 'professional'),
    (trade: 'electrical', scope: 'residential', tier: 'complete'),
    (trade: 'hvac', scope: 'residential', tier: 'core'),
    (trade: 'hvac', scope: 'residential', tier: 'standard'),
    (trade: 'hvac', scope: 'residential', tier: 'professional'),
    (trade: 'hvac', scope: 'residential', tier: 'complete'),
  ];
}

String _value(List<String> args, String key) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return '';
}
