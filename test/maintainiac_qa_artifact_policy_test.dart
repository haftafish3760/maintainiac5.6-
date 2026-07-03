import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'QA artifact policy accepts redacted reports fixtures and regressions',
    () {
      const policy = MaintainiacQaArtifactPolicy([
        MaintainiacQaArtifact(
          id: 'artifact_report_001',
          kind: MaintainiacQaArtifactKind.report,
          path: 'build/qa/reports/release_gate.json',
          owner: 'maintainiac-qa',
          summary: 'Release gate command report with redacted metrics.',
          tags: {'release-gate', 'report'},
        ),
        MaintainiacQaArtifact(
          id: 'artifact_fixture_001',
          kind: MaintainiacQaArtifactKind.fixture,
          path: 'test/fixtures/work_supply_parser/golden_fixtures.json',
          owner: 'maintainiac-qa',
          summary: 'Synthetic inventory parser fixture corpus.',
          tags: {'inventory', 'parser', 'fixture'},
        ),
        MaintainiacQaArtifact(
          id: 'artifact_regression_001',
          kind: MaintainiacQaArtifactKind.regression,
          path: 'docs/qa/regressions/inventory_parser.md',
          owner: 'maintainiac-qa',
          summary: 'Permanent inventory parser regression index.',
          tags: {'regression', 'inventory'},
        ),
      ]);

      expect(policy.validate(), isEmpty);
      expect(policy.byKind(MaintainiacQaArtifactKind.report), hasLength(1));
      expect(policy.toJson().toString(), contains('artifact_report_001'));
    },
  );

  test(
    'QA artifact policy rejects private receipt and unredacted evidence',
    () {
      const policy = MaintainiacQaArtifactPolicy([
        MaintainiacQaArtifact(
          id: 'artifact_bad_privacy',
          kind: MaintainiacQaArtifactKind.report,
          path: 'build/qa/reports/raw_receipt.txt',
          owner: 'maintainiac-qa',
          summary: 'Bad raw receipt evidence.',
          redacted: false,
          containsRawReceiptText: true,
          containsPrivateData: true,
          tags: {'bad'},
        ),
      ]);

      final failures = policy.validate().join('\n');

      expect(failures, contains('must be redacted'));
      expect(failures, contains('must not store raw receipt text'));
      expect(failures, contains('must not store private data'));
    },
  );

  test(
    'QA artifact policy rejects Google Drive OneDrive and F drive paths',
    () {
      const policy = MaintainiacQaArtifactPolicy([
        MaintainiacQaArtifact(
          id: 'artifact_bad_google',
          kind: MaintainiacQaArtifactKind.report,
          path: 'C:/Users/rjenk/Google Drive/Documents/report.json',
          owner: 'maintainiac-qa',
          summary: 'Wrong synced location.',
          tags: {'bad-path'},
        ),
        MaintainiacQaArtifact(
          id: 'artifact_bad_onedrive',
          kind: MaintainiacQaArtifactKind.report,
          path: 'C:/Users/rjenk/OneDrive/Documents/report.json',
          owner: 'maintainiac-qa',
          summary: 'Wrong OneDrive location.',
          tags: {'bad-path'},
        ),
        MaintainiacQaArtifact(
          id: 'artifact_bad_f_drive',
          kind: MaintainiacQaArtifactKind.report,
          path: 'F:/maintainiac_two/build/qa/report.json',
          owner: 'maintainiac-qa',
          summary: 'Wrong repo drive.',
          tags: {'bad-path'},
        ),
      ]);

      final failures = policy.validate().join('\n');

      expect(failures, contains('artifact_bad_google uses forbidden'));
      expect(failures, contains('artifact_bad_onedrive uses forbidden'));
      expect(failures, contains('artifact_bad_f_drive uses forbidden'));
    },
  );
}
