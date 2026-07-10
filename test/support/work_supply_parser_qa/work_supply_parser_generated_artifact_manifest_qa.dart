import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserGeneratedArtifactManifestSuite extends QaSuite {
  const WorkSupplyParserGeneratedArtifactManifestSuite()
    : super('inventory.generated_artifact_manifest');

  static const _artifacts = {
    'release_one_commands':
        'build/parser_qa_pipeline/release_one_commands.json',
    'latest_pass_evidence':
        'build/parser_qa_pass_evidence/latest_pass_evidence.json',
  };

  static const _requiredSafetyFields = {
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final presentArtifacts = <String>[];

    for (final entry in _artifacts.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_generated_artifact:${entry.key}',
            message: 'Expected generated parser QA artifact is missing.',
            severity: QaSeverity.warning,
            expected: entry.value,
            actual: 'missing',
            suggestedFix:
                'Generate this local artifact before claiming batch evidence is ready.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
        continue;
      }
      presentArtifacts.add(entry.key);
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) continue;
      final map = decoded.cast<String, Object?>();
      for (final field in _requiredSafetyFields) {
        if (map[field] == false) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'unsafe_generated_artifact:${entry.key}:$field',
            message:
                'Generated parser QA artifact is missing a false safety flag.',
            severity: QaSeverity.error,
            expected: '$field=false',
            actual: '${map[field]}',
            suggestedFix:
                'Keep generated parser QA artifacts explicitly local-only and non-production.',
            metadata: const {'triageCategory': QaFailureTriage.security},
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: _artifacts.length * (_requiredSafetyFields.length + 1),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'expectedArtifacts': _artifacts,
        'presentArtifacts': presentArtifacts,
        'requiredSafetyFields': _requiredSafetyFields.toList()..sort(),
      },
    );
  }
}
