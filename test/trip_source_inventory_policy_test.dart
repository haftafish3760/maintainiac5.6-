import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_source_inventory_policy.dart';

void main() {
  test('policy catches duplicate trip filenames and primary types', () {
    final duplicateFile = TripSourceInventoryPolicy.evaluate(
      sourcePaths: const [
        'lib/shared/trip_tracking/trip_alpha_policy.dart',
        'lib/other/trip_alpha_policy.dart',
      ],
      testPaths: const [],
      primaryTypesByPath: const {},
    );
    final duplicateType = TripSourceInventoryPolicy.evaluate(
      sourcePaths: const [
        'lib/shared/trip_tracking/trip_alpha_policy.dart',
        'lib/shared/trip_tracking/trip_beta_policy.dart',
      ],
      testPaths: const [],
      primaryTypesByPath: const {
        'lib/shared/trip_tracking/trip_alpha_policy.dart': 'TripAlphaPolicy',
        'lib/shared/trip_tracking/trip_beta_policy.dart': 'TripAlphaPolicy',
      },
    );

    expect(duplicateFile.status, TripSourceInventoryStatus.duplicateFilenames);
    expect(
      duplicateType.status,
      TripSourceInventoryStatus.duplicatePrimaryTypes,
    );
  });

  test(
    'trip tracking source inventory has no duplicate filenames or types',
    () {
      final libFiles = _dartFiles('lib')
          .where(
            (path) =>
                path.contains('/trip_tracking/') ||
                _base(path).startsWith('trip_'),
          )
          .toList(growable: false);
      final testFiles = _dartFiles('test')
          .where((path) => _base(path).startsWith('trip_'))
          .toList(growable: false);
      final decision = TripSourceInventoryPolicy.evaluate(
        sourcePaths: libFiles,
        testPaths: testFiles,
        primaryTypesByPath: {
          for (final file in [...libFiles, ...testFiles])
            file: _primaryTypeName(File(file).readAsStringSync()),
        },
      );

      expect(decision.status, TripSourceInventoryStatus.clean);
      expect(decision.duplicateFilenames, isEmpty);
      expect(decision.duplicatePrimaryTypes, isEmpty);
      expect(decision.sourceFileCount, greaterThan(20));
      expect(decision.testFileCount, greaterThan(20));
    },
  );

  test('safe inventory summary cannot mutate files or leak source', () {
    final safe = TripSourceInventoryPolicy.evaluate(
      sourcePaths: const ['lib/shared/trip_tracking/trip_alpha_policy.dart'],
      testPaths: const ['test/trip_alpha_policy_test.dart'],
      primaryTypesByPath: const {
        'lib/shared/trip_tracking/trip_alpha_policy.dart': 'TripAlphaPolicy',
        'test/trip_alpha_policy_test.dart': 'TripAlphaPolicyTest',
      },
    ).toSafeSummary();

    expect(safe['tripInventoryOnly'], isTrue);
    expect(safe['inventoryCanModifyFiles'], isFalse);
    expect(safe['inventoryCanDeleteFiles'], isFalse);
    expect(safe['receiptInventoryFuelExpenseModulesExcluded'], isTrue);
    expect(safe['odometerTruthBoundaryTracked'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['calibrationProofBoundaryTracked'], isTrue);
    expect(safe['inventoryCanApplyCalibration'], isFalse);
    expect(safe['inventoryCanCreateOfficialMileage'], isFalse);
    expect(safe['inventoryCanSetGlobalTruth'], isFalse);
    expect(safe['inventoryCanChangeOfficialMileage'], isFalse);
    expect(safe['rawSourceIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}

List<String> _dartFiles(String root) {
  return Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.path.replaceAll('\\', '/'))
      .toList(growable: false)
    ..sort();
}

String _base(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}

String _primaryTypeName(String source) {
  final match = RegExp(
    r'^\s*(?:abstract\s+final\s+|abstract\s+|base\s+|final\s+|sealed\s+)?(?:class|enum|mixin)\s+([A-Za-z][A-Za-z0-9_]*)',
    multiLine: true,
  ).firstMatch(source);
  return match?.group(1) ?? '';
}
