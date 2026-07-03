enum MaintainiacEvidenceKind {
  analyzer,
  individualTest,
  individualCommandResolver,
  releaseGateTool,
  backboneVisibility,
  privacyGate,
  sourceTruthGate,
  gitPush,
}

class MaintainiacReleaseEvidence {
  const MaintainiacReleaseEvidence({
    required this.id,
    required this.kind,
    required this.commandOrArtifact,
    required this.proves,
    required this.requiredForRelease,
  });

  final String id;
  final MaintainiacEvidenceKind kind;
  final String commandOrArtifact;
  final String proves;
  final bool requiredForRelease;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('release evidence missing id');
    if (commandOrArtifact.trim().isEmpty) {
      failures.add('$id missing command or artifact');
    }
    if (proves.trim().isEmpty) failures.add('$id missing proof statement');
    if (kind == MaintainiacEvidenceKind.individualTest &&
        !commandOrArtifact.contains('--plain-name')) {
      failures.add('$id individual test evidence must use --plain-name');
    }
    if (kind == MaintainiacEvidenceKind.individualCommandResolver &&
        !commandOrArtifact.startsWith(
          'dart run tool/maintainiac_individual_qa_command.dart --id ',
        )) {
      failures.add('$id must prove exact individual command lookup by id');
    }
    if (kind == MaintainiacEvidenceKind.releaseGateTool &&
        !commandOrArtifact.startsWith(
          'dart run tool/maintainiac_release_gate.dart',
        )) {
      failures.add('$id must prove the release gate tool output directly');
    }
    if (kind == MaintainiacEvidenceKind.gitPush &&
        !commandOrArtifact.startsWith('git push')) {
      failures.add('$id git push evidence must use git push');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'commandOrArtifact': commandOrArtifact,
      'proves': proves,
      'requiredForRelease': requiredForRelease,
    };
  }
}

class MaintainiacReleaseEvidenceBundle {
  const MaintainiacReleaseEvidenceBundle(this.evidence);

  final List<MaintainiacReleaseEvidence> evidence;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final requiredKinds = <MaintainiacEvidenceKind>{};
    for (final entry in evidence) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate release evidence ${entry.id}');
      }
      if (entry.requiredForRelease) requiredKinds.add(entry.kind);
      failures.addAll(entry.validate());
    }
    for (final required in MaintainiacEvidenceKind.values) {
      if (!requiredKinds.contains(required)) {
        failures.add('release evidence missing required kind ${required.name}');
      }
    }
    return failures;
  }

  List<String> requiredCommands() {
    return [
      for (final entry in evidence)
        if (entry.requiredForRelease) entry.commandOrArtifact,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'evidenceCount': evidence.length,
      'requiredCommandCount': requiredCommands().length,
      'requiredCommands': requiredCommands(),
      'evidence': [for (final entry in evidence) entry.toJson()],
    };
  }
}

const maintainiacReleaseEvidenceBundle = MaintainiacReleaseEvidenceBundle([
  MaintainiacReleaseEvidence(
    id: 'parser_consumer_targeted_analyzer',
    kind: MaintainiacEvidenceKind.analyzer,
    commandOrArtifact:
        'dart analyze test/support/qa_harness test/maintainiac_qa_backbone_test.dart',
    proves: 'New QA harness contracts compile and satisfy analyzer rules.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'surgical_selector_individual_tests',
    kind: MaintainiacEvidenceKind.individualTest,
    commandOrArtifact:
        'flutter test test/maintainiac_surgical_selector_coverage_test.dart --plain-name "surgical selector coverage requires selectors for every focused behavior"',
    proves:
        'Every focused parser-consumer behavior has an individual selector.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'individual_command_resolver',
    kind: MaintainiacEvidenceKind.individualCommandResolver,
    commandOrArtifact:
        'dart run tool/maintainiac_individual_qa_command.dart --id qa_environment_local_truth',
    proves:
        'A single selector id resolves to one exact focused test command without running a batch.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'release_gate_tool_command_manifest',
    kind: MaintainiacEvidenceKind.releaseGateTool,
    commandOrArtifact: 'dart run tool/maintainiac_release_gate.dart --json',
    proves:
        'The release gate tool emits auditable JSON including the required surgical QA commands.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'main_backbone_visibility',
    kind: MaintainiacEvidenceKind.backboneVisibility,
    commandOrArtifact:
        'flutter test test/maintainiac_qa_backbone_test.dart --plain-name "main Maintainiac QA backbone covers whole app modules"',
    proves: 'Shared QA backbone reports all new gates and contracts.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'telemetry_privacy_gate',
    kind: MaintainiacEvidenceKind.privacyGate,
    commandOrArtifact:
        'flutter test test/maintainiac_qa_telemetry_privacy_gate_test.dart --plain-name "QA telemetry privacy gate covers report and admin surfaces"',
    proves: 'QA/admin/parser diagnostics redact private fields.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'source_truth_gate',
    kind: MaintainiacEvidenceKind.sourceTruthGate,
    commandOrArtifact:
        'flutter test test/maintainiac_source_truth_gate_test.dart --plain-name "source truth gate protects local truth and derived outputs"',
    proves:
        'Hive/local truth, mirror-only cloud, suggestions, and derived outputs are labeled.',
    requiredForRelease: true,
  ),
  MaintainiacReleaseEvidence(
    id: 'github_push_checkpoint',
    kind: MaintainiacEvidenceKind.gitPush,
    commandOrArtifact: 'git push',
    proves: 'Milestone is backed up remotely before continuing.',
    requiredForRelease: true,
  ),
]);
