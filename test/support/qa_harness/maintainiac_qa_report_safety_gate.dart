import 'qa_harness.dart';

class MaintainiacQaReportSafetyGate {
  const MaintainiacQaReportSafetyGate({
    required this.requiredTopLevelFields,
    required this.requiredAdminFields,
    required this.requiredPackHealthFields,
    required this.requiredSuiteFields,
  });

  factory MaintainiacQaReportSafetyGate.releaseOne() {
    return const MaintainiacQaReportSafetyGate(
      requiredTopLevelFields: {
        'domain',
        'strict',
        'startedAt',
        'runConfig',
        'durationMs',
        'checked',
        'failureCount',
        'actualFailureCount',
        'severityCounts',
        'failuresBySuite',
        'failuresByTriageCategory',
        'slowestSuites',
        'packHealth',
        'adminHealth',
        'results',
      },
      requiredAdminFields: {
        'domain',
        'profile',
        'preset',
        'strict',
        'status',
        'checked',
        'actualFailureCount',
        'blockingFailureCount',
        'severityCounts',
        'failuresByTriageCategory',
        'slowestSuites',
        'packHealth',
        'durationMs',
        'startedAt',
      },
      requiredPackHealthFields: {
        'suite',
        'presentContracts',
        'missingRequiredContracts',
        'missingRecommendedContracts',
        'healthScore',
        'coverageScore',
        'readinessLabel',
        'failureCount',
        'checked',
        'durationMs',
      },
      requiredSuiteFields: {
        'name',
        'durationMs',
        'checked',
        'failureCount',
        'actualFailureCount',
        'severityCounts',
        'metrics',
        'failures',
      },
    );
  }

  final Set<String> requiredTopLevelFields;
  final Set<String> requiredAdminFields;
  final Set<String> requiredPackHealthFields;
  final Set<String> requiredSuiteFields;

  List<String> validateReport(QaReport report) {
    final failures = <String>[];
    final json = report.toJson();
    _requireFields(failures, 'top_level', json, requiredTopLevelFields);

    final adminHealth = _map(json['adminHealth']);
    _requireFields(failures, 'admin_health', adminHealth, requiredAdminFields);
    if (adminHealth['checked'] != json['checked']) {
      failures.add('admin_health checked must equal report checked');
    }
    if (adminHealth['actualFailureCount'] != json['actualFailureCount']) {
      failures.add(
        'admin_health actualFailureCount must equal report actualFailureCount',
      );
    }
    if (adminHealth['packHealth'] == null) {
      failures.add('admin_health must embed packHealth snapshot');
    }

    final packHealth = _map(json['packHealth']);
    _requireFields(
      failures,
      'pack_health',
      packHealth,
      requiredPackHealthFields,
    );
    if (packHealth['healthScore'] is! num) {
      failures.add('pack_health healthScore must be numeric');
    }
    if (packHealth['coverageScore'] is! num) {
      failures.add('pack_health coverageScore must be numeric');
    }

    final results = json['results'];
    if (results is! List || results.isEmpty) {
      failures.add('report results must include executed suites');
    } else {
      for (final entry in results) {
        final suite = _map(entry);
        final suiteName = suite['name']?.toString() ?? 'unknown_suite';
        _requireFields(
          failures,
          'suite:$suiteName',
          suite,
          requiredSuiteFields,
        );
        if ((suite['checked'] as int? ?? 0) <= 0) {
          failures.add('suite:$suiteName checked must be greater than zero');
        }
        if (suite['actualFailureCount'] is! int) {
          failures.add('suite:$suiteName needs actualFailureCount');
        }
      }
    }

    final critical = _severityCount(json, 'critical');
    final errors = _severityCount(json, 'error');
    if (report.runConfig.profile == 'release') {
      if (json['strict'] != true) failures.add('release report must be strict');
      if ((json['actualFailureCount'] as int? ?? -1) != 0) {
        failures.add('release report must have zero actual failures');
      }
      if (critical != 0 || errors != 0) {
        failures.add('release report must have zero critical/error failures');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'requiredTopLevelFields': requiredTopLevelFields.toList()..sort(),
      'requiredAdminFields': requiredAdminFields.toList()..sort(),
      'requiredPackHealthFields': requiredPackHealthFields.toList()..sort(),
      'requiredSuiteFields': requiredSuiteFields.toList()..sort(),
    };
  }

  void _requireFields(
    List<String> failures,
    String scope,
    Map<String, Object?> value,
    Set<String> required,
  ) {
    for (final field in required) {
      if (!value.containsKey(field)) {
        failures.add('$scope missing report safety field $field');
      }
    }
  }

  int _severityCount(Map<String, Object?> json, String severity) {
    final counts = _map(json['severityCounts']);
    return counts[severity] as int? ?? -1;
  }

  Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return {for (final entry in value.entries) '${entry.key}': entry.value};
    }
    return const {};
  }
}
