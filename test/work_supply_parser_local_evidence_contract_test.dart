import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/work_supply_parser_local_evidence.dart';

void main() {
  test('local evidence rejects a corpus outside the ignored data root', () {
    final report = scoreWorkSupplyLocalEvidence('test/fixtures/not_local.json');
    expect(report['measurementStatus'], 'unavailable');
    expect(report['reason'], 'corpus_file_not_found');
    expect(report['releaseClaimEligible'], false);
  });

  test(
    'local evidence requires privacy metadata before matching receipt text',
    () {
      final directory = Directory('.external_datasets/parser_evidence_contract')
        ..createSync(recursive: true);
      final file = File('${directory.path}/invalid.json')
        ..writeAsStringSync(
          jsonEncode({
            'schema': workSupplyLocalEvidenceSchema,
            'localOnly': true,
            'committedToGit': false,
            'reportExcludes': const [],
            'cases': const [],
          }),
        );
      addTearDown(() => directory.deleteSync(recursive: true));

      final report = scoreWorkSupplyLocalEvidence(file.path);
      expect(report['measurementStatus'], 'invalid_corpus');
      expect(report['errors'], contains('privacy_exclusions_missing'));
      expect(report['releaseClaimEligible'], false);
    },
  );

  test(
    'local evidence invokes the matcher but cannot claim from a tiny corpus',
    () {
      final directory = Directory('.external_datasets/parser_evidence_contract')
        ..createSync(recursive: true);
      final file = File('${directory.path}/tiny.json')
        ..writeAsStringSync(
          jsonEncode({
            'schema': workSupplyLocalEvidenceSchema,
            'localOnly': true,
            'committedToGit': false,
            'reportExcludes': const [
              'rawLine',
              'ocrText',
              'receiptImagePath',
              'sourceImageBytes',
              'cardNumber',
              'customerName',
              'streetAddress',
            ],
            // Temporary contract data only; it is deleted after the test and
            // cannot represent independently collected release evidence.
            'cases': const [
              {
                'id': 'contract-plumbing-001',
                'rawLine': 'HD 3/4 PVC SCH40 COUPLING',
                'trade': 'plumbing',
                'expectedStatus': 'matched',
                'expectedCandidateId': 'pvc_schedule_40_coupling',
                'tradeScope': 'Plumbing',
                'sourceType': 'reviewedreal',
                'reviewStatus': 'reviewed',
              },
              {
                'id': 'contract-electrical-001',
                'rawLine': 'HOME DEPOT 15A GFCI OUTLET WHITE',
                'trade': 'electrical',
                'expectedStatus': 'matched',
                'expectedCandidateId': 'gfci',
                'tradeScope': 'Electrical',
                'sourceType': 'reviewedreal',
                'reviewStatus': 'reviewed',
              },
              {
                'id': 'contract-hvac-001',
                'rawLine': 'HVAC SUPPLY 20X25X1 MERV 8 FILTER',
                'trade': 'hvac',
                'expectedStatus': 'matched',
                'expectedCandidateId': 'filter',
                'tradeScope': 'HVAC',
                'sourceType': 'reviewedreal',
                'reviewStatus': 'reviewed',
              },
            ],
          }),
        );
      addTearDown(() => directory.deleteSync(recursive: true));

      final report = scoreWorkSupplyLocalEvidence(file.path);
      expect(report['measurementStatus'], 'measured');
      expect((report['overall'] as Map)['correct'], 3);
      expect(report['releaseClaimEligible'], false);
      expect(
        report['releaseClaimBlockers'],
        contains('plumbing:sample_size_below_100'),
      );
      expect(localEvidenceSummary(report), isNot(contains('PVC SCH40')));
    },
  );
}
