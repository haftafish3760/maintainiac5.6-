import 'dart:convert';
import 'dart:io';

const _defaultSummary =
    'build/parser_qa_reports/release_shards/latest_summary.json';
const _usage =
    'dart run tool/work_supply_parser_qa_release_signoff.dart '
    '[--summary $_defaultSummary] [--expected-profile release] '
    '[--max-age-hours 168] [--allow-dry-run]';

const _expectedShardIds = {
  'release-contracts-001',
  'safety-governance-001',
  'semantic-fixtures-001',
  'catalog-contracts-001',
};

const _requiredFalseSafetyFields = {
  'unsafe',
  'liveServicesAllowed',
  'writesProductionCatalog',
  'firebaseWritesAllowed',
  'ocrCameraExpensesTouched',
};

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }
  final options = _SignoffOptions.parse(args);
  final failures = <String>[];
  final summaryFile = File(options.summaryPath);
  if (!summaryFile.existsSync()) {
    failures.add('missing_summary:${options.summaryPath}');
    _finish(failures);
    return;
  }

  final decoded = jsonDecode(summaryFile.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    failures.add('summary_not_json_object:${options.summaryPath}');
    _finish(failures);
    return;
  }
  final summary = decoded;
  _expectEqual(
    failures,
    id: 'profile_mismatch',
    expected: options.expectedProfile,
    actual: summary['profile']?.toString() ?? '',
  );
  if (options.expectedProfile == 'release' && summary['strict'] != true) {
    failures.add('release_profile_not_strict:${summary['strict']}');
  }
  if (!options.allowDryRun && summary['dryRun'] == true) {
    failures.add('dry_run_not_release_signoff');
  }
  if ((summary['failedShardCount'] as num? ?? 1).toInt() != 0) {
    failures.add('failed_shard_count:${summary['failedShardCount']}');
  }
  _expectFalseSafetyFields(failures, summary, scope: 'summary');
  final declaredShardCount = (summary['shardCount'] as num? ?? -1).toInt();
  final rawCompletedShardCount = summary['completedShardCount'];
  if (rawCompletedShardCount is! num) {
    failures.add('missing_completed_shard_count');
  }
  final completedShardCount = rawCompletedShardCount is num
      ? rawCompletedShardCount.toInt()
      : -1;
  if (completedShardCount != declaredShardCount) {
    failures.add(
      'incomplete_shard_count:$completedShardCount/$declaredShardCount',
    );
  }
  final summaryState = (summary['state']?.toString() ?? '').trim();
  if (summaryState.isEmpty) {
    failures.add('missing_summary_state');
  } else if (summaryState != 'complete') {
    failures.add('summary_not_complete:$summaryState');
  }
  if ((summary['timeoutBudgetMs'] as num? ?? 0).toInt() <= 0) {
    failures.add('missing_timeout_budget');
  }
  if ((summary['maxGeneratedCases'] as num? ?? 0).toInt() <= 0) {
    failures.add('missing_generated_case_limit');
  }
  if ((summary['resumeFrom']?.toString() ?? '').trim().isEmpty) {
    failures.add('missing_resume_evidence');
  }

  final results = summary['results'];
  if (results is! List) {
    failures.add('missing_results');
    _finish(failures);
    return;
  }
  final seenShards = <String>{};
  for (final result in results) {
    if (result is! Map) {
      failures.add('result_not_json_object');
      continue;
    }
    final shardId = result['shardId']?.toString() ?? '';
    if (shardId.isEmpty) {
      failures.add('missing_shard_id');
      continue;
    }
    seenShards.add(shardId);
    if ((result['exitCode'] as num? ?? 1).toInt() != 0) {
      failures.add('shard_failed:$shardId');
    }
    if (options.expectedProfile == 'release' && result['strict'] != true) {
      failures.add('release_shard_not_strict:$shardId:${result['strict']}');
    }
    _expectFalseSafetyFields(failures, result, scope: 'shard:$shardId');
    final shardState = (result['state']?.toString() ?? '').trim();
    if (shardState.isNotEmpty && shardState != 'complete') {
      failures.add('shard_not_complete:$shardId:$shardState');
    }
    if (result['suiteFilter'] is! List ||
        (result['suiteFilter'] as List).isEmpty) {
      failures.add('missing_suite_filter:$shardId');
    }
    if ((result['generatedCaseLimit'] as num? ?? 0).toInt() <= 0) {
      failures.add('missing_shard_generated_limit:$shardId');
    }
    if ((result['timeoutBudgetMs'] as num? ?? 0).toInt() <= 0) {
      failures.add('missing_shard_timeout_budget:$shardId');
    }
    if ((result['resumeFrom']?.toString() ?? '').trim().isEmpty) {
      failures.add('missing_shard_resume_evidence:$shardId');
    }
    final startedAt = DateTime.tryParse(result['startedAt']?.toString() ?? '');
    if (startedAt == null) {
      failures.add('missing_shard_started_at:$shardId');
    } else if (options.maxAgeHours > 0 &&
        DateTime.now().toUtc().difference(startedAt.toUtc()) >
            Duration(hours: options.maxAgeHours)) {
      failures.add('stale_shard:$shardId');
    }
    final transcriptPath = result['transcriptPath']?.toString() ?? '';
    if (transcriptPath.isEmpty || !File(transcriptPath).existsSync()) {
      failures.add('missing_transcript:$shardId');
    }
  }
  for (final expected in _expectedShardIds) {
    if (!seenShards.contains(expected)) {
      failures.add('missing_expected_shard:$expected');
    }
  }
  _finish(failures);
}

