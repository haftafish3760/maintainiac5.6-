enum MaintainiacRestartLifecycleStage {
  draftCreated,
  localWriteQueued,
  partialMirrorWrite,
  appKilled,
  appRestarted,
  userReviewResumed,
  syncRetried,
}

class MaintainiacRestartLifecycleScenario {
  const MaintainiacRestartLifecycleScenario({
    required this.id,
    required this.module,
    required this.stages,
    required this.mustRecoverLocalState,
    required this.mustPreserveReviewState,
    required this.mustAvoidSilentOverwrite,
    required this.expectedOutcome,
  });

  final String id;
  final String module;
  final Set<MaintainiacRestartLifecycleStage> stages;
  final bool mustRecoverLocalState;
  final bool mustPreserveReviewState;
  final bool mustAvoidSilentOverwrite;
  final String expectedOutcome;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('restart lifecycle scenario missing id');
    }
    if (module.trim().isEmpty) {
      failures.add('$id missing module');
    }
    if (!stages.contains(MaintainiacRestartLifecycleStage.appKilled) ||
        !stages.contains(MaintainiacRestartLifecycleStage.appRestarted)) {
      failures.add('$id must include app kill and restart stages');
    }
    if (!mustRecoverLocalState) {
      failures.add('$id must recover local state');
    }
    if (!mustAvoidSilentOverwrite) {
      failures.add('$id must avoid silent overwrite');
    }
    if (expectedOutcome.trim().isEmpty) {
      failures.add('$id missing expected outcome');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module,
      'stages': [for (final stage in stages) stage.name]..sort(),
      'mustRecoverLocalState': mustRecoverLocalState,
      'mustPreserveReviewState': mustPreserveReviewState,
      'mustAvoidSilentOverwrite': mustAvoidSilentOverwrite,
      'expectedOutcome': expectedOutcome,
    };
  }
}

class MaintainiacRestartLifecycleGate {
  const MaintainiacRestartLifecycleGate(this.scenarios);

  final List<MaintainiacRestartLifecycleScenario> scenarios;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final modules = <String>{};
    for (final scenario in scenarios) {
      if (!ids.add(scenario.id)) {
        failures.add('duplicate restart lifecycle scenario ${scenario.id}');
      }
      modules.add(scenario.module);
      failures.addAll(scenario.validate());
    }
    for (final required in {
      'expenses',
      'inventory',
      'jobs',
      'sync',
      'parser_review',
    }) {
      if (!modules.contains(required)) {
        failures.add('restart lifecycle gate missing module $required');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'scenarioCount': scenarios.length,
      'scenarios': [for (final scenario in scenarios) scenario.toJson()],
    };
  }
}

const maintainiacRestartLifecycleGate = MaintainiacRestartLifecycleGate([
  MaintainiacRestartLifecycleScenario(
    id: 'expense_draft_restart_recovery',
    module: 'expenses',
    stages: {
      MaintainiacRestartLifecycleStage.draftCreated,
      MaintainiacRestartLifecycleStage.appKilled,
      MaintainiacRestartLifecycleStage.appRestarted,
      MaintainiacRestartLifecycleStage.userReviewResumed,
    },
    mustRecoverLocalState: true,
    mustPreserveReviewState: true,
    mustAvoidSilentOverwrite: true,
    expectedOutcome:
        'Expense draft resumes from local storage before mirror sync.',
  ),
  MaintainiacRestartLifecycleScenario(
    id: 'inventory_review_restart_recovery',
    module: 'inventory',
    stages: {
      MaintainiacRestartLifecycleStage.draftCreated,
      MaintainiacRestartLifecycleStage.appKilled,
      MaintainiacRestartLifecycleStage.appRestarted,
      MaintainiacRestartLifecycleStage.userReviewResumed,
    },
    mustRecoverLocalState: true,
    mustPreserveReviewState: true,
    mustAvoidSilentOverwrite: true,
    expectedOutcome:
        'Inventory parser candidates remain review-only after restart.',
  ),
  MaintainiacRestartLifecycleScenario(
    id: 'job_material_restart_recovery',
    module: 'jobs',
    stages: {
      MaintainiacRestartLifecycleStage.localWriteQueued,
      MaintainiacRestartLifecycleStage.appKilled,
      MaintainiacRestartLifecycleStage.appRestarted,
      MaintainiacRestartLifecycleStage.syncRetried,
    },
    mustRecoverLocalState: true,
    mustPreserveReviewState: false,
    mustAvoidSilentOverwrite: true,
    expectedOutcome:
        'Confirmed job material local write retries mirror sync after restart.',
  ),
  MaintainiacRestartLifecycleScenario(
    id: 'partial_sync_restart_recovery',
    module: 'sync',
    stages: {
      MaintainiacRestartLifecycleStage.localWriteQueued,
      MaintainiacRestartLifecycleStage.partialMirrorWrite,
      MaintainiacRestartLifecycleStage.appKilled,
      MaintainiacRestartLifecycleStage.appRestarted,
      MaintainiacRestartLifecycleStage.syncRetried,
    },
    mustRecoverLocalState: true,
    mustPreserveReviewState: false,
    mustAvoidSilentOverwrite: true,
    expectedOutcome:
        'Partial mirror writes resume from local dirty state without cloud winning.',
  ),
  MaintainiacRestartLifecycleScenario(
    id: 'parser_review_restart_recovery',
    module: 'parser_review',
    stages: {
      MaintainiacRestartLifecycleStage.draftCreated,
      MaintainiacRestartLifecycleStage.appKilled,
      MaintainiacRestartLifecycleStage.appRestarted,
      MaintainiacRestartLifecycleStage.userReviewResumed,
    },
    mustRecoverLocalState: true,
    mustPreserveReviewState: true,
    mustAvoidSilentOverwrite: true,
    expectedOutcome:
        'Parser review state resumes without auto-accepting candidates.',
  ),
]);
