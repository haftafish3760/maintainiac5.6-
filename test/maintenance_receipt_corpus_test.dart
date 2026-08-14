import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

import 'support/maintenance_receipt_synthetic_corpus.dart';

void main() {
  final fixtures = loadMaintenanceReceiptSyntheticCorpus();

  for (final fixture in fixtures) {
    test('synthetic corpus ${fixture['id']}', () {
      final result = parseMaintenanceReceipt(
        MaintenanceReceiptParserInput(
          activeVehicleId: 'corpus_vehicle',
          activeVehicleName: 'Corpus Vehicle',
          currentOdometer: 100000,
          sourceText: fixture['sourceText'] as String,
        ),
      );

      expect(
        result.kind.name,
        fixture['kind'],
        reason: fixture['id'] as String,
      );
      expect(
        result.merchantName,
        fixture['merchant'],
        reason: fixture['id'] as String,
      );
      final candidates = {
        for (final candidate in result.candidates)
          candidate.itemName: candidate,
      };
      final actions = (fixture['actions'] as Map<String, dynamic>)
          .cast<String, String>();
      if (fixture['allowAdditionalItems'] != true) {
        expect(
          candidates.keys,
          unorderedEquals(actions.keys),
          reason: '${fixture['id']} candidate precision',
        );
      }
      for (final entry in actions.entries) {
        expect(
          candidates,
          contains(entry.key),
          reason: '${fixture['id']} missing ${entry.key}',
        );
        expect(
          candidates[entry.key]!.action.name,
          entry.value,
          reason: '${fixture['id']} ${entry.key}',
        );
      }
      final fields = ((fixture['fields'] as Map?) ?? const <String, Object?>{})
          .cast<String, dynamic>();
      for (final entry in fields.entries) {
        final expected = (entry.value as Map).cast<String, dynamic>();
        final candidate = candidates[entry.key];
        expect(candidate, isNotNull, reason: '${fixture['id']} ${entry.key}');
        final actual = candidate!.toJson();
        for (final field in expected.entries) {
          expect(
            actual[field.key],
            field.value,
            reason: '${fixture['id']} ${entry.key} ${field.key}',
          );
        }
      }
      for (final forbidden in fixture['forbiddenItems'] as List<dynamic>) {
        expect(
          candidates,
          isNot(contains(forbidden)),
          reason: '${fixture['id']} unexpectedly found $forbidden',
        );
      }
      expect(
        result.candidates,
        everyElement(
          isA<MaintenanceReceiptCandidate>().having(
            (candidate) => candidate.requiresUserConfirmation,
            'requires confirmation',
            isTrue,
          ),
        ),
      );
      expect(result.mayMutateMaintenance, isFalse);
    });

    test(
      'synthetic corpus ${fixture['id']} survives spacing and case noise',
      () {
        final source = fixture['sourceText'] as String;
        final noisySource = source
            .split('\n')
            .map((line) => '  ${line.toLowerCase().replaceAll(' ', '   ')}  ')
            .join('\r\n');
        final baseline = parseMaintenanceReceipt(
          MaintenanceReceiptParserInput(
            activeVehicleId: 'corpus_vehicle',
            sourceText: source,
          ),
        );
        final noisy = parseMaintenanceReceipt(
          MaintenanceReceiptParserInput(
            activeVehicleId: 'corpus_vehicle',
            sourceText: noisySource,
          ),
        );

        expect(noisy.kind, baseline.kind);
        expect(noisy.merchantName, baseline.merchantName);
        expect(
          {
            for (final candidate in noisy.candidates)
              candidate.itemName: (
                candidate.action,
                candidate.detailA,
                candidate.detailB,
              ),
          },
          {
            for (final candidate in baseline.candidates)
              candidate.itemName: (
                candidate.action,
                candidate.detailA,
                candidate.detailB,
              ),
          },
        );
      },
    );
  }
}
