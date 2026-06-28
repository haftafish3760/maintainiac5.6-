import 'dart:io';

Future<void> main(List<String> args) async {
  final parsed = _BuilderArgs.parse(args);
  if (parsed.help) {
    _printUsage();
    return;
  }

  final environment = {
    ...Platform.environment,
    'MAINTAINIAC_PACK_TRADE': parsed.trade,
    'MAINTAINIAC_PACK_TIER': parsed.tier,
    'MAINTAINIAC_PACK_ALL': parsed.all ? 'true' : 'false',
    if (parsed.outPath != null) 'MAINTAINIAC_PACK_OUT': parsed.outPath!,
  };
  final process = await Process.start(
    'flutter',
    const [
      'test',
      'test/work_supply_trade_pack_builder_report_test.dart',
      '--plain-name',
      'exports requested trade packs',
    ],
    mode: ProcessStartMode.inheritStdio,
    environment: environment,
  );
  exitCode = await process.exitCode;
}

class _BuilderArgs {
  const _BuilderArgs({
    required this.trade,
    required this.tier,
    required this.all,
    required this.help,
    this.outPath,
  });

  final String trade;
  final String tier;
  final bool all;
  final bool help;
  final String? outPath;

  static _BuilderArgs parse(List<String> args) {
    var trade = 'Plumbing';
    var tier = 'complete';
    var all = false;
    var help = false;
    String? outPath;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg == '--all') {
        all = true;
      } else if (arg == '--trade' && i + 1 < args.length) {
        trade = args[++i];
      } else if (arg == '--tier' && i + 1 < args.length) {
        tier = args[++i];
      } else if (arg == '--out' && i + 1 < args.length) {
        outPath = args[++i];
      }
    }

    return _BuilderArgs(
      trade: trade,
      tier: tier,
      all: all,
      help: help,
      outPath: outPath,
    );
  }
}

void _printUsage() {
  stdout.writeln(
    'Build and validate local Maintainiac work-supply trade packs.',
  );
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run tool/work_supply_trade_pack_builder.dart');
  stdout.writeln(
    '  dart run tool/work_supply_trade_pack_builder.dart --trade Plumbing --tier complete',
  );
  stdout.writeln(
    '  dart run tool/work_supply_trade_pack_builder.dart --all --out /tmp/packs',
  );
  stdout.writeln('');
  stdout.writeln(
    'Options: --trade NAME --tier core|standard|professional|complete --all --out DIR',
  );
}
