import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPassEvidenceSuite extends QaSuite {
  const WorkSupplyParserPassEvidenceSuite()
    : super('inventory.pass_evidence_contract');

  static const _requiredSummaryFields = {
    'waveId',
    'qaLayer',
    'trades',
    'marketScopes',
    'tiers',
    'localePackIds',
    'limit',
    'fixtureRunLimit',
    'liveServicesAllowed',
    'writesProductionCatalog',
    'ocrCameraExpensesTouched',
    'firebaseWritesAllowed',
  };

  static const _requiredPassEvidenceFields = {
    'pass',
    'label',
    'localTime',
    'timestamp',
    'artifact',
    'artifactExists',
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final latest = File('build/parser_qa_batch_waves/latest_wave_summary.json');
    final latestPassEvidence = File(
      'build/parser_qa_pass_evidence/latest_pass_evidence.json',
    );
    if (!latest.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_latest_wave_summary',
          message: 'No latest parser QA wave summary exists yet.',
          severity: QaSeverity.warning,
          expected: latest.path,
          actual: 'missing',
          suggestedFix:
              'Run or dry-run a batch wave so each parser QA pass has durable pass evidence.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    } else {
      final decoded =
          jsonDecode(latest.readAsStringSync()) as Map<String, Object?>;
      for (final field in _requiredSummaryFields) {
        if (decoded.containsKey(field)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_wave_summary_field:$field',
            message: 'Latest parser QA wave summary is missing evidence.',
            severity: QaSeverity.warning,
            expected: field,
            actual: decoded.keys.join(', '),
            suggestedFix:
                'Write $field into every wave summary so pass evidence is auditable.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }
    if (!latestPassEvidence.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_latest_pass_evidence',
          message: 'No latest numbered parser QA pass evidence exists yet.',
          severity: QaSeverity.warning,
          expected: latestPassEvidence.path,
          actual: 'missing',
          suggestedFix:
              'Run the pass evidence writer after meaningful parser QA work so pass number, time, artifact, and safety flags are durable.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    } else {
      final decoded =
          jsonDecode(latestPassEvidence.readAsStringSync())
              as Map<String, Object?>;
      for (final field in _requiredPassEvidenceFields) {
        if (decoded.containsKey(field)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_pass_evidence_field:$field',
            message: 'Latest parser QA pass evidence is missing a field.',
            severity: QaSeverity.warning,
            expected: field,
            actual: decoded.keys.join(', '),
            suggestedFix:
                'Write $field into every numbered pass evidence record.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked:
          _requiredSummaryFields.length +
          _requiredPassEvidenceFields.length +
          2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'summaryPath': latest.path,
        'passEvidencePath': latestPassEvidence.path,
        'requiredSummaryFields': _requiredSummaryFields.toList()..sort(),
        'requiredPassEvidenceFields': _requiredPassEvidenceFields.toList()
          ..sort(),
        'contract':
            'Every parser QA batch should leave a durable summary with pass/wave scope, execution policy, and local-only safety flags.',
      },
    );
  }
}
