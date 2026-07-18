import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'trip summaries that declare odometer truth also declare global truth',
    () {
      final tripDir = Directory('lib/shared/trip_tracking');
      final offenders = <String>[];

      for (final entity in tripDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        final declaresOdometerTruth =
            source.contains('odometerRemainsOfficialMileageTruth') ||
            source.contains('odometerRemainsCanonical');
        if (!declaresOdometerTruth) continue;
        if (!source.contains('odometerIsGlobalTruth')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Any trip policy/summary that says the odometer remains official '
            'or canonical must also say odometerIsGlobalTruth. GPS, Mapbox, '
            'calibration, mirrors, recovery, dashboard imports, and native '
            'events may assist or request review, but cannot silently become '
            'the official mileage source.',
      );
    },
  );
}
