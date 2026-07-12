import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/work_supply_parser_local_evidence.dart';

void main() {
  test('measures only an explicitly configured local independent corpus', () {
    const corpusPath = String.fromEnvironment('PARSER_QA_LOCAL_CORPUS_PATH');
    final report = scoreWorkSupplyLocalEvidence(corpusPath);
    final status = report['measurementStatus'];

    // No checked-in or synthetic fixture may be promoted to independent proof.
    // Without a user-supplied ignored corpus, this is an honest unavailable
    // measurement rather than a fabricated release-quality result.
    if (status == 'measured') {
      expect(
        report['releaseClaimEligible'],
        isTrue,
        reason: localEvidenceSummary(report),
      );
    } else {
      expect(status, 'unavailable', reason: localEvidenceSummary(report));
    }
    // ignore: avoid_print
    print(localEvidenceSummary(report));
  });
}
