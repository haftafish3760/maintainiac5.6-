import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('batch-wave handoff artifacts are enough to resume without scrollback', () {
    final root = Directory('build/parser_qa_batch_waves');
    final requiredArtifacts = {
      'pass198-residential-core-wave-execute': [
        'wave_summary.json',
        'queue/pass198_residential_core_wave_execute_generated_fixture_first_round/summary.json',
      ],
      'pass201-residential-standard-wave-execute': [
        'wave_summary.json',
        'queue/pass201_residential_standard_wave_execute_generated_fixture_first_round/summary.json',
      ],
      'pass202-residential-professional-wave-execute': [
        'wave_summary.json',
        'queue/pass202_residential_professional_wave_execute_generated_fixture_first_round/summary.json',
      ],
      'pass203-residential-complete-wave-execute': [
        'wave_summary.json',
        'queue/pass203_residential_complete_wave_execute_generated_fixture_first_round/summary.json',
        'transcript_audit.json',
      ],
    };

    for (final entry in requiredArtifacts.entries) {
      final waveDir = Directory('${root.path}/${entry.key}');
      expect(waveDir.existsSync(), true, reason: entry.key);
      for (final relative in entry.value) {
        expect(
          File('${waveDir.path}/$relative').existsSync(),
          true,
          reason: '${entry.key}/$relative',
        );
      }
      final wave = jsonDecode(
        File('${waveDir.path}/wave_summary.json').readAsStringSync(),
      ) as Map;
      expect(wave['dryRun'], false, reason: entry.key);
      expect(wave['queueExitCode'], 0, reason: entry.key);
      expect(wave['liveServicesAllowed'], false, reason: entry.key);
      expect(wave['writesProductionCatalog'], false, reason: entry.key);
      expect(wave['firebaseWritesAllowed'], false, reason: entry.key);
      expect(wave['ocrCameraExpensesTouched'], false, reason: entry.key);
    }

    final report = File('${root.path}/pass208-release-one-wave-report.json');
    expect(report.existsSync(), true);
    final reportJson = jsonDecode(report.readAsStringSync()) as Map;
    expect(reportJson['allComplete'], true);
    expect(reportJson['totalCellCount'], 24);
    expect(reportJson['failedCellCount'], 0);
  });
}
