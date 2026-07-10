enum MaintainiacQaCheckpointReason {
  milestone,
  elapsedTime,
  failingGate,
  userRequested,
}

class MaintainiacQaCheckpointDecision {
  const MaintainiacQaCheckpointDecision({
    required this.shouldCheckpoint,
    required this.reason,
    required this.message,
  });

  final bool shouldCheckpoint;
  final MaintainiacQaCheckpointReason? reason;
  final String message;
}

class MaintainiacQaCheckpointPolicy {
  const MaintainiacQaCheckpointPolicy({
    this.maxUnpushedWork = const Duration(minutes: 30),
  });

  final Duration maxUnpushedWork;

  MaintainiacQaCheckpointDecision evaluate({
    required DateTime now,
    required DateTime lastPushAt,
    required bool milestoneReached,
    required bool failingGate,
    required bool userRequested,
    required int changedFileCount,
  }) {
    if (changedFileCount <= 0) {
      return const MaintainiacQaCheckpointDecision(
        shouldCheckpoint: false,
        reason: null,
        message: 'No local changes need a checkpoint.',
      );
    }
    if (userRequested) {
      return const MaintainiacQaCheckpointDecision(
        shouldCheckpoint: true,
        reason: MaintainiacQaCheckpointReason.userRequested,
        message: 'User requested a checkpoint push.',
      );
    }
    if (failingGate) {
      return const MaintainiacQaCheckpointDecision(
        shouldCheckpoint: true,
        reason: MaintainiacQaCheckpointReason.failingGate,
        message: 'Checkpoint failing evidence before feature work continues.',
      );
    }
    if (milestoneReached) {
      return const MaintainiacQaCheckpointDecision(
        shouldCheckpoint: true,
        reason: MaintainiacQaCheckpointReason.milestone,
        message: 'Milestone reached; commit and push the checkpoint.',
      );
    }
    if (now.difference(lastPushAt) >= maxUnpushedWork) {
      return const MaintainiacQaCheckpointDecision(
        shouldCheckpoint: true,
        reason: MaintainiacQaCheckpointReason.elapsedTime,
        message: 'Unpushed work exceeded the checkpoint window.',
      );
    }
    return const MaintainiacQaCheckpointDecision(
      shouldCheckpoint: false,
      reason: null,
      message: 'Continue batching; checkpoint window has not elapsed.',
    );
  }

  List<String> validate() {
    final failures = <String>[];
    if (maxUnpushedWork <= Duration.zero) {
      failures.add('checkpoint window must be positive');
    }
    if (maxUnpushedWork > const Duration(hours: 3)) {
      failures.add('checkpoint window must not exceed three hours');
    }
    return failures;
  }
}
