import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active wider wave remains local-only and failure-free', () {
    final wave = Directory(
      'build/parser_qa_batch_waves/residential_all_tiers_wave_001',
    );
    expect(wave.existsSync(), true);
    final plan =
        jsonDecode(File('${wave.path}/wave_plan.json').readAsStringSync())
            as Map;
    expect(plan['dryRun'], false);
    expect(plan['liveServicesAllowed'], false);
    expect(plan['writesProductionCatalog'], false);
    expect(plan['firebaseWritesAllowed'], false);
    expect(plan['ocrCameraExpensesTouched'], false);

    final statusFile = File('${wave.path}/queue/latest_status.json');
    final summaryFile = File(
      '${wave.path}/queue/'
      'residential_all_tiers_wave_001_generated_fixture_all_tiers_v1/'
      'summary.json',
    );
    final evidence = statusFile.existsSync()
        ? jsonDecode(statusFile.readAsStringSync()) as Map
        : jsonDecode(summaryFile.readAsStringSync()) as Map;

    expect(evidence['cellCount'], 24);
    expect(evidence['failedCellCount'], 0);
    expect(evidence['completedCellCount'], greaterThanOrEqualTo(1));
    expect(evidence['liveServicesAllowed'], false);
    expect(evidence['writesProductionCatalog'], false);
    final state = evidence['state'] ?? 'complete';
    expect(['running', 'complete'], contains(state));
  });
}
