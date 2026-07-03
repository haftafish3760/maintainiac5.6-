import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real evidence index includes completed and active batch waves safely', () {
    final index = File('build/parser_qa_batch_waves/pass216-evidence-index.json');
    expect(index.existsSync(), true);
    final json = jsonDecode(index.readAsStringSync()) as Map;

    expect(json['unsafe'], false);
    expect(json['liveServicesAllowed'], false);
    expect(json['writesProductionCatalog'], false);
    expect(json['firebaseWritesAllowed'], false);
    expect(json['ocrCameraExpensesTouched'], false);

    final waves = (json['waves'] as List).cast<Map>();
    final ids = waves.map((wave) => wave['waveId']).toSet();
    expect(ids, contains('pass198-residential-core-wave-execute'));
    expect(ids, contains('pass201-residential-standard-wave-execute'));
    expect(ids, contains('pass202-residential-professional-wave-execute'));
    expect(ids, contains('pass203-residential-complete-wave-execute'));
    expect(ids, contains('pass206-residential-top-three-all-tiers-wave-execute'));

    for (final wave in waves) {
      expect(wave['liveServicesAllowed'], false, reason: '${wave['waveId']}');
      expect(wave['writesProductionCatalog'], false, reason: '${wave['waveId']}');
      expect(wave['firebaseWritesAllowed'], false, reason: '${wave['waveId']}');
      expect(wave['ocrCameraExpensesTouched'], false, reason: '${wave['waveId']}');
      expect(
        File(wave['wavePlanPath'].toString()).existsSync(),
        true,
        reason: '${wave['waveId']} plan path',
      );
    }
  });
}
