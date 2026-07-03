import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('QA telemetry privacy gate covers report and admin surfaces', () {
    const gate = maintainiacQaTelemetryPrivacyGate;

    expect(gate.validate(), isEmpty);
    expect(gate.toJson()['ruleCount'], greaterThanOrEqualTo(5));
    expect(
      gate.forbiddenFieldsFor(MaintainiacTelemetrySurface.parserDiagnostic),
      contains('rawReceiptText'),
    );
    expect(
      gate.forbiddenFieldsFor(MaintainiacTelemetrySurface.adminDashboard),
      contains('deviceSerial'),
    );
    expect(gate.toJson().toString(), contains('run_ledger_redaction'));
  });

  test('QA telemetry privacy gate rejects missing redaction and overlap', () {
    const gate = MaintainiacQaTelemetryPrivacyGate([
      MaintainiacTelemetryPrivacyRule(
        id: 'bad',
        surface: MaintainiacTelemetrySurface.qaReport,
        allowedFields: {'rawReceiptText'},
        forbiddenFields: {'rawReceiptText'},
        redactionRequired: false,
        reason: '',
      ),
    ]);

    final failures = gate.validate().join('\n');

    expect(failures, contains('bad missing reason'));
    expect(failures, contains('bad must require redaction'));
    expect(failures, contains('fields cannot be both allowed and forbidden'));
    expect(
      failures,
      contains('telemetry privacy gate missing surface adminDashboard'),
    );
  });
}
