import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advised next wider wave dry-run plan is safe and scoped', () {
    final summary = File(
      'build/parser_qa_batch_waves/pass228-residential-top-three-all-tiers-wave-dryrun/wave_summary.json',
    );
    expect(summary.existsSync(), true);

    final json = jsonDecode(summary.readAsStringSync()) as Map;
    expect(json['dryRun'], true);
    expect(json['previousWaveId'], 'pass206-residential-top-three-all-tiers-wave-execute');
    expect(json['qaLayer'], 'generated-fixture-wider-batch-v2-advised-45');
    expect(json['fixtureRunLimit'], 45);
    expect(json['limit'], 500);
    expect(json['trades'], ['plumbing', 'electrical', 'hvac']);
    expect(json['marketScopes'], ['residential']);
    expect(json['tiers'], ['core', 'standard', 'professional', 'complete']);
    expect(json['localePackIds'], ['en-US', 'es-US']);
    expect(json['liveServicesAllowed'], false);
    expect(json['writesProductionCatalog'], false);
    expect(json['firebaseWritesAllowed'], false);
    expect(json['ocrCameraExpensesTouched'], false);
    expect(json['queueExitCode'], 0);
  });
}
