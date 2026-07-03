import 'maintainiac_surgical_test_selector.dart';

class MaintainiacIndividualTestEntry {
  const MaintainiacIndividualTestEntry({
    required this.id,
    required this.module,
    required this.riskFamily,
    required this.command,
    required this.owner,
    required this.whenToRun,
  });

  final String id;
  final String module;
  final String riskFamily;
  final String command;
  final String owner;
  final String whenToRun;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('individual test missing id');
    }
    if (module.trim().isEmpty) {
      failures.add('$id missing module');
    }
    if (riskFamily.trim().isEmpty) {
      failures.add('$id missing risk family');
    }
    if (owner.trim().isEmpty) {
      failures.add('$id missing owner');
    }
    if (whenToRun.trim().isEmpty) {
      failures.add('$id missing run guidance');
    }
    if (!command.startsWith('flutter test test/')) {
      failures.add('$id must be a focused Flutter test command');
    }
    if (!command.contains(' --plain-name ')) {
      failures.add('$id must use --plain-name for surgical reruns');
    }
    if (command.contains('&&') ||
        command.contains(';') ||
        command.contains('|')) {
      failures.add('$id must not chain commands');
    }
    final lower = command.toLowerCase();
    if (lower.contains('googlevision') ||
        lower.contains('mlkit') ||
        lower.contains('camera') ||
        lower.contains('ocr') ||
        lower.contains('firebase') ||
        lower.contains('firestore')) {
      failures.add('$id must not touch OCR/camera/live cloud providers');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module,
      'riskFamily': riskFamily,
      'command': command,
      'owner': owner,
      'whenToRun': whenToRun,
    };
  }
}

class MaintainiacIndividualTestManifest {
  const MaintainiacIndividualTestManifest(this.entries);

  final List<MaintainiacIndividualTestEntry> entries;

  factory MaintainiacIndividualTestManifest.fromSelectors(
    MaintainiacSurgicalTestSelectorRegistry registry,
  ) {
    return MaintainiacIndividualTestManifest([
      for (final selector in registry.selectors)
        MaintainiacIndividualTestEntry(
          id: selector.id,
          module: _moduleFor(selector),
          riskFamily: _riskFamilyFor(selector),
          command: selector.command,
          owner: 'qa_backbone',
          whenToRun: selector.reason,
        ),
    ]);
  }

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final commands = <String>{};
    final modules = <String>{};
    final riskFamilies = <String>{};
    for (final entry in entries) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate individual test id ${entry.id}');
      }
      if (!commands.add(entry.command)) {
        failures.add('duplicate individual test command ${entry.command}');
      }
      modules.add(entry.module);
      riskFamilies.add(entry.riskFamily);
      failures.addAll(entry.validate());
    }
    for (final required in {
      'inventory',
      'expenses',
      'parser',
      'security',
      'regression',
      'release',
    }) {
      if (!modules.contains(required) && !riskFamilies.contains(required)) {
        failures.add('individual test manifest missing $required coverage');
      }
    }
    return failures;
  }

  List<String> commandsForRiskFamily(String riskFamily) {
    return [
      for (final entry in entries)
        if (entry.riskFamily == riskFamily) entry.command,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'entryCount': entries.length,
      'modules': ({for (final entry in entries) entry.module}.toList()..sort()),
      'riskFamilies': ({for (final entry in entries) entry.riskFamily}.toList()
        ..sort()),
      'entries': [for (final entry in entries) entry.toJson()],
    };
  }
}

String _moduleFor(MaintainiacSurgicalTestSelector selector) {
  if (selector.file.contains('inventory_parser_consumer')) {
    return 'inventory';
  }
  if (selector.file.contains('expense_parser_consumer')) {
    return 'expenses';
  }
  if (selector.file.contains('parser_consumer') ||
      selector.file.contains('parser_regression') ||
      selector.file.contains('parser_release') ||
      selector.file.contains('surgical_') ||
      selector.file.contains('qa_backbone')) {
    return 'parser';
  }
  if (selector.tags.contains('inventory')) {
    return 'inventory';
  }
  if (selector.tags.contains('expenses')) {
    return 'expenses';
  }
  if (selector.tags.contains('security') || selector.tags.contains('privacy')) {
    return 'security';
  }
  if (selector.tags.contains('payments')) {
    return 'payments';
  }
  if (selector.tags.contains('financial')) {
    return 'financial';
  }
  if (selector.tags.contains('performance')) {
    return 'performance';
  }
  if (selector.tags.contains('sync')) {
    return 'sync';
  }
  if (selector.tags.contains('environment') ||
      selector.tags.contains('builders') ||
      selector.tags.contains('fixtures') ||
      selector.tags.contains('assertions') ||
      selector.tags.contains('audit')) {
    return 'qa-backbone';
  }
  return 'parser';
}

String _riskFamilyFor(MaintainiacSurgicalTestSelector selector) {
  if (selector.tags.contains('financial')) {
    return 'financial';
  }
  if (selector.tags.contains('performance')) {
    return 'performance';
  }
  if (selector.tags.contains('fixtures')) {
    return 'fixtures';
  }
  if (selector.tags.contains('audit')) {
    return 'audit';
  }
  if (selector.tags.contains('sync')) {
    return 'sync';
  }
  if (selector.tags.contains('regression')) {
    return 'regression';
  }
  if (selector.tags.contains('security')) {
    return 'security';
  }
  if (selector.tags.contains('privacy')) {
    return 'privacy';
  }
  if (selector.tags.contains('source-of-truth')) {
    return 'source-of-truth';
  }
  if (selector.tags.contains('privacy')) {
    return 'privacy';
  }
  if (selector.tags.contains('release-gate') ||
      selector.tags.contains('release-one')) {
    return 'release';
  }
  return 'parser';
}

final maintainiacIndividualTestManifest =
    MaintainiacIndividualTestManifest.fromSelectors(
      maintainiacSurgicalTestSelectorRegistry,
    );
