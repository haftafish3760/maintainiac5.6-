import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live wider wave evidence artifacts stay local and usable', () {
    final root = Directory(
      'build/parser_qa_batch_waves/pass206-residential-top-three-all-tiers-wave-execute',
    );
    final durationReport = File('${root.path}/duration_report.json');
    final batchAdvice = File('${root.path}/batch_size_advice.json');
    final watchdog = File('${root.path}/queue_watchdog.json');

    expect(durationReport.existsSync(), true);
    expect(batchAdvice.existsSync(), true);
    expect(watchdog.existsSync(), true);

    final duration = jsonDecode(durationReport.readAsStringSync()) as Map;
    final advice = jsonDecode(batchAdvice.readAsStringSync()) as Map;
    final watch = jsonDecode(watchdog.readAsStringSync()) as Map;

    expect(duration['liveServicesAllowed'], false);
    expect(duration['writesProductionCatalog'], false);
    expect(duration['cellCount'], greaterThan(0));
    expect(duration['averageDurationMs'], greaterThan(0));
    expect(duration['slowestCells'], isNotEmpty);

    expect(advice['liveServicesAllowed'], false);
    expect(advice['writesProductionCatalog'], false);
    expect(advice['recommendedFixtureRunLimit'], greaterThan(0));
    expect(advice['targetCellMs'], greaterThan(0));

    expect(watch['liveServicesAllowed'], false);
    expect(watch['writesProductionCatalog'], false);
    expect(watch['failedCellCount'], 0);
    expect(watch['findings'], isEmpty);
  });
}
