import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release-one batch waves cover top-three trades and all tiers', () {
    final root = Directory('build/parser_qa_batch_waves');
    final waveIds = [
      'pass198-residential-core-wave-execute',
      'pass201-residential-standard-wave-execute',
      'pass202-residential-professional-wave-execute',
      'pass203-residential-complete-wave-execute',
    ];
    final cells = <String>{};
    var totalCompleted = 0;
    var totalFailed = 0;
    for (final waveId in waveIds) {
      final summary = File(
        '${root.path}/$waveId/queue/'
        '${_queueIdFor(waveId)}/summary.json',
      );
      expect(summary.existsSync(), true, reason: 'Missing $waveId summary');
      final json = jsonDecode(summary.readAsStringSync()) as Map;
      expect(json['dryRun'], false, reason: waveId);
      expect(json['liveServicesAllowed'], false, reason: waveId);
      expect(json['writesProductionCatalog'], false, reason: waveId);
      totalCompleted += json['completedCellCount'] as int;
      totalFailed += json['failedCellCount'] as int;
      for (final result in json['results'] as List) {
        final row = result as Map;
        expect(row['exitCode'], 0, reason: row['cellId'].toString());
        cells.add(
          [
            row['trade'],
            row['marketScope'],
            row['tier'],
            row['localePackId'],
          ].join('|'),
        );
      }
    }

    expect(totalCompleted, 24);
    expect(totalFailed, 0);
    for (final trade in ['plumbing', 'electrical', 'hvac']) {
      for (final tier in ['core', 'standard', 'professional', 'complete']) {
        for (final locale in ['en-US', 'es-US']) {
          expect(
            cells,
            contains('$trade|residential|$tier|$locale'),
            reason: '$trade $tier $locale missing from wave evidence',
          );
        }
      }
    }
  });
}

String _queueIdFor(String waveId) {
  final tier = waveId.split('-')[2];
  return 'pass${waveId.substring(4, 7)}_residential_${tier}_wave_execute_'
      'generated_fixture_first_round';
}
