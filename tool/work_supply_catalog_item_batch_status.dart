import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_catalog_item_batch_status.dart '
    '[--blueprint-root build/parser_qa_blueprints] '
    '[--trades plumbing,electrical,hvac] [--scopes residential] '
    '[--tiers core,standard] [--locales en-US,es-US] '
    '[--output build/parser_qa_pipeline/item_batch_status.json] '
    '[--require-complete]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyCatalogItemBatchStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyCatalogItemBatchStatus(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _Options.parse(args);
  final cells = <Map<String, Object?>>[];
  var missing = 0;
  var unsafe = 0;
  var generatedItemCount = 0;
  var manualReviewRequiredCount = 0;

  for (final trade in options.trades) {
    for (final scope in options.scopes) {
      for (final tier in options.tiers) {
        for (final locale in options.locales) {
          final cell = _readCell(options, trade, scope, tier, locale);
          cells.add(cell);
          if (cell['status'] == 'missing') missing++;
          if (cell['localOnlySafe'] == false) unsafe++;
          generatedItemCount += (cell['generatedCount'] as int?) ?? 0;
          if (cell['promotionMode'] == 'review-required' ||
              cell['promotionMode'] == 'manual-review-required') {
            manualReviewRequiredCount++;
          }
        }
      }
    }
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_catalog_item_batch_status',
    'blueprintRoot': options.blueprintRoot,
    'expectedCells': cells.length,
    'presentCells': cells.length - missing,
    'missingCells': missing,
    'unsafeCells': unsafe,
    'generatedItemCount': generatedItemCount,
    'manualReviewRequiredCells': manualReviewRequiredCount,
    'requireComplete': options.requireComplete,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'cells': cells,
  };

  final output = File(options.output)..parent.createSync(recursive: true);
  output.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      ...summary,
      'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
    }),
    flush: true,
  );
  stdout.writeln(
    'QA_CATALOG_ITEM_BATCH_STATUS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_CATALOG_ITEM_BATCH_STATUS_ARTIFACT json=${output.path}');

  if (unsafe > 0) return 1;
  if (options.requireComplete && missing > 0) return 2;
  return 0;
}

Map<String, Object?> _readCell(
  _Options options,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  final root =
      '${options.blueprintRoot}/work_supply_catalog/$trade/$scope/$tier/$locale';
  final manifestPath = '$root/manifest.json';
  final blueprintPath = '$root/item_blueprints.json';
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    return _cell(
      trade: trade,
      scope: scope,
      tier: tier,
      locale: locale,
      status: 'missing',
      manifestPath: manifestPath,
      blueprintPath: blueprintPath,
      localOnlySafe: true,
      resumeCommand: _resumeCommand(options, trade, scope, tier, locale),
    );
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  final matchesRequestedCell =
      manifest['trade'] == trade &&
      manifest['marketScope'] == scope &&
      manifest['tier'] == tier &&
      manifest['localePackId'] == locale;
  final localOnlySafe =
      manifest['liveServicesAllowed'] == false &&
      manifest['writesProductionCatalog'] == false &&
      manifest['firebaseWritesAllowed'] == false;
  return _cell(
    trade: trade,
    scope: scope,
    tier: tier,
    locale: locale,
    status: matchesRequestedCell ? 'present' : 'mismatched',
    manifestPath: manifestPath,
    blueprintPath: blueprintPath,
    blueprintExists: File(blueprintPath).existsSync(),
    localOnlySafe: localOnlySafe,
    generatedCount: (manifest['generatedCount'] as int?) ?? 0,
    requestedLimit: (manifest['requestedLimit'] as int?) ?? 0,
    promotionMode: manifest['promotionMode']?.toString(),
    resumeCommand: _resumeCommand(options, trade, scope, tier, locale),
  );
}

Map<String, Object?> _cell({
  required String trade,
  required String scope,
  required String tier,
  required String locale,
  required String status,
  required String manifestPath,
  required String blueprintPath,
  required bool localOnlySafe,
  required String resumeCommand,
  bool blueprintExists = false,
  int generatedCount = 0,
  int requestedLimit = 0,
  String? promotionMode,
}) {
  return {
    'cellId': '${trade}_${scope}_${tier}_${locale.replaceAll('-', '_')}',
    'trade': trade,
    'marketScope': scope,
    'tier': tier,
    'localePackId': locale,
    'status': status,
    'manifestPath': manifestPath,
    'blueprintPath': blueprintPath,
    'blueprintExists': blueprintExists,
    'generatedCount': generatedCount,
    'requestedLimit': requestedLimit,
    'promotionMode': promotionMode ?? 'unknown',
    'localOnlySafe': localOnlySafe,
    'resumeCommand': resumeCommand,
  };
}

String _resumeCommand(
  _Options options,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  return 'dart run tool/work_supply_catalog_blueprint_generator.dart '
      '--trade $trade --scope $scope --tier $tier --locale $locale '
      '--output-dir ${options.blueprintRoot}';
}

class _Options {
  const _Options({
    required this.blueprintRoot,
    required this.trades,
    required this.scopes,
    required this.tiers,
    required this.locales,
    required this.output,
    required this.requireComplete,
  });

  final String blueprintRoot;
  final List<String> trades;
  final List<String> scopes;
  final List<String> tiers;
  final List<String> locales;
  final String output;
  final bool requireComplete;

  static _Options parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final key = arg.substring(2);
      if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
        values[key] = args[++index];
      } else {
        flags.add(key);
      }
    }
    return _Options(
      blueprintRoot: values['blueprint-root'] ?? 'build/parser_qa_blueprints',
      trades: _csv(values['trades'] ?? 'plumbing,electrical,hvac'),
      scopes: _csv(values['scopes'] ?? 'residential'),
      tiers: _csv(values['tiers'] ?? 'core,standard'),
      locales: _csv(values['locales'] ?? 'en-US,es-US'),
      output:
          values['output'] ?? 'build/parser_qa_pipeline/item_batch_status.json',
      requireComplete: flags.contains('require-complete'),
    );
  }

  static List<String> _csv(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}
