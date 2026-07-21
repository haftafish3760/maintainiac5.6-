import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every odometer-touching trip boundary declares odometer global truth',
    () {
      final tripDir = Directory('lib/shared/trip_tracking');
      final missing = <String>[];
      final candidates =
          tripDir
              .listSync(recursive: false)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in candidates) {
        final source = file.readAsStringSync();
        if (!_touchesOdometerTruth(source)) continue;
        if (!source.contains('odometerIsGlobalTruth') &&
            !source.contains('TripTrackingOdometerTruthPolicy')) {
          missing.add(file.path);
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'Any trip file that handles odometer, mileage reconciliation, '
            'calibration, GPS/map mileage, Firebase mirror mileage, stop review '
            'mileage, or live dashboard mileage must explicitly preserve the '
            'physical odometer as canonical/global truth.',
      );
    },
  );

  test('no trip source claims external mileage can override odometer', () {
    final tripDir = Directory('lib/shared/trip_tracking');
    final violations = <String>[];
    final unsafeClaims = RegExp(
      r'(gps|mapbox|firebase|firestore|cloudFunction|importedFile|localCache|sensorFusion)'
      r"""[A-Za-z0-9_]*CanOverrideOdometer['"]?\s*[:,=>]\s*true""",
      caseSensitive: false,
    );

    final candidates =
        tripDir
            .listSync(recursive: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in candidates) {
      final source = file.readAsStringSync();
      if (unsafeClaims.hasMatch(source)) violations.add(file.path);
    }

    expect(
      violations,
      isEmpty,
      reason:
          'GPS, Mapbox, Firebase, Cloud Functions, imports, cache, and sensors '
          'may assist or visualize mileage but must never become official '
          'odometer truth.',
    );
  });

  test('no advisory trip boundary can claim global odometer truth authority', () {
    final tripDir = Directory('lib/shared/trip_tracking');
    final violations = <String>[];
    final unsafeClaims = RegExp(
      r'(gps|mapbox|firebase|firestore|cloudFunction|importedFile|localCache|'
      r'sensorFusion|mirror|projection|calibration|route|optimization)'
      r"""[A-Za-z0-9_]*(CanSetGlobalTruth|CanConfirmOfficialMileage|CanChangeOfficialMileage)['"]?\s*[:,=>]\s*true""",
      caseSensitive: false,
    );

    final candidates =
        tripDir
            .listSync(recursive: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in candidates) {
      final source = file.readAsStringSync();
      if (unsafeClaims.hasMatch(source)) violations.add(file.path);
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Advisory GPS, Mapbox, Firebase/Firestore mirrors, route history, '
          'live projections, optimization, and calibration boundaries must not '
          'claim authority to set global truth, confirm official mileage, or '
          'change official mileage.',
    );
  });
}

bool _touchesOdometerTruth(String source) {
  final lower = source.toLowerCase();
  return lower.contains('confirmedodometer') ||
      lower.contains('startingodometer') ||
      lower.contains('endingodometer') ||
      lower.contains('liveodometer') ||
      lower.contains('odometerprojection') ||
      lower.contains('odometerusage') ||
      lower.contains('odometrystate') ||
      lower.contains('odometerreview') ||
      lower.contains('odometerreconciliation') ||
      lower.contains('odometercalibration') ||
      lower.contains('odometer') && lower.contains('reconcil') ||
      lower.contains('odometer') && lower.contains('confirm') ||
      lower.contains('mileage') && lower.contains('distance') ||
      lower.contains('mileage') && lower.contains('difference') ||
      lower.contains('mileage') && lower.contains('anomaly') ||
      lower.contains('mileage') && lower.contains('projection') ||
      lower.contains('calibration') && lower.contains('multiplier');
}
