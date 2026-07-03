import 'maintainiac_qa_case_registry.dart';
import 'maintainiac_qa_environment.dart';

enum MaintainiacQaCadence { focused, milestone, nightly, release }

class MaintainiacQaExecution {
  const MaintainiacQaExecution({
    required this.id,
    required this.label,
    required this.module,
    required this.command,
    required this.cadence,
    required this.owner,
    required this.proves,
    required this.failureAction,
    this.tags = const {},
    this.liveServicesAllowed = false,
    this.firebaseWritesAllowed = false,
  });

  factory MaintainiacQaExecution.fromCase(
    MaintainiacQaCase qaCase, {
    MaintainiacQaCadence cadence = MaintainiacQaCadence.focused,
  }) {
    return MaintainiacQaExecution(
      id: qaCase.id,
      label: qaCase.title,
      module: qaCase.module,
      command: qaCase.testCommand,
      cadence: cadence,
      owner: 'maintainiac-qa',
      proves: qaCase.behavior,
      failureAction:
          'Stop feature work, inspect ${qaCase.evidenceTarget}, fix the root cause, and add or update a regression fixture before continuing.',
      tags: qaCase.tags,
    );
  }

  final String id;
  final String label;
  final MaintainiacQaModule module;
  final String command;
  final MaintainiacQaCadence cadence;
  final String owner;
  final String proves;
  final String failureAction;
  final Set<String> tags;
  final bool liveServicesAllowed;
  final bool firebaseWritesAllowed;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('execution missing id');
    if (label.trim().isEmpty) failures.add('$id missing label');
    if (command.trim().isEmpty) failures.add('$id missing command');
    if (!command.startsWith('flutter test ') &&
        !command.startsWith('dart run ')) {
      failures.add('$id command must be a focused flutter test or dart run');
    }
    if (cadence == MaintainiacQaCadence.focused &&
        command.startsWith('flutter test ') &&
        !command.contains(' --plain-name ')) {
      failures.add('$id focused Flutter command must use --plain-name');
    }
    if (owner.trim().isEmpty) failures.add('$id missing owner');
    if (proves.trim().isEmpty) failures.add('$id missing behavior it proves');
    if (failureAction.trim().isEmpty) {
      failures.add('$id missing failure action');
    }
    if (liveServicesAllowed) {
      failures.add('$id must not allow live services in the QA harness');
    }
    if (firebaseWritesAllowed) {
      failures.add('$id must not allow Firebase writes in the QA harness');
    }
    if (tags.isEmpty) failures.add('$id needs searchable tags');
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'module': module.name,
      'command': command,
      'cadence': cadence.name,
      'owner': owner,
      'proves': proves,
      'failureAction': failureAction,
      'tags': tags.toList()..sort(),
      'liveServicesAllowed': liveServicesAllowed,
      'firebaseWritesAllowed': firebaseWritesAllowed,
    };
  }
}

class MaintainiacQaExecutionManifest {
  const MaintainiacQaExecutionManifest(this.executions);

  factory MaintainiacQaExecutionManifest.releaseOneCore() {
    final registry = MaintainiacQaCaseRegistry.backboneSeed();
    return MaintainiacQaExecutionManifest([
      for (final qaCase in registry.cases)
        MaintainiacQaExecution.fromCase(
          qaCase,
          cadence: _cadenceFor(qaCase.priority),
        ),
    ]);
  }

  final List<MaintainiacQaExecution> executions;

  List<MaintainiacQaExecution> byCadence(MaintainiacQaCadence cadence) {
    return [
      for (final execution in executions)
        if (execution.cadence == cadence) execution,
    ];
  }

  List<String> commandPlanFor(MaintainiacQaCadence cadence) {
    final commands = <String>[];
    for (final execution in byCadence(cadence)) {
      if (!commands.contains(execution.command)) {
        commands.add(execution.command);
      }
    }
    return commands;
  }

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (executions.isEmpty) failures.add('execution manifest is empty');
    for (final execution in executions) {
      if (!ids.add(execution.id)) {
        failures.add('duplicate execution id ${execution.id}');
      }
      failures.addAll(execution.validate());
    }
    final modules = executions.map((execution) => execution.module).toSet();
    for (final module in {
      MaintainiacQaModule.inventory,
      MaintainiacQaModule.expenses,
      MaintainiacQaModule.sync,
      MaintainiacQaModule.security,
      MaintainiacQaModule.performance,
    }) {
      if (!modules.contains(module)) {
        failures.add('execution manifest missing ${module.name}');
      }
    }
    if (byCadence(MaintainiacQaCadence.release).isEmpty) {
      failures.add('execution manifest missing release cadence checks');
    }
    if (byCadence(MaintainiacQaCadence.focused).isEmpty) {
      failures.add('execution manifest missing focused checks');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'executionCount': executions.length,
      'focusedCommands': commandPlanFor(MaintainiacQaCadence.focused),
      'releaseCommands': commandPlanFor(MaintainiacQaCadence.release),
      'executions': [for (final execution in executions) execution.toJson()],
    };
  }

  static MaintainiacQaCadence _cadenceFor(MaintainiacQaCasePriority priority) {
    return switch (priority) {
      MaintainiacQaCasePriority.releaseBlocker => MaintainiacQaCadence.release,
      MaintainiacQaCasePriority.core => MaintainiacQaCadence.focused,
      MaintainiacQaCasePriority.standard => MaintainiacQaCadence.milestone,
      MaintainiacQaCasePriority.hardening => MaintainiacQaCadence.nightly,
    };
  }
}