void _expectFalseSafetyFields(
  List<String> failures,
  Map<Object?, Object?> json, {
  required String scope,
}) {
  for (final field in _requiredFalseSafetyFields) {
    if (!json.containsKey(field)) {
      failures.add('missing_safety_field:$scope:$field');
      continue;
    }
    if (json[field] != false) {
      failures.add('unsafe_safety_field:$scope:$field:${json[field]}');
    }
  }
}

void _expectEqual(
  List<String> failures, {
  required String id,
  required String expected,
  required String actual,
}) {
  if (expected == actual) return;
  failures.add('$id:expected=$expected:actual=$actual');
}

void _finish(List<String> failures) {
  if (failures.isEmpty) {
    stdout.writeln('QA_RELEASE_SIGNOFF status=pass failures=0');
    return;
  }
  stdout.writeln('QA_RELEASE_SIGNOFF status=fail failures=${failures.length}');
  for (final failure in failures) {
    stdout.writeln('QA_RELEASE_SIGNOFF_FAILURE $failure');
  }
  exitCode = 1;
}

class _SignoffOptions {
  const _SignoffOptions({
    required this.summaryPath,
    required this.expectedProfile,
    required this.maxAgeHours,
    required this.allowDryRun,
  });

  final String summaryPath;
  final String expectedProfile;
  final int maxAgeHours;
  final bool allowDryRun;

  static _SignoffOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final withoutPrefix = arg.substring(2);
      final equalsIndex = withoutPrefix.indexOf('=');
      if (equalsIndex >= 0) {
        values[withoutPrefix.substring(0, equalsIndex)] = withoutPrefix
            .substring(equalsIndex + 1);
        continue;
      }
      final nextIsValue =
          index + 1 < args.length && !args[index + 1].startsWith('--');
      if (nextIsValue) {
        values[withoutPrefix] = args[++index];
      } else {
        flags.add(withoutPrefix);
      }
    }
    return _SignoffOptions(
      summaryPath: values['summary'] ?? _defaultSummary,
      expectedProfile: values['expected-profile'] ?? 'release',
      maxAgeHours: int.tryParse(values['max-age-hours'] ?? '') ?? 168,
      allowDryRun: flags.contains('allow-dry-run'),
    );
  }
}
