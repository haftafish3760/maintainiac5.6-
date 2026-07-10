import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed release-one wave transcripts are present and non-empty', () {
    final summaries = [
      'build/parser_qa_batch_waves/pass198-residential-core-wave-execute/queue/'
          'pass198_residential_core_wave_execute_generated_fixture_first_round/summary.json',
      'build/parser_qa_batch_waves/pass201-residential-standard-wave-execute/queue/'
          'pass201_residential_standard_wave_execute_generated_fixture_first_round/summary.json',
      'build/parser_qa_batch_waves/pass202-residential-professional-wave-execute/queue/'
          'pass202_residential_professional_wave_execute_generated_fixture_first_round/summary.json',
      'build/parser_qa_batch_waves/pass203-residential-complete-wave-execute/queue/'
          'pass203_residential_complete_wave_execute_generated_fixture_first_round/summary.json',
    ];
    var transcriptCount = 0;
    for (final summaryPath in summaries) {
      final summary = File(summaryPath);
      expect(summary.existsSync(), true, reason: summaryPath);
      final json = jsonDecode(summary.readAsStringSync()) as Map;
      expect(json['failedCellCount'], 0, reason: summaryPath);
      for (final result in json['results'] as List) {
        final row = result as Map;
        final transcript = File(row['transcriptPath'].toString());
        expect(transcript.existsSync(), true, reason: row['cellId'].toString());
        expect(transcript.lengthSync(), greaterThan(500));
        transcriptCount++;
      }
    }
    expect(transcriptCount, 24);
  });
}
