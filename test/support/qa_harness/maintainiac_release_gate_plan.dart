import 'maintainiac_qa_case_registry.dart';

class MaintainiacReleaseGatePlan {
  const MaintainiacReleaseGatePlan({
    required this.name,
    required this.registry,
    required this.requiredPriorities,
  });

  factory MaintainiacReleaseGatePlan.releaseOne() {
    return MaintainiacReleaseGatePlan(
      name: 'release_one_core_gate',
      registry: MaintainiacQaCaseRegistry.backboneSeed(),
      requiredPriorities: const {
        MaintainiacQaCasePriority.releaseBlocker,
        MaintainiacQaCasePriority.core,
      },
    );
  }

  final String name;
  final MaintainiacQaCaseRegistry registry;
  final Set<MaintainiacQaCasePriority> requiredPriorities;

  List<MaintainiacQaCase> get requiredCases {
    return [
      for (final qaCase in registry.cases)
        if (requiredPriorities.contains(qaCase.priority)) qaCase,
    ];
  }

  List<String> get commands {
    final commands = <String>[];
    for (final qaCase in requiredCases) {
      if (qaCase.testCommand.isNotEmpty &&
          !commands.contains(qaCase.testCommand)) {
        commands.add(qaCase.testCommand);
      }
    }
    return commands;
  }

  List<String> validate() {
    final failures = <String>[];
    if (name.trim().isEmpty) failures.add('release gate missing name');
    failures.addAll(registry.validate());
    if (requiredPriorities.isEmpty) {
      failures.add('release gate missing required priorities');
    }
    final required = requiredCases;
    if (required.isEmpty) failures.add('release gate has no required cases');
    for (final qaCase in required) {
      if (qaCase.evidenceTarget.trim().isEmpty) {
        failures.add('${qaCase.id} missing evidence target');
      }
      if (qaCase.priority == MaintainiacQaCasePriority.releaseBlocker &&
          qaCase.testCommand.trim().isEmpty) {
        failures.add('${qaCase.id} release blocker missing command');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'requiredPriorities': [
        for (final priority in requiredPriorities) priority.name,
      ]..sort(),
      'requiredCaseCount': requiredCases.length,
      'commands': commands,
      'cases': [for (final qaCase in requiredCases) qaCase.toJson()],
    };
  }
}
