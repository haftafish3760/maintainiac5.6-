enum MaintainiacQaRunStatus { queued, running, passed, failed, skipped }

class MaintainiacQaRunRecord {
  const MaintainiacQaRunRecord({
    required this.id,
    required this.label,
    required this.command,
    required this.inputSignature,
    required this.startedAt,
    required this.status,
    this.completedAt,
    this.exitCode,
    this.gitCommit = '',
    this.scope = const [],
    this.reportPath = '',
    this.actionableSummary = '',
  });

  final String id;
  final String label;
  final String command;
  final String inputSignature;
  final DateTime startedAt;
  final DateTime? completedAt;
  final MaintainiacQaRunStatus status;
  final int? exitCode;
  final String gitCommit;
  final List<String> scope;
  final String reportPath;
  final String actionableSummary;

  bool get isTerminal {
    return switch (status) {
      MaintainiacQaRunStatus.passed ||
      MaintainiacQaRunStatus.failed ||
      MaintainiacQaRunStatus.skipped => true,
      MaintainiacQaRunStatus.queued || MaintainiacQaRunStatus.running => false,
    };
  }

  bool get passedCleanly =>
      status == MaintainiacQaRunStatus.passed && exitCode == 0;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('run record missing id');
    if (label.trim().isEmpty) failures.add('$id missing label');
    if (command.trim().isEmpty) failures.add('$id missing command');
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
    if (inputSignature.trim().isEmpty) {
      failures.add('$id missing input signature');
    }
    if (scope.isEmpty) failures.add('$id missing source scope');
    if (isTerminal && completedAt == null) {
      failures.add('$id terminal run missing completedAt');
    }
    if (status == MaintainiacQaRunStatus.passed && exitCode != 0) {
      failures.add('$id passed run must have exitCode 0');
    }
    if (status == MaintainiacQaRunStatus.failed && exitCode == 0) {
      failures.add('$id failed run must have non-zero exitCode');
    }
    if (status == MaintainiacQaRunStatus.failed &&
        actionableSummary.trim().isEmpty) {
      failures.add('$id failed run missing actionable summary');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'command': command,
      'inputSignature': inputSignature,
      'startedAt': startedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'status': status.name,
      if (exitCode != null) 'exitCode': exitCode,
      if (gitCommit.isNotEmpty) 'gitCommit': gitCommit,
      'scope': scope,
      if (reportPath.isNotEmpty) 'reportPath': reportPath,
      if (actionableSummary.isNotEmpty) 'actionableSummary': actionableSummary,
    };
  }
}

List<String> _testFileReferences(String command) {
  return [
    for (final token in command.split(RegExp(r'\s+')))
      if (token.startsWith('test/') && token.endsWith('.dart')) token,
  ];
}

class MaintainiacQaRunLedger {
  const MaintainiacQaRunLedger(this.records);

  final List<MaintainiacQaRunRecord> records;

  MaintainiacQaRunRecord? latestFor(String command) {
    for (final record in records.reversed) {
      if (record.command == command) return record;
    }
    return null;
  }

  bool canSkip({required String command, required String inputSignature}) {
    final latest = latestFor(command);
    return latest != null &&
        latest.passedCleanly &&
        latest.inputSignature == inputSignature;
  }

  List<MaintainiacQaRunRecord> failuresNeedingFix() {
    return [
      for (final record in records)
        if (record.status == MaintainiacQaRunStatus.failed) record,
    ];
  }

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    for (final record in records) {
      if (!ids.add(record.id)) {
        failures.add('duplicate run record id ${record.id}');
      }
      failures.addAll(record.validate());
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'recordCount': records.length,
      'failedCount': failuresNeedingFix().length,
      'records': [for (final record in records) record.toJson()],
    };
  }
}
