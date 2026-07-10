import 'maintainiac_sensitive_field_registry.dart';

enum MaintainiacTelemetrySurface {
  qaReport,
  adminDashboard,
  parserDiagnostic,
  exportArtifact,
  runLedger,
}

class MaintainiacTelemetryPrivacyRule {
  const MaintainiacTelemetryPrivacyRule({
    required this.id,
    required this.surface,
    required this.allowedFields,
    required this.forbiddenFields,
    required this.redactionRequired,
    required this.reason,
  });

  final String id;
  final MaintainiacTelemetrySurface surface;
  final Set<String> allowedFields;
  final Set<String> forbiddenFields;
  final bool redactionRequired;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('telemetry privacy rule missing id');
    if (allowedFields.isEmpty) failures.add('$id missing allowed fields');
    if (forbiddenFields.isEmpty) failures.add('$id missing forbidden fields');
    if (reason.trim().isEmpty) failures.add('$id missing reason');
    if (!redactionRequired) {
      failures.add('$id must require redaction');
    }
    final overlap = allowedFields.intersection(forbiddenFields);
    if (overlap.isNotEmpty) {
      failures.add('$id fields cannot be both allowed and forbidden: $overlap');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'surface': surface.name,
      'allowedFields': allowedFields.toList()..sort(),
      'forbiddenFields': forbiddenFields.toList()..sort(),
      'redactionRequired': redactionRequired,
      'reason': reason,
    };
  }
}

class MaintainiacQaTelemetryPrivacyGate {
  const MaintainiacQaTelemetryPrivacyGate(this.rules);

  final List<MaintainiacTelemetryPrivacyRule> rules;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final surfaces = <MaintainiacTelemetrySurface>{};
    for (final rule in rules) {
      if (!ids.add(rule.id)) {
        failures.add('duplicate telemetry privacy rule ${rule.id}');
      }
      surfaces.add(rule.surface);
      final missingSensitiveFields = maintainiacSensitiveFieldNames.difference(
        rule.forbiddenFields,
      );
      if (missingSensitiveFields.isNotEmpty) {
        failures.add(
          '${rule.id} missing sensitive forbidden fields: '
          '$missingSensitiveFields',
        );
      }
      failures.addAll(rule.validate());
    }
    for (final required in MaintainiacTelemetrySurface.values) {
      if (!surfaces.contains(required)) {
        failures.add('telemetry privacy gate missing surface ${required.name}');
      }
    }
    return failures;
  }

  Set<String> forbiddenFieldsFor(MaintainiacTelemetrySurface surface) {
    return {
      for (final rule in rules)
        if (rule.surface == surface) ...rule.forbiddenFields,
    };
  }

  Map<String, Object?> toJson() {
    return {
      'ruleCount': rules.length,
      'surfaces': [
        for (final surface in MaintainiacTelemetrySurface.values) surface.name,
      ],
      'rules': [for (final rule in rules) rule.toJson()],
    };
  }
}

const _commonForbiddenPrivateFields = maintainiacSensitiveFieldNames;

const maintainiacQaTelemetryPrivacyGate = MaintainiacQaTelemetryPrivacyGate([
  MaintainiacTelemetryPrivacyRule(
    id: 'qa_report_redaction',
    surface: MaintainiacTelemetrySurface.qaReport,
    allowedFields: {
      'suite',
      'failureId',
      'severity',
      'triageCategory',
      'durationMs',
      'checked',
    },
    forbiddenFields: _commonForbiddenPrivateFields,
    redactionRequired: true,
    reason:
        'QA reports need actionable failure metadata without private receipt or customer data.',
  ),
  MaintainiacTelemetryPrivacyRule(
    id: 'admin_dashboard_rollup',
    surface: MaintainiacTelemetrySurface.adminDashboard,
    allowedFields: {
      'deviceModelBucket',
      'appVersion',
      'module',
      'failureCategory',
      'count',
    },
    forbiddenFields: _commonForbiddenPrivateFields,
    redactionRequired: true,
    reason:
        'Admin health dashboards should show aggregate health, not user records.',
  ),
  MaintainiacTelemetryPrivacyRule(
    id: 'parser_diagnostic_redaction',
    surface: MaintainiacTelemetrySurface.parserDiagnostic,
    allowedFields: {
      'domain',
      'fixtureId',
      'candidateCount',
      'confidenceBucket',
      'warningCode',
    },
    forbiddenFields: _commonForbiddenPrivateFields,
    redactionRequired: true,
    reason:
        'Parser diagnostics must explain failures without logging raw receipt content.',
  ),
  MaintainiacTelemetryPrivacyRule(
    id: 'export_artifact_redaction',
    surface: MaintainiacTelemetrySurface.exportArtifact,
    allowedFields: {
      'exportId',
      'ownerAccountId',
      'recordCount',
      'createdAtIso',
      'module',
    },
    forbiddenFields: _commonForbiddenPrivateFields,
    redactionRequired: true,
    reason: 'Export artifacts must be owned and redacted before writing.',
  ),
  MaintainiacTelemetryPrivacyRule(
    id: 'run_ledger_redaction',
    surface: MaintainiacTelemetrySurface.runLedger,
    allowedFields: {
      'runId',
      'commandLabel',
      'inputSignature',
      'status',
      'exitCode',
      'reportPath',
    },
    forbiddenFields: _commonForbiddenPrivateFields,
    redactionRequired: true,
    reason:
        'Run ledgers need reproducibility data without private app payloads.',
  ),
]);
