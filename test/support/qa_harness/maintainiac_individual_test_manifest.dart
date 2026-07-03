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
    if (_testFileReferences(command).length != 1) {
      failures.add('$id must target exactly one test file');
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
    final mentionsFirestore = lower.contains('firestore');
    final allowedMirrorContract =
        lower.contains('firestore mirror') ||
        _isOfflineFirestoreContractCommand(lower);
    final allowedBoundaryGuard = _isBoundaryGuardCommand(lower);
    final mentionsBlockedProvider =
        lower.contains('googlevision') ||
        lower.contains('mlkit') ||
        lower.contains('camera') ||
        lower.contains('ocr');
    if ((mentionsBlockedProvider &&
            !allowedMirrorContract &&
            !allowedBoundaryGuard) ||
        lower.contains('firebase') ||
        (mentionsFirestore && !allowedMirrorContract)) {
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

List<String> _testFileReferences(String command) {
  return [
    for (final token in command.split(RegExp(r'\s+')))
      if (token.startsWith('test/') && token.endsWith('.dart')) token,
  ];
}

bool _isOfflineFirestoreContractCommand(String lowerCommand) {
  return lowerCommand.contains('maintainiac_firestore_schema_test.dart') ||
      lowerCommand.contains('maintainiac_firestore_upload_queue_test.dart') ||
      lowerCommand.contains('maintainiac_firestore_documents_test.dart') ||
      lowerCommand.contains('maintainiac_hosted_cache_test.dart');
}

bool _isBoundaryGuardCommand(String lowerCommand) {
  return lowerCommand.contains('maintainiac_source_boundary_test.dart') ||
      lowerCommand.contains(
        'maintainiac_operating_directive_contract_test.dart',
      );
}

class MaintainiacIndividualTestManifest {
  const MaintainiacIndividualTestManifest(this.entries);

  final List<MaintainiacIndividualTestEntry> entries;

  static const allowedModules = {
    'expenses',
    'financial',
    'inventory',
    'parser',
    'payments',
    'performance',
    'qa-backbone',
    'security',
    'sync',
  };

  static const allowedRiskFamilies = {
    'audit',
    'financial',
    'fixtures',
    'parser',
    'performance',
    'privacy',
    'regression',
    'release',
    'security',
    'source-of-truth',
    'sync',
  };

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
      if (!allowedModules.contains(entry.module)) {
        failures.add('${entry.id} has unknown module ${entry.module}');
      }
      if (!allowedRiskFamilies.contains(entry.riskFamily)) {
        failures.add('${entry.id} has unknown risk family ${entry.riskFamily}');
      }
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

  List<String> commandsForModule(String module) {
    return [
      for (final entry in entries)
        if (entry.module == module) entry.command,
    ];
  }

  MaintainiacIndividualTestEntry entryForId(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    throw ArgumentError.value(id, 'id', 'Unknown individual test id');
  }

  String commandForId(String id) {
    return entryForId(id).command;
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
