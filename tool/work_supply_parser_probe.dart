import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main(List<String> args) {
  final options = _ProbeOptions.parse(args);
  if (options.showHelp || options.line.trim().isEmpty) {
    stdout.writeln(_ProbeOptions.usage);
    if (options.line.trim().isEmpty && !options.showHelp) {
      exitCode = 64;
    }
    return;
  }

  final match = matchReceiptLineToCatalog(
    options.line,
    tradeScope: options.tradeScope,
    maxCandidates: options.maxCandidates,
    localePackId: options.localePackId,
  );

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'line': options.line,
      'tradeScope': options.tradeScope,
      'localePackId': options.localePackId,
      'maxCandidates': options.maxCandidates,
      'matched': match != null,
      'item': match == null
          ? null
          : {
              'name': match.item.name,
              'trade': match.item.trade,
              'packTier': match.item.packTier.name,
              'system': match.item.system,
              'itemType': match.item.itemType,
              'variant': match.item.variant,
              'path': match.item.path,
              'aliases': match.item.aliases,
            },
      'confidence': match?.confidence,
      'confidenceLevel': match?.confidenceLevel.name,
      'matchedTerms': match?.matchedTerms,
    }),
  );
}

class _ProbeOptions {
  const _ProbeOptions({
    required this.line,
    required this.tradeScope,
    required this.localePackId,
    required this.maxCandidates,
    required this.showHelp,
  });

  static const usage =
      'flutter pub run tool/work_supply_parser_probe.dart '
      '--line "LOCAL HDW 8 OZ PVC GLUE 71.90 94.77" '
      '[--trade Plumbing] [--locale en-US] [--max-candidates 420]';

  final String line;
  final String tradeScope;
  final String localePackId;
  final int maxCandidates;
  final bool showHelp;

  static _ProbeOptions parse(List<String> args) {
    String valueFor(String name) {
      for (var i = 0; i < args.length; i++) {
        final arg = args[i];
        if (arg == '--$name' && i + 1 < args.length) return args[i + 1];
        if (arg.startsWith('--$name=')) return arg.substring(name.length + 3);
      }
      return '';
    }

    final maxCandidates = int.tryParse(valueFor('max-candidates')) ?? 420;

    return _ProbeOptions(
      line: valueFor('line'),
      tradeScope: valueFor('trade').isEmpty ? 'Plumbing' : valueFor('trade'),
      localePackId: valueFor('locale'),
      maxCandidates: maxCandidates,
      showHelp: args.contains('--help') || args.contains('-h'),
    );
  }
}
