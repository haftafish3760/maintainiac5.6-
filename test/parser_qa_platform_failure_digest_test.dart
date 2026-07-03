import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/parser_qa_platform/parser_qa_failure_digest.dart';

void main() {
  test('shared failure digest supports non-inventory parser adapters', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_platform_failure_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final transcript = File('${root.path}/maintenance_fail.txt')
      ..writeAsStringSync(
        [
          'Expected: matching maintenance item',
          'Actual: null',
          'Some tests failed.',
        ].join('\n'),
      );
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'maintenance_filters_en_US',
              'trade': 'maintenance',
              'tier': 'core',
              'localePackId': 'en-US',
              'exitCode': 1,
              'transcriptPath': transcript.path,
            },
          ],
        }),
      );

    final digest = buildParserQaFailureDigest(
      ParserQaFailureDigestOptions(
        summaryPath: summary.path,
        outputPath: '${root.path}/failure_digest.json',
        reportName: 'maintenance_parser_qa_failure_digest',
      ),
    );

    expect(digest['report'], 'maintenance_parser_qa_failure_digest');
    expect(digest['failedCellCount'], 1);
    final failure = ((digest['failures'] as List).single as Map);
    expect(failure['cellId'], 'maintenance_filters_en_US');
    expect(failure['suggestedFixCategory'], 'missing_match_or_alias');
  });
}
