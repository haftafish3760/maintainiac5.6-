import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wider all-tier wave plan preserves release-one scope and safety', () {
    final plan = File(
      'build/parser_qa_batch_waves/'
      'pass206-residential-top-three-all-tiers-wave-execute/wave_plan.json',
    );
    expect(plan.existsSync(), true);
    final json = jsonDecode(plan.readAsStringSync()) as Map;

    expect(json['qaLayer'], 'generated-fixture-wider-batch');
    expect(json['dryRun'], false);
    expect(json['trades'], ['plumbing', 'electrical', 'hvac']);
    expect(json['marketScopes'], ['residential']);
    expect(json['tiers'], ['core', 'standard', 'professional', 'complete']);
    expect(json['localePackIds'], ['en-US', 'es-US']);
    expect(json['limit'], 500);
    expect(json['fixtureRunLimit'], 25);
    expect(json['liveServicesAllowed'], false);
    expect(json['writesProductionCatalog'], false);
    expect(json['firebaseWritesAllowed'], false);
    expect(json['ocrCameraExpensesTouched'], false);

    final queueArgs = (json['queueArgs'] as List).join(' ');
    expect(queueArgs, contains('--execute'));
    expect(queueArgs, contains('--trades plumbing,electrical,hvac'));
    expect(queueArgs, contains('--tiers core,standard,professional,complete'));
    expect(queueArgs, contains('--locales en-US,es-US'));
    expect(queueArgs, contains('--limit 500'));
    expect(queueArgs, contains('--fixture-run-limit 25'));
  });
}
