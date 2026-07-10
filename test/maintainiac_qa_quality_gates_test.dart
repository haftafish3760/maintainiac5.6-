import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('quality gate matrix covers release required QA dimensions', () {
    final gates = MaintainiacQualityGateMatrix.releaseOne();

    expect(gates.validate(), isEmpty);
    expect(gates.toJson().toString(), contains('differentialRegression'));
    expect(gates.toJson().toString(), contains('propertyFuzzTesting'));
    expect(gates.toJson().toString(), contains('interruptedPackDownload'));
    expect(gates.toJson().toString(), contains('focusedRerunCommand'));
    expect(gates.toJson().toString(), contains('spanishLocale'));
    expect(gates.toJson().toString(), contains('quotaBudgetPerRun'));
  });

  test('quality gate matrix rejects partial release dimensions', () {
    const gates = MaintainiacQualityGateMatrix(
      sync: {MaintainiacSyncScenario.localWrite},
      security: {MaintainiacSecurityScenario.userIsolation},
      financial: {MaintainiacFinancialScenario.expenseTotals},
      performance: {MaintainiacPerformanceScenario.startupLoad},
      regression: {MaintainiacRegressionScenario.goldenRegressionCorpus},
      persistenceChaos: {MaintainiacPersistenceChaosScenario.lowStorage},
      releaseEvidence: {MaintainiacReleaseEvidenceScenario.fixtureSource},
      accessibilityLocalization: {
        MaintainiacAccessibilityLocalizationScenario.englishLocale,
      },
      costQuota: {MaintainiacCostQuotaScenario.noLiveFirebaseInLocalQa},
    );

    final failures = gates.validate().join('\n');

    expect(failures, contains('sync missing'));
    expect(failures, contains('security missing'));
    expect(failures, contains('financial missing'));
    expect(failures, contains('performance missing'));
    expect(failures, contains('regression missing'));
    expect(failures, contains('persistenceChaos missing'));
    expect(failures, contains('releaseEvidence missing'));
    expect(failures, contains('accessibilityLocalization missing'));
    expect(failures, contains('costQuota missing'));
  });
}
